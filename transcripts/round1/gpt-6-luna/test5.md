# Round 1 · gpt-6-luna · Test 5

## Turn 1

### User

```text
can u look at include_router in this version of fastapi and explain what actually happens to the child routes? are they copied into the parent immediately or kept around somehow?

im mainly trying to understand how prefix, tags and dependencies behave when routers are nested two or three levels deep. don't change anything
```

### Assistant

In this checkout, `include_router` does **not** immediately copy every child route into the parent. It appends an `_IncludedRouter` wrapper to the parent’s `routes`, holding a reference to the original router and the include settings. The wrapper builds effective route contexts when it needs them, and caches those contexts. The cache is versioned, so routes added to a child router after inclusion can still be picked up later. See [`include_router`](<https://github.com/fastapi/fastapi/blob/95f8322ee1dcda7ceace7b1c4f6c9915b36d748f/fastapi/routing.py#L3133>) and [`_IncludedRouter`](<https://github.com/fastapi/fastapi/blob/95f8322ee1dcda7ceace7b1c4f6c9915b36d748f/fastapi/routing.py#L1586>).

For nested routers, each include adds its settings to the context passed down to child routes:

- **Prefixes concatenate** in order. For example, including a router at `/v1` and then a nested router at `/users` gives its `/` route the path `/v1/users/`. The final path is assembled by `path_for`.
- **Tags accumulate** as lists: outer include tags, then nested include tags, then the endpoint’s own tags.
- **Dependencies accumulate** in that same outer-to-inner-to-endpoint order. They are combined into the effective route context; the normal dependency system then handles resolution and caching at request time.

That means a route nested two or three levels deep gets the settings from each include along its path. Tags affect the operation’s OpenAPI metadata; dependencies affect request handling. The accumulation happens through `_RouterIncludeContext.combine` and `_EffectiveRouteContext.from_api_route` in [`routing.py`](<https://github.com/fastapi/fastapi/blob/95f8322ee1dcda7ceace7b1c4f6c9915b36d748f/fastapi/routing.py#L1340>).

One distinction: a router’s own `prefix`, `tags`, and `dependencies` are applied when routes are registered on that router. The arguments passed to `include_router(...)` add settings at the point where that router is included. So for a deeply nested route, both its registration settings and each enclosing include’s settings can contribute.
