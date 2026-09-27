# Round 1 · gpt-6-luna · Test 12

## Turn 1

### User

```text
suppose i wanted include_router to snapshot the child router at include time instead of reflecting later changes. don't implement it. can u tell me roughly what would actually need to change in this codebase and what behavior/tests we'd risk breaking
```

### Assistant

`include_router` already captures the include options—prefix, tags, dependencies, responses, and so on—in an include context. The live behavior comes from storing a reference to the child router and reading its routes later.

In [routing.py](https://github.com/fastapi/fastapi/blob/95f8322ee1dcda7ceace7b1c4f6c9915b36d748f/fastapi/routing.py#L1586), `_IncludedRouter` holds `original_router`. Its candidate-building methods iterate `original_router.routes` and `_low_priority_routes`, and cache the result against the router’s route version. Nested included routers are also expanded lazily. So adding a route to a child after inclusion can affect the parent after cache invalidation.

To make inclusion a snapshot, the main change would be to capture the child’s route structure when `include_router` is called, then have the included branch build candidates from that captured structure instead of consulting the child’s current routes. Nested routers need a defined snapshot boundary too: a shallow capture of route objects would still see later changes through nested `_IncludedRouter` references. Startup and shutdown handlers are copied during inclusion today, but lifespan composition and other router-level settings would need to be checked against the intended snapshot semantics.

A snapshot would not automatically mean a deep copy. Existing route objects, endpoint functions, dependency callables, callback lists, and mutable metadata may still be shared. The design would need to say whether “snapshot” freezes just which routes are included, or also freezes their configuration.

Likely compatibility risks:

- **Routes added after inclusion:** They currently can become visible through the included router; snapshot semantics would hide them. This includes routes added to nested routers.
- **Routes changed or removed after inclusion:** The current implementation retains the router reference and rebuilds from its route state, so edits may affect the include. A snapshot could keep old route objects or old structure, depending on how deeply it copies.
- **Multiple includes and nested includes:** Including the same child under different prefixes/options, or including a parent before later adding to its child, needs clear snapshot timing at each include call.
- **Router-level defaults changed after inclusion:** `default_response_class`, `generate_unique_id_function`, strict content type, and dependency override provider are consulted while effective route contexts are built. A snapshot could change whether later mutations to these settings are reflected.
- **OpenAPI and route lookup:** Effective routes feed request matching, URL generation, and schema generation. Those paths must all observe the same snapshot or users could get mismatches between served routes and docs.
- **Startup, shutdown, and lifespan:** Event handlers are copied at include time already; lifespan contexts are merged then. Snapshot work should preserve their current behavior and check nested-router cases, especially if the intended snapshot includes later lifespan or event changes.
- **Internal tests and extension code:** Tests in `test_router_include_context.py` inspect `_IncludedRouter` and its caches directly. External code may also depend on route objects or router references, even though those internals are not a stable public API.

The most relevant existing tests are in [test_router_include_context.py](https://github.com/fastapi/fastapi/blob/95f8322ee1dcda7ceace7b1c4f6c9915b36d748f/tests/test_router_include_context.py#L764), which exercises included-route contexts, nested includes, and caching, and [test_router_events.py](https://github.com/fastapi/fastapi/blob/95f8322ee1dcda7ceace7b1c4f6c9915b36d748f/tests/test_router_events.py#L330), which checks lifecycle handlers. I didn’t find an obvious test specifically asserting that adding a route after inclusion makes it appear; that behavior looks like a consequence of the lazy, versioned traversal and would be a good targeted compatibility test if this change were pursued.
