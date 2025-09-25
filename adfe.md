love it — let’s lock in a production-grade, **chat-first** structure that streams ADK events over SSE, renders directly from events (not legacy “mega message”), and still leaves room for selectors that build messages when you want them.

Below is a tight plan + code you can hand to the team.

---

# scope recap (chat-first)

* Keep **Home** and **Chat** routes. Defer dashboards/specs.
* Render UI **from events**; collapse non-final/intermediate steps.
* Show **parts** (text, code, blobs/images, tool calls/responses), **state/artifact deltas**, and **errors**.
* **Notifications** (modal) and **Comments** (sidebar) are cross-cutting and route-scoped to the current `sessionId`.

Event stream & semantics come from the ADK: events carry content parts, function calls/responses, and action deltas; the runtime appends events, applies deltas, and yields them in order.  

---

# repo layout (trimmed to Sessions + Chat)

```
frontend-app/
├── package.json
├── tsconfig.json
├── vite.config.ts
├── .env.example
├── server/                     # Express (TypeScript)
│   ├── index.ts
│   ├── routes/
│   │   ├── chat.ts            # SSE proxy + REST passthrough
│   │   ├── comments.ts        # Firestore CRUD
│   │   └── notifications.ts   # Firestore CRUD
│   ├── middlewares/{auth.ts,error.ts,rate-limit.ts}
│   ├── services/{fastapi.ts,firestore.ts,sse.ts}
│   └── utils/{logger.ts,config.ts}
├── src/
│   ├── app/{main.tsx,router.tsx,providers.tsx,theme.ts,queryClient.ts}
│   ├── pages/
│   │   ├── Home/{HomePage.tsx,index.ts}
│   │   └── Chat/{ChatLayout.tsx,ChatPage.tsx,index.ts}
│   ├── features/
│   │   ├── sessions/          # list/get sessions
│   │   │   ├── api/sessions.api.ts
│   │   │   └── model/types.ts
│   │   ├── chat/
│   │   │   ├── api/{events.api.ts,send.api.ts}
│   │   │   ├── hooks/{useEventStream.ts,useSessionState.ts}
│   │   │   ├── model/{adk-types.ts,normalize.ts,selectors.ts}
│   │   │   ├── components/
│   │   │   │   ├── ChatComposer.tsx
│   │   │   │   ├── MessageList.tsx
│   │   │   │   ├── EventList.tsx
│   │   │   │   └── widgets/{TextPart.tsx,CodeWidget.tsx,ImageWidget.tsx,
│   │   │   │              FunctionCallCard.tsx,FunctionResponseCard.tsx}
│   │   │   └── state/useChatUIStore.ts
│   │   ├── comments/{api/comments.api.ts,components/CommentsSidebar.tsx,context/CommentsProvider.tsx}
│   │   └── notifications/{api/notifications.api.ts,components/NotificationsModal.tsx,context/NotificationsProvider.tsx}
│   ├── shared/{ui/*,lib/{http.ts,zod-helpers.ts},hooks/*,types/*}
│   └── index.css
└── tests/{e2e,unit}
```

---

# 1) Type contracts (TS) mirroring ADK

Authoritative ADK structures: `Event`, `EventActions`, `Content/Part`, function call/response, `state_delta`, `artifact_delta`, and the `is_final_response()` rules. We mirror these in the FE and keep a **thin normalization** layer for rendering.  

