# Production‑grade SSE + TanStack Query for a Chat Event Stream

This guide shows a pragmatic, production‑ready way to wire **SSE** to **TanStack Query** in a React app for a chat UI where events include: user messages, intermediate agent actions, and final model messages. It assumes:

* Frontend: React + TanStack Query (v5) with optional Zustand.
* BFF: Express, proxying to FastAPI which emits SSE.
* Route is parameterized by `session_id`.

The pattern: **fetch a snapshot → subscribe to SSE → incrementally update the Query cache**. Use virtualization and collapsibles to render efficiently.

---

## 1) Event model & wire format

Define a typed, append‑only event log per session. Each event must have a stable id, a monotonic cursor/sequence, a type, time, and minimal payload.

```ts
// shared/types.ts
export type EventBase = {
  id: string;                 // globally unique (ulid/uuid)
  seq: number;                // strictly increasing per session
  sessionId: string;
  ts: string;                 // ISO timestamp
  type: string;
};

export type UserMessageEvent = EventBase & {
  type: 'user.message';
  content: string;
};

export type AgentActionStart = EventBase & {
  type: 'agent.action.start';
  tool: string;               // e.g., 'search', 'code', 'http'
  input: unknown;             // redacted/safe summary if needed
};

export type AgentActionProgress = EventBase & {
  type: 'agent.action.progress';
  tool: string;
  progress: number;           // 0..100
  logs?: string[];
};

export type AgentActionEnd = EventBase & {
  type: 'agent.action.end';
  tool: string;
  output: unknown;
  ok: boolean;
  error?: string;
};

export type ModelDelta = EventBase & {
  type: 'model.delta';
  contentDelta: string;       // token/char deltas
};

export type ModelComplete = EventBase & {
  type: 'model.complete';
  content: string;            // final stitched content
};

export type SystemHeartbeat = EventBase & {
  type: 'system.heartbeat';
};

export type ChatEvent =
  | UserMessageEvent
  | AgentActionStart
  | AgentActionProgress
  | AgentActionEnd
  | ModelDelta
  | ModelComplete
  | SystemHeartbeat;
```

**SSE frames** should use `event`, `id`, and `data` fields:

```
event: model.delta
id: 000243
retry: 5000
:data: {"id":"01H...","seq":243,"sessionId":"abc","ts":"...","type":"model.delta","contentDelta":"Hello"}

```

> Use `id` == last `seq` (or explicit cursor). Send a heartbeat every ~15s: `event: system.heartbeat`.

---

## 2) FastAPI emitter (reference)

```py
# server/fastapi_stream.py
from fastapi import FastAPI, Request
from fastapi.responses import StreamingResponse
import asyncio, json

app = FastAPI()

async def sse_event(event_type, data, event_id=None):
    yield f"event: {event_type}\n".encode()
    if event_id is not None:
        yield f"id: {event_id}\n".encode()
    payload = json.dumps(data, separators=(',', ':'))
    yield f"data: {payload}\n\n".encode()

@app.get('/sessions/{session_id}/stream')
async def stream(session_id: str, request: Request, last_event_id: str | None = None):
    async def generator():
        # resume from cursor if provided
        cursor = int(last_event_id) if last_event_id else None
        # (replay missed events from store starting at cursor) ...
        # then live tail
        while True:
            if await request.is_disconnected():
                break
            # produce next event (await from queue/bus)
            evt = await next_event_for_session(session_id, cursor)
            cursor = evt['seq']
            async for chunk in sse_event(evt['type'], evt, str(evt['seq'])):
                yield chunk
            # heartbeat (or send from another task)
            # async for hb in sse_event('system.heartbeat', {"seq": cursor}):
            #     yield hb
    return StreamingResponse(generator(), media_type='text/event-stream', headers={
        'Cache-Control': 'no-cache, no-transform',
        'X-Accel-Buffering': 'no',  # nginx disable buffering
        'Connection': 'keep-alive',
        # CORS handled globally
    })
```

---

## 3) Express BFF proxy (auth, headers, abort)

```ts
// bff/stream.ts
import express from 'express'
import fetch from 'node-fetch'

const router = express.Router()

router.get('/sessions/:id/stream', async (req, res) => {
  const { id } = req.params
  // Auth: prefer cookie/session; EventSource can’t set custom headers reliably
  const token = req.cookies['auth'] || ''
  const lastEventId = req.header('Last-Event-ID') || req.query.lastEventId || ''

  const upstream = await fetch(`${process.env.FASTAPI_URL}/sessions/${id}/stream?last_event_id=${encodeURIComponent(lastEventId)}`, {
    headers: {
      'Accept': 'text/event-stream',
      'Authorization': token ? `Bearer ${token}` : undefined,
    } as any,
  })

  res.status(200)
  res.setHeader('Content-Type', 'text/event-stream')
  res.setHeader('Cache-Control', 'no-cache, no-transform')
  res.setHeader('Connection', 'keep-alive')
  res.setHeader('X-Accel-Buffering', 'no')

  // Pipe, but also pass through Last-Event-ID from upstream if present
  upstream.body?.on('data', (chunk) => res.write(chunk))
  upstream.body?.on('end', () => res.end())
  req.on('close', () => upstream.body?.destroy())
})

export default router
```

