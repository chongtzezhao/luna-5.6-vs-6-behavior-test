# Round 1 · gpt-5.6-luna · Test 12

## Turn 1

### User

```text
suppose i wanted include_router to snapshot the child router at include time instead of reflecting later changes. don't implement it. can u tell me roughly what would actually need to change in this codebase and what behavior/tests we'd risk breaking
```

### Assistant

Yes. In this checkout, `include_router()` is deliberately live:

- It appends an `_IncludedRouter` containing the original router.
- Requests/OpenAPI lazily build “effective” route contexts from that original router.
- `_routes_version` invalidates those caches when routes are added.
- Nested `_IncludedRouter`s are recursively followed, so changes deep in the tree can appear later.

Relevant code: [`include_router()`](https://github.com/fastapi/fastapi/blob/95f8322ee1dcda7ceace7b1c4f6c9915b36d748f/fastapi/routing.py#L3133), [`_IncludedRouter`](https://github.com/fastapi/fastapi/blob/95f8322ee1dcda7ceace7b1c4f6c9915b36d748f/fastapi/routing.py#L1586), and route-version handling around [`_get_routes_version()`](https://github.com/fastapi/fastapi/blob/95f8322ee1dcda7ceace7b1c4f6c9915b36d748f/fastapi/routing.py#L2581).

To make inclusion snapshot-based, the main changes would likely be:

1. Materialize the child route tree during `include_router()`

Instead of storing only:

```python
_IncludedRouter(original_router=router, include_context=...)
```

it would need to capture the child’s current routes, including nested included routers, and construct an independent snapshot for that inclusion.

A shallow copy of `router.routes` would not be enough, because nested `_IncludedRouter`s would still point at live child routers. The snapshot boundary would need to recurse through:

- `APIRoute`
- websocket routes
- Starlette `Route`, `Mount`, `Host`, etc.
- `_FrontendRouteGroup`
- nested `APIRouter` inclusions

2. Preserve per-inclusion metadata in the snapshot

The same router can be included multiple times with different prefixes, tags, dependencies, response classes, callbacks, and schema settings. So the snapshot must be built per inclusion, not stored back onto the child router.

The effective-context machinery currently handles this lazily through `_RouterIncludeContext.combine()` and `_EffectiveRouteContext.from_api_route()`. A snapshot implementation would likely move that work into inclusion time or create a frozen equivalent of those objects.

3. Decide what gets copied versus shared

Endpoints and dependency callables should remain shared by identity. Route configuration would need to be copied sufficiently that later mutations to the child route do not affect the included snapshot.

This is especially relevant to:

- `tags`
- `dependencies`
- `responses`
- callbacks
- response models and response classes
- `include_in_schema`
- generated operation IDs
- strict content-type settings
- websocket dependencies
- Starlette route/mount path data

A full `deepcopy()` would probably be unsafe or excessive; this would need deliberate route-type-specific copying.

4. Rework or reduce live-cache/version logic

With a true snapshot, `_IncludedRouter.effective_candidates()` would no longer need to re-read `original_router.routes` or compare the child’s `_routes_version`.

However, route-version handling would still matter for:

- routes added directly to the app/router after inclusion
- OpenAPI cache invalidation for those direct changes
- frontend low-priority route caches

The app’s current OpenAPI logic explicitly uses the recursive route version:

```python
routes_version = self.router._get_routes_version()
```

That recursion would need to stop at the snapshot boundary.

5. Define lifecycle semantics explicitly

Startup/shutdown handlers are already copied/merged at include time:

```python
for handler in router.on_startup:
    self.add_event_handler("startup", handler)
...
self.lifespan_context = _merge_lifespan_context(...)
```

So ordinary later additions to the child’s lifecycle handlers are not currently live in the same way routes are. But nested-router lifecycle changes can be subtle. A snapshot design should specify whether the child’s lifespan context and event handlers are captured recursively at the exact include point.

The clearest behavior change would break these existing tests:

- [`test_live_route_addition_uses_include_metadata_for_runtime_and_openapi`](https://github.com/fastapi/fastapi/blob/95f8322ee1dcda7ceace7b1c4f6c9915b36d748f/tests/test_router_include_context.py#L226)
- [`test_openapi_cache_updates_after_live_route_addition`](https://github.com/fastapi/fastapi/blob/95f8322ee1dcda7ceace7b1c4f6c9915b36d748f/tests/test_router_include_context.py#L254)
- [`test_nested_router_added_after_parent_inclusion_is_live`](https://github.com/fastapi/fastapi/blob/95f8322ee1dcda7ceace7b1c4f6c9915b36d748f/tests/test_router_include_context.py#L273)
- [`test_low_priority_cache_updates_after_route_added_to_included_router`](https://github.com/fastapi/fastapi/blob/95f8322ee1dcda7ceace7b1c4f6c9915b36d748f/tests/test_frontend.py#L929)
- [`test_url_path_for_uses_effective_context_for_live_included_route`](https://github.com/fastapi/fastapi/blob/95f8322ee1dcda7ceace7b1c4f6c9915b36d748f/tests/test_router_include_context.py#L310)

Those would either need to be changed to assert the new behavior or replaced with snapshot tests.

The main compatibility risks are:

- Routes registered after inclusion silently not being served.
- OpenAPI no longer showing routes added later.
- Nested routers added after a parent was included no longer appearing.
- Frontend fallback behavior no longer yielding to API routes added after inclusion.
- `url_path_for()` no longer finding names added after inclusion.
- Direct mutation of child router configuration after inclusion no longer affecting the app.
- Users relying on dynamically assembled routers—where inclusion happens before all decorators run—getting incomplete APIs.

The safest conceptual model would be: “`include_router()` freezes the complete route/lifespan/configuration graph as of that call; later changes require another `include_router()` call or an explicit rebuild.”