```ts
// src/features/chat/model/adk-types.ts
export type BlobPart = { data?: string; mimeType?: string; displayName?: string }; // base64 in data
export type FunctionCall = { id?: string; name?: string; args?: Record<string, unknown> };
export type FunctionResponse = { id?: string; name?: string; response?: Record<string, unknown>; will_continue?: boolean };

export type Part = {
  text?: string;
  inline_data?: BlobPart;
  file_data?: { fileUri: string; mimeType?: string };
  function_call?: FunctionCall;
  function_response?: FunctionResponse;
  executable_code?: { code?: string; language?: string };
  code_execution_result?: { outcome?: string; output?: string };
};

export type Content = { role?: 'user' | 'model'; parts?: Part[] };

export type EventActions = {
  skip_summarization?: boolean;
  state_delta?: Record<string, unknown>;
  artifact_delta?: Record<string, number>;
  transfer_to_agent?: string | null;
  escalate?: boolean | null;
  requested_auth_configs?: Record<string, unknown>;
  requested_tool_confirmations?: Record<string, unknown>;
  compaction?: { start_timestamp: number; end_timestamp: number; compacted_content: Content } | null;
};

export type AdkEvent = {
  id: string;
  invocation_id: string;
  author: string; // 'user' or agent name
  timestamp: number;
  content?: Content | null;
  actions: EventActions;
  partial?: boolean | null;
  turn_complete?: boolean | null;
  error_code?: string | null;
  error_message?: string | null;
  long_running_tool_ids?: string[] | null;
};
```

**Final detection** (front-end analogue of ADK’s `is_final_response`):

```ts
// src/features/chat/model/normalize.ts
export const isFinalEvent = (e: AdkEvent) => {
  const parts = e.content?.parts ?? [];
  const hasCall = parts.some(p => !!p.function_call);
  const hasResp = parts.some(p => !!p.function_response);
  const trailingCodeResult = parts.at(-1)?.code_execution_result != null;

  if (e.actions?.skip_summarization) return true;
  if (e.long_running_tool_ids && e.long_running_tool_ids.length) return true;
  return !hasCall && !hasResp && !e.partial && !trailingCodeResult;
};
```

> Source for the logic and fields, including `state_delta`, `artifact_delta`, `skip_summarization`, and `is_final_response()` decision: ADK `Event`/`EventActions` definitions.  

---

# 2) Normalization pipeline

Normalize raw ADK events into **display units** (EventItems) without losing fidelity:

```ts
// src/features/chat/model/normalize.ts
export type EventItem =
  | { kind: 'text'; id: string; author: string; markdown: string; final: boolean }
  | { kind: 'function_call'; id: string; author: string; call: FunctionCall }
  | { kind: 'function_response'; id: string; author: string; response: FunctionResponse; raw: Record<string, unknown> | undefined }
  | { kind: 'code_block'; id: string; author: string; code?: string; language?: string }
  | { kind: 'code_result'; id: string; author: string; outcome?: string; output?: string }
  | { kind: 'blob'; id: string; author: string; mimeType?: string; data?: string; displayName?: string }
  | { kind: 'state_delta'; id: string; delta: Record<string, unknown> }
  | { kind: 'artifact_delta'; id: string; delta: Record<string, number> }
  | { kind: 'control'; id: string; transfer_to_agent?: string | null; escalate?: boolean | null }
  | { kind: 'error'; id: string; code?: string | null; message?: string | null };

export function explodeEvent(e: AdkEvent): EventItem[] {
  const items: EventItem[] = [];
  if (e.error_code || e.error_message) items.push({ kind: 'error', id: e.id, code: e.error_code, message: e.error_message });

  const parts = e.content?.parts ?? [];
  for (const p of parts) {
    if (p.text) items.push({ kind:'text', id:e.id, author:e.author, markdown:p.text, final:isFinalEvent(e) });
    if (p.function_call) items.push({ kind:'function_call', id:e.id, author:e.author, call:p.function_call });
    if (p.function_response) items.push({ kind:'function_response', id:e.id, author:e.author, response:p.function_response, raw:p.function_response.response });
    if (p.executable_code) items.push({ kind:'code_block', id:e.id, author:e.author, code:p.executable_code.code, language:p.executable_code.language });
    if (p.code_execution_result) items.push({ kind:'code_result', id:e.id, author:e.author, outcome:p.code_execution_result.outcome, output:p.code_execution_result.output });
    if (p.inline_data) items.push({ kind:'blob', id:e.id, author:e.author, data:p.inline_data.data, mimeType:p.inline_data.mimeType, displayName:p.inline_data.displayName });
  }

  if (e.actions?.state_delta && Object.keys(e.actions.state_delta).length)
    items.push({ kind:'state_delta', id:e.id, delta: e.actions.state_delta });
  if (e.actions?.artifact_delta && Object.keys(e.actions.artifact_delta).length)
    items.push({ kind:'artifact_delta', id:e.id, delta: e.actions.artifact_delta });
  if (e.actions?.transfer_to_agent || e.actions?.escalate)
    items.push({ kind:'control', id:e.id, transfer_to_agent:e.actions.transfer_to_agent, escalate:e.actions.escalate });

  return items;
}
```