> Ensure infra (nginx, CDN, serverless) **does not buffer** SSE. Add `X-Accel-Buffering: no`, disable gzip for this route, and raise idle timeouts.

---

## 4) Frontend: TanStack Query + SSE subscription

**Key idea:** TSQuery holds the canonical cache; SSE pushes are applied with `queryClient.setQueryData`. We batch updates to avoid rerender storms and use `Last-Event-ID` to resume seamlessly.

```ts
// app/queryKeys.ts
export const qk = {
  session: (sessionId: string) => ['session', sessionId] as const,
  events: (sessionId: string) => ['session', sessionId, 'events'] as const,
}
```

```ts
// app/api.ts
export type EventsPage = { items: ChatEvent[]; nextSeq: number | null }

export async function fetchEventsSnapshot(sessionId: string, fromSeq?: number): Promise<EventsPage> {
  const url = new URL(`/api/sessions/${sessionId}/events`, location.origin)
  if (fromSeq) url.searchParams.set('from', String(fromSeq))
  const r = await fetch(url, { credentials: 'include' })
  if (!r.ok) throw new Error('snapshot fetch failed')
  return r.json()
}

export function openSSE(
  sessionId: string,
  onEvent: (evt: ChatEvent) => void,
  opts?: { lastEventId?: string | null; onError?: (e: any) => void }
): () => void {
  const url = new URL(`/api/sessions/${sessionId}/stream`, location.origin)
  if (opts?.lastEventId) url.searchParams.set('lastEventId', opts.lastEventId)

  const es = new EventSource(url, { withCredentials: true })

  const handler = (type: string) => (e: MessageEvent<string>) => {
    if (!e.data) return
    try {
      const parsed = JSON.parse(e.data) as ChatEvent
      onEvent(parsed)
    } catch {}
  }

  es.addEventListener('user.message', handler('user.message'))
  es.addEventListener('agent.action.start', handler('agent.action.start'))
  es.addEventListener('agent.action.progress', handler('agent.action.progress'))
  es.addEventListener('agent.action.end', handler('agent.action.end'))
  es.addEventListener('model.delta', handler('model.delta'))
  es.addEventListener('model.complete', handler('model.complete'))
  es.addEventListener('system.heartbeat', () => {})

  es.onerror = (e) => opts?.onError?.(e)

  return () => es.close()
}
```

```ts
// app/useChatSession.tsx
import { useEffect, useMemo, useRef, startTransition } from 'react'
import { useQueryClient, useQuery } from '@tanstack/react-query'
import { qk } from './queryKeys'
import { fetchEventsSnapshot, openSSE } from './api'

export function useChatSession(sessionId: string) {
  const qc = useQueryClient()
  const lastSeqRef = useRef<number | null>(null)

  // 1) initial snapshot
  const snapshot = useQuery({
    queryKey: qk.events(sessionId),
    queryFn: () => fetchEventsSnapshot(sessionId),
    staleTime: 30_000,
    select: (page) => page.items,
    refetchOnWindowFocus: false,
  })

  // 2) live subscription
  useEffect(() => {
    let raf = 0
    let buffer: ChatEvent[] = []

    const flush = () => {
      if (buffer.length === 0) return
      const batch = buffer
      buffer = []
      startTransition(() => {
        qc.setQueryData<ChatEvent[]>(qk.events(sessionId), (prev = []) => {
          const merged = mergeEvents(prev, batch) // de‑dupe by id, sort by seq
          lastSeqRef.current = merged.length ? merged[merged.length - 1].seq : lastSeqRef.current
          return merged
        })
      })
    }

    const cancel = openSSE(
      sessionId,
      (evt) => {
        buffer.push(evt)
        // throttle to animation frames to cap re‑renders
        if (!raf) raf = requestAnimationFrame(() => { raf = 0; flush() })
      },
      { lastEventId: lastSeqRef.current ? String(lastSeqRef.current) : null }
    )

    return () => {
      cancel()
      if (raf) cancelAnimationFrame(raf)
    }
  }, [sessionId, qc])

  return {
    events: snapshot.data ?? [],
    isLoading: snapshot.isLoading,
    error: snapshot.error as Error | null,
  }
}

function mergeEvents(prev: ChatEvent[], incoming: ChatEvent[]): ChatEvent[] {
  const map = new Map(prev.map((e) => [e.id, e]))
  for (const e of incoming) map.set(e.id, e)
  const out = Array.from(map.values())
  out.sort((a, b) => a.seq - b.seq)
  return out
}
```

