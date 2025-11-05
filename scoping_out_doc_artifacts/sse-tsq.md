Here’s the tight cheat-sheet for **SSE + TanStack Query** in your chat app.

# What you’re building

* **Flow:** snapshot (REST) → **subscribe** (SSE) → **incrementally update** TanStack Query cache → **virtualized UI** (collapsible for agent actions).
* **Events:** `user.message`, `agent.action.{start|progress|end}`, `model.delta`, `model.complete`, `system.heartbeat`.
* **Cursor:** monotonically increasing `seq` used as SSE `id` to resume with `Last-Event-ID`.

# Server (FastAPI → Express BFF)

* **FastAPI SSE**: `GET /sessions/:id/stream` emits frames:

  ```
  event: model.delta
  id: 243
  data: {"seq":243,"type":"model.delta","contentDelta":"Hi"}
  ```
* **Heartbeats** every 10–20s (`system.heartbeat`) to keep connections warm.
* **Express proxy** `/api/sessions/:id/stream`:

  * Set `Content-Type: text/event-stream`, `Cache-Control: no-cache, no-transform`, `X-Accel-Buffering: no`.
  * Pipe upstream bytes; respect `Last-Event-ID` (query/header).
  * Disable gzip/buffering on this route at CDN/reverse proxy.

# Client (React + TanStack Query v5)

**Query keys**

```ts
const qk = {
  events: (sessionId: string) => ['session', sessionId, 'events'] as const,
};
```

**Snapshot fetch**

```ts
useQuery({
  queryKey: qk.events(sessionId),
  queryFn: () => fetch(`/api/sessions/${sessionId}/events`).then(r => r.json()),
  select: d => d.items, refetchOnWindowFocus: false, staleTime: 30_000,
});
```

**Open SSE + cache updates (core pattern)**

```ts
useEffect(() => {
  const es = new EventSource(`/api/sessions/${id}/stream?lastEventId=${lastSeqRef.current ?? ''}`, { withCredentials: true });

  let buf: ChatEvent[] = []; let raf = 0;
  const onAny = (e: MessageEvent<string>) => { try { buf.push(JSON.parse(e.data)); } catch {} if (!raf) raf = requestAnimationFrame(flush); };
  const flush = () => { const batch = buf; buf = []; raf = 0;
    queryClient.setQueryData<ChatEvent[]>(qk.events(id), (prev = []) => mergeByIdAndSort(prev, batch));
    lastSeqRef.current = Math.max(lastSeqRef.current ?? 0, ...batch.map(b => b.seq));
  };

  ['user.message','agent.action.start','agent.action.progress','agent.action.end','model.delta','model.complete'].forEach(t => es.addEventListener(t, onAny));
  es.onerror = () => {/* surface UI state if needed */};
  return () => { es.close(); if (raf) cancelAnimationFrame(raf); };
}, [id]);
```

**Optimistic send**

```ts
useMutation({
  mutationFn: (content: string) => fetch(`/api/sessions/${id}/messages`, { method:'POST', body: JSON.stringify({ content }), headers:{'Content-Type':'application/json'}, credentials:'include'}),
  onMutate: (content) => queryClient.setQueryData<ChatEvent[]>(qk.events(id), (prev = []) => [...prev, optimisticUserEvent(content)]),
});
```

# UI: grouping + collapsibles + virtualization

* **Group** raw events into display rows:

  * Stitch `model.delta` → running assistant bubble, finalize on `model.complete`.
  * Nest `agent.action.*` under a `<details>` collapsible row.
* **Virtualize** with `@tanstack/react-virtual` to handle long histories.
* **State split:** TanStack Query = server data; Zustand = UI state (expanded rows, scroll lock).

# Production checklist

**Server**

* Disable buffering (nginx `X-Accel-Buffering: no`), no gzip, extend idle timeouts.
* Durable event log; `id = seq` for resume; heartbeats.
* Auth via cookies/session; CORS for `text/event-stream`.

**Client**

* Batch updates (RAF) to avoid render storms.
* Sort by `seq`, de-dupe by `id`.
* Persist last `seq` in `sessionStorage` (nice to have).
* Validate payloads (zod) before cache insert.

# Variants / when to switch

* Need custom headers? Use `fetch` + `ReadableStream` + `eventsource-parser` (same cache-update pattern).
* Heavy streams? Parse/validate in a Web Worker and `postMessage` batched events.

That’s the essence. If you want, I can trim this further into a drop-in `useSSEQuery()` hook + minimal `ChatPane` with collapsibles and virtualization.