---

# 3) Data layer: queries + SSE streaming

**REST (backfill):** fetch latest N events to hydrate.
**SSE (live):** append new events as they arrive. The ADK runtime upstream guarantees: *Runner processes event, applies `state_delta`/`artifact_delta`, appends to history, yields to UI* — so we can trust ordering and state semantics. 

```ts
// src/features/chat/api/events.api.ts
import { useInfiniteQuery, useQueryClient } from '@tanstack/react-query';
import { AdkEvent } from '../model/adk-types';

export const useEventsBackfill = (sessionId: string) =>
  useInfiniteQuery({
    queryKey: ['events', sessionId],
    queryFn: async ({ pageParam }) => {
      const resp = await fetch(`/api/chat/sessions/${sessionId}/events?cursor=${pageParam ?? ''}`);
      return resp.json() as Promise<{ events: AdkEvent[]; nextCursor?: string }>;
    },
    getNextPageParam: (last) => last.nextCursor,
    initialPageParam: undefined,
  });
```

```ts
// src/features/chat/hooks/useEventStream.ts
import { useEffect } from 'react';
import { useQueryClient } from '@tanstack/react-query';
import type { AdkEvent } from '../model/adk-types';
import { explodeEvent } from '../model/normalize';

export function useEventStream(sessionId: string) {
  const qc = useQueryClient();

  useEffect(() => {
    const es = new EventSource(`/api/chat/sessions/${sessionId}/stream`, { withCredentials: true });

    const onMessage = (ev: MessageEvent) => {
      try {
        const e: AdkEvent = JSON.parse(ev.data);
        // Append event into infinite cache page 0 (or a shadow list)
        qc.setQueryData<any>(['events', sessionId], (prev) => {
          if (!prev) return { pages: [{ events: [e] }], pageParams: [undefined] };
          const pages = [...prev.pages];
          pages[0] = { ...pages[0], events: [...(pages[0]?.events ?? []), e] };
          return { ...prev, pages };
        });
        // Maintain a derived cache for “flat items” for rendering speed
        qc.setQueryData<any>(['eventItems', sessionId], (prev: any[] = []) => [...prev, ...explodeEvent(e)]);
        // Keep a live SessionState cache by rolling in deltas
        if (e.actions?.state_delta) {
          qc.setQueryData<Record<string, unknown>>(['sessionState', sessionId], (cur = {}) => ({ ...cur, ...e.actions!.state_delta! }));
        }
      } catch {}
    };

    const onError = () => {
      es.close();
      // simple jittered backoff reconnect
      setTimeout(() => useEventStream(sessionId), Math.random() * 2000 + 800);
    };

    es.addEventListener('message', onMessage);
    es.addEventListener('error', onError);
    return () => es.close();
  }, [sessionId, qc]);
}
```

**Why SSE here?** ADK yields each event as it’s committed by the Runner; UI can progressively render text chunks (`partial==true`) while only **final** chunks mark a turn complete. The ADK defines partial streaming vs final and how deltas are committed post-yield. 

---

# 4) Rendering strategy: **event-native** with collapsible internals