---

## 5) Collapsible UI with virtualization

Use `@tanstack/react-virtual` to efficiently render thousands of rows, and provide nested collapsibles for intermediate agent actions.

```tsx
// components/ChatPane.tsx
import { useRef } from 'react'
import { useVirtualizer } from '@tanstack/react-virtual'
import { useChatSession } from '../app/useChatSession'

export default function ChatPane({ sessionId }: { sessionId: string }) {
  const parentRef = useRef<HTMLDivElement>(null)
  const { events } = useChatSession(sessionId)

  // group into display messages; collapse agent actions under the parent that caused them
  const rows = groupForDisplay(events)

  const rowVirtualizer = useVirtualizer({
    count: rows.length,
    getScrollElement: () => parentRef.current,
    estimateSize: () => 64,
    overscan: 8,
  })

  return (
    <div ref={parentRef} className="h-full overflow-auto">
      <div style={{ height: rowVirtualizer.getTotalSize(), position: 'relative' }}>
        {rowVirtualizer.getVirtualItems().map((vi) => {
          const row = rows[vi.index]
          return (
            <div
              key={row.key}
              className="absolute left-0 right-0 p-3"
              style={{ transform: `translateY(${vi.start}px)` }}
            >
              <RowRenderer row={row} />
            </div>
          )
        })}
      </div>
    </div>
  )
}

// --- helpers ---

type DisplayRow =
  | { kind: 'user'; key: string; content: string; ts: string }
  | { kind: 'assistant'; key: string; content: string; ts: string }
  | { kind: 'action'; key: string; tool: string; ts: string; children: ActionChild[]; collapsed?: boolean }

type ActionChild = { seq: number; text: string; ts: string }

function groupForDisplay(events: ChatEvent[]): DisplayRow[] {
  const rows: DisplayRow[] = []
  let currentAssistant: { content: string; ts: string; key: string } | null = null
  let openAction: { tool: string; ts: string; children: ActionChild[]; key: string } | null = null

  for (const e of events) {
    switch (e.type) {
      case 'user.message':
        rows.push({ kind: 'user', key: e.id, content: e.content, ts: e.ts })
        currentAssistant = null
        break
      case 'model.delta':
        if (!currentAssistant) currentAssistant = { content: '', ts: e.ts, key: `assistant-${e.seq}` }
        currentAssistant.content += e.contentDelta
        break
      case 'model.complete':
        rows.push({ kind: 'assistant', key: e.id, content: e.content, ts: e.ts })
        currentAssistant = null
        break
      case 'agent.action.start':
        openAction = { tool: e.tool, ts: e.ts, children: [], key: e.id }
        break
      case 'agent.action.progress':
        if (openAction) openAction.children.push({ seq: e.seq, text: `${e.progress}%`, ts: e.ts })
        break
      case 'agent.action.end':
        if (openAction) {
          openAction.children.push({ seq: e.seq, text: e.ok ? 'done' : `error: ${e.error}`, ts: e.ts })
          rows.push({ kind: 'action', key: openAction.key, tool: openAction.tool, ts: openAction.ts, children: openAction.children, collapsed: true })
          openAction = null
        }
        break
    }
  }
  if (currentAssistant) rows.push({ kind: 'assistant', key: currentAssistant.key, content: currentAssistant.content, ts: currentAssistant.ts })
  return rows
}

function RowRenderer({ row }: { row: DisplayRow }) {
  if (row.kind === 'user') return <Bubble who="user" text={row.content} ts={row.ts} />
  if (row.kind === 'assistant') return <Bubble who="assistant" text={row.content} ts={row.ts} />
  return <ActionCollapsible tool={row.tool} ts={row.ts} childrenRows={row.children} />
}

function Bubble({ who, text, ts }: { who: 'user' | 'assistant'; text: string; ts: string }) {
  const align = who === 'user' ? 'items-end' : 'items-start'
  return (
    <div className={`flex ${align}`}>
      <div className="rounded-2xl shadow p-3 max-w-[70ch]">
        <div className="text-sm opacity-60">{new Date(ts).toLocaleTimeString()}</div>
        <div>{text}</div>
      </div>
    </div>
  )
}

function ActionCollapsible({ tool, ts, childrenRows }: { tool: string; ts: string; childrenRows: ActionChild[] }) {
  return (
    <details className="rounded-xl border p-3">
      <summary className="cursor-pointer select-none">{tool} • {new Date(ts).toLocaleTimeString()}</summary>
      <ul className="mt-2 text-sm opacity-80 space-y-1">
        {childrenRows.map((c) => (<li key={c.seq}>[{new Date(c.ts).toLocaleTimeString()}] {c.text}</li>))}
      </ul>
    </details>
  )
}
```