* **Primary list = EventList** (fully event-native).
* **MessageList** (optional) = derived view (selector) that groups by `invocation_id`, shows only **final** items as the main “message bubble,” with intermediate/function/tool events tucked into a collapsible “details” drawer.

```tsx
// src/features/chat/components/EventList.tsx
export function EventList({ items }: { items: EventItem[] }) {
  return (
    <div>
      {items.map(it => {
        switch (it.kind) {
          case 'text': return <TextPart key={it.id} author={it.author} markdown={it.markdown} final={it.final} />;
          case 'function_call': return <FunctionCallCard key={it.id} call={it.call} author={it.author} />;
          case 'function_response': return <FunctionResponseCard key={it.id} response={it.response} raw={it.raw} author={it.author} />;
          case 'code_block': return <CodeWidget key={it.id} code={it.code} language={it.language} />;
          case 'code_result': return <CodeWidget key={it.id} code={it.output} language="text" />;
          case 'blob': return <ImageWidget key={it.id} data={it.data} mimeType={it.mimeType} name={it.displayName} />;
          case 'state_delta': return <small key={it.id}>state Δ applied</small>;
          case 'artifact_delta': return <small key={it.id}>artifact Δ updated</small>;
          case 'error': return <div key={it.id} className="error">{it.code ?? 'error'}: {it.message}</div>;
          default: return null;
        }
      })}
    </div>
  );
}
```

**Message selector** (optional) — produces high-level “bubbles” + hidden details:

```ts
// src/features/chat/model/selectors.ts
import { AdkEvent } from './adk-types';
import { isFinalEvent, explodeEvent, EventItem } from './normalize';

export type Bubble = {
  id: string;
  author: string;
  final: boolean;
  headline?: string;             // first text chunk if any
  details: EventItem[];          // all items for this invocation_id
  invocation_id: string;
};

export function buildBubbles(events: AdkEvent[]): Bubble[] {
  const byInv: Record<string, AdkEvent[]> = {};
  for (const e of events) (byInv[e.invocation_id] ??= []).push(e);
  const result: Bubble[] = [];

  for (const inv in byInv) {
    const evts = byInv[inv];
    const items = evts.flatMap(explodeEvent);
    const headline = items.find(i => i.kind === 'text' && (i as any).final) as any;
    const auth = evts.at(-1)?.author ?? 'agent';
    result.push({
      id: `${inv}:${evts.at(-1)?.id}`,
      author: auth,
      final: evts.some(isFinalEvent),
      headline: headline?.markdown,
      details: items,
      invocation_id: inv,
    });
  }
  return result.sort((a,b) => a.id.localeCompare(b.id));
}
```

---

# 5) Chat page wiring

```tsx
// src/pages/Chat/ChatPage.tsx
import { Suspense, useMemo } from 'react';
import { useParams } from 'react-router-dom';
import { useEventsBackfill } from '../../features/chat/api/events.api';
import { useEventStream } from '../../features/chat/hooks/useEventStream';
import { buildBubbles } from '../../features/chat/model/selectors';
import { EventList } from '../../features/chat/components/EventList';
import { Virtuoso } from 'react-virtuoso';

export default function ChatPage() {
  const { sessionId = '' } = useParams();
  const { data } = useEventsBackfill(sessionId);
  useEventStream(sessionId);

  const flatEvents = useMemo(
    () => (data?.pages ?? []).flatMap(p => p.events ?? []),
    [data]
  );
  const items = useMemo(() => flatEvents.flatMap(e => explodeEvent(e)), [flatEvents]);
  const bubbles = useMemo(() => buildBubbles(flatEvents), [flatEvents]);

  return (
    <div className="grid grid-cols-[1fr,360px] gap-4">
      <div className="rounded-2xl shadow p-2">
        <Suspense fallback={<div>Loading…</div>}>
          {/* Switch between raw events or message bubbles */}
          <EventList items={items} />
          {/* Or: <MessageList bubbles={bubbles} /> */}
        </Suspense>
      </div>
      <CommentsSidebar scope="session" />
    </div>
  );
}
```

---

# 6) Express SSE proxy (pass-through, robust)

```ts
// server/routes/chat.ts
import { Router } from 'express';
import { auth } from '../middlewares/auth';
import { fastapi } from '../services/fastapi';

export const chat = Router();

// backfill
chat.get('/chat/sessions/:id/events', auth, async (req, res, next) => {
  try {
    const r = await fastapi.get(`/sessions/${req.params.id}/events`, { params: { cursor: req.query.cursor } });
    res.json(r.data);
  } catch (e) { next(e); }
});

// streaming pass-through
chat.get('/chat/sessions/:id/stream', auth, async (req, res, next) => {
  try {
    res.setHeader('Content-Type', 'text/event-stream');
    res.setHeader('Cache-Control', 'no-cache, no-transform');
    res.setHeader('Connection', 'keep-alive');
    res.flushHeaders();

    const upstream = await fastapi.get<unknown>(`/sessions/${req.params.id}/events/stream`, {
      responseType: 'stream',
      headers: { authorization: req.headers.authorization as string },
    });

    upstream.data.on('data', (chunk: Buffer) => res.write(chunk));
    upstream.data.on('end', () => res.end());
    upstream.data.on('error', () => res.end());
    req.on('close', () => upstream.data.destroy());
  } catch (e) { next(e); }
});
```

---

# 7) Security & performance notes (practical)

* **Blobs & data URIs:** cap previewable size; allowlist image MIME types; route non-image blobs to download flow. (ADK Blob parts carry `mime_type` and base64 `data`.) 
* **Virtualize** long lists (e.g., react-virtuoso) and **lazy-load** heavy widgets (plotly).
* **Reconnection**: jittered SSE backoff; surface offline banner.
* **Client cache** (TanStack Query) with per-resource `staleTime`; avoid re-hydrating old partial chunks.
* **ETags** on backfill endpoints; gzip/brotli; HTTP/2.
* **Authz**: Express validates user → injects downstream headers; avoid client→FastAPI direct leakage.
* **XSS**: sanitize markdown; render code fences safely.

---

# 8) Notifications & Comments (route-scoped)

* **NotificationsProvider** at app level, modal + toasts. CRUD via `/api/notifications`.
* **CommentsProvider** wraps Chat route, reading `sessionId` from params and scoping queries to `scope=session`. Sidebar mounts only on pages that opt-in.
  Events drive state/artifact panels; comments remain orthogonal.

---

# 9) Testing & DX

* **MSW** for REST + a tiny **SSE mock** (stream text → partials → final; tool call → response; state_delta).
* **Playwright** happy path: send → stream → final; blob image renders; tool result details collapsible.
* **Type validation**: Zod schemas for incoming events; dev logs for unexpected parts.

---

# 10) Migration from legacy “mega context”

Short term, keep an adapter that **derives messages from events** (by `invocation_id`, pick final text, attach tool/exec segments as “details”). As we transition UIs to event-native, the adapter becomes optional.

---

# why this works with ADK’s model

* Events are **the source of truth** for text, tool calls, tool results, and side-effects (`state_delta`, `artifact_delta`). Your FE renders from that, not from stitched messages. 
* The **runtime loop** guarantees ordering and that deltas are applied when the event is committed, then yielded to clients — perfect for SSE. 
* The FE’s `isFinalEvent` mirrors ADK’s `is_final_response` contract (skip_summarization, long-running tool ids, no calls/responses, not partial, no trailing code-result). 
* `EventActions` fields (state/artifact/auth/confirmation/transfer/escalate) are explicitly surfaced for UI or control affordances. 

---

If you want, I can turn this into a starter PR (files + stubs) so the team can `pnpm i && pnpm dev` and start plugging in your actual FastAPI endpoints.