---

## 6) Submitting messages

Use a mutation for the POST, and let SSE deliver resulting events. Optimistically add the user message to the cache to keep the UI snappy.

```ts
// app/useSendMessage.ts
import { useMutation, useQueryClient } from '@tanstack/react-query'
import { qk } from './queryKeys'

export function useSendMessage(sessionId: string) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: async (content: string) => {
      const r = await fetch(`/api/sessions/${sessionId}/messages`, {
        method: 'POST',
        credentials: 'include',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ content }),
      })
      if (!r.ok) throw new Error('send failed')
      return r.json()
    },
    onMutate: async (content) => {
      // optimistic insert
      qc.setQueryData<ChatEvent[]>(qk.events(sessionId), (prev = []) => [
        ...prev,
        {
          id: `optimistic-${Date.now()}`,
          seq: (prev.at(-1)?.seq ?? 0) + 0.1, // float to avoid colliding; replaced by real event later
          sessionId,
          ts: new Date().toISOString(),
          type: 'user.message',
          content,
        } as any,
      ])
    },
  })
}
```

---

## 7) Error handling & reconnection

* Let the browser’s `EventSource` auto‑retry (respects `retry:` from server). Handle `onerror` to surface UI state.
* Use `Last-Event-ID` (or `last_event_id` query) to resume. Cache the last `seq` in memory and optionally in `sessionStorage` to survive reloads.
* Validate payloads (zod/io‑ts) before inserting into cache to keep corrupted events from poisoning UI.

```ts
import { z } from 'zod'

const ChatEventZ = z.object({ id: z.string(), seq: z.number(), sessionId: z.string(), ts: z.string(), type: z.string() })

function safeInsert(qc: QueryClient, sessionId: string, evt: unknown) {
  const parsed = ChatEventZ.safeParse(evt)
  if (!parsed.success) return
  qc.setQueryData<ChatEvent[]>(qk.events(sessionId), (prev = []) => mergeEvents(prev, [parsed.data as any]))
}
```

---

## 8) Where Zustand fits

Zustand is optional. A common hybrid is:

* **TanStack Query**: server‑owned data (events, sessions, snapshots) + mutations.
* **Zustand**: purely UI/client state (which row is expanded, draft inputs, scroll lock, ephemeral toasts).

This keeps streaming data normalized and cacheable, and the UI state simple.

---

## 9) Scaling checklist (prod)

**Server**

* [ ] Send heartbeats every 10–20s to keep connections warm.
* [ ] Disable buffering at proxies/CDNs; raise idle timeouts.
* [ ] Use `id` = cursor to enable exact resume; store events durably (DB or event log).
* [ ] Backpressure is implicit with SSE; keep payloads small and delta‑based.
* [ ] Rate‑limit per user/session; cap concurrent streams.
* [ ] CORS for `text/event-stream`; allow credentials if using cookies.

**Client**

* [ ] Batch cache updates (RAF/microtask) to avoid rerender floods.
* [ ] Virtualize lists; avoid diffing massive arrays every frame.
* [ ] Derive display rows from events; don’t over‑store UI transforms.
* [ ] Reconnect with `Last-Event-ID`; replay missing events via snapshot + from‑cursor.
* [ ] Persist last cursor in `sessionStorage` for reload continuity.
* [ ] Guard against out‑of‑order events by sorting on `seq`.

---

## 10) Testing tips

* Simulate jitter: randomly delay or drop events server‑side; ensure UI recovers.
* Fuzz payloads to verify zod validators.
* Load test: thousands of tiny `model.delta` frames – ensure batching keeps FPS smooth.
* Snapshot + stream race: fetch should not overwrite newer SSE state—always **merge**.

---

## 11) Variants

* **Without EventSource** (for finer control or custom headers) use `fetch` + `ReadableStream` and an SSE parser (e.g., `eventsource-parser`). The cache update pattern stays identical.
* **Web Workers** to parse/validate SSE and postMessage batched events to the UI thread under extreme load.

---

### Minimal wiring summary

1. `useQuery` loads initial events.
2. `openSSE` subscribes and batches updates into `setQueryData`.
3. Virtualized `ChatPane` renders messages; agent actions are collapsible.
4. `useSendMessage` posts user messages; subsequent events arrive via SSE.

This composition stays SSR-friendly, scalable, and easy to test.
