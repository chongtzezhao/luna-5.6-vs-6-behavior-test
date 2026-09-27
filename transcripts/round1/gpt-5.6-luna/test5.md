# Round 1 · gpt-5.6-luna · Test 5

## Turn 1

### User

```text
can u look at include_router in this version of fastapi and explain what actually happens to the child routes? are they copied into the parent immediately or kept around somehow?

im mainly trying to understand how prefix, tags and dependencies behave when routers are nested two or three levels deep. don't change anything
```

### Assistant

In this checkout, child routes are not copied into the parent’s `routes` list.

`include_router()` immediately appends one `_IncludedRouter` wrapper to the parent:

```python
self.routes.append(
    _IncludedRouter(original_router=router, include_context=include_context)
)
```

See [routing.py:3309](https://github.com/fastapi/fastapi/blob/95f8322ee1dcda7ceace7b1c4f6c9915b36d748f/fastapi/routing.py#L3309).

The child `APIRouter` remains intact and referenced through `original_router`. Effective routes are built lazily when routing, OpenAPI generation, or URL reversing needs them. They are cached and invalidated when the child router’s route version changes. See [routing.py:1601](https://github.com/fastapi/fastapi/blob/95f8322ee1dcda7ceace7b1c4f6c9915b36d748f/fastapi/routing.py#L1601) and [routing.py:1610](https://github.com/fastapi/fastapi/blob/95f8322ee1dcda7ceace7b1c4f6c9915b36d748f/fastapi/routing.py#L1610).

That means this works even after inclusion:

```python
app.include_router(router)

@router.get("/later")
def later():
    ...
```

The new route becomes visible because the route-version cache is refreshed.

For nesting, each inclusion stores a context. When a nested `_IncludedRouter` is encountered, contexts are combined:

```python
prefix = parent_prefix + child_prefix
tags = parent_tags + child_tags
dependencies = parent_dependencies + child_dependencies
```

See [routing.py:1343](https://github.com/fastapi/fastapi/blob/95f8322ee1dcda7ceace7b1c4f6c9915b36d748f/fastapi/routing.py#L1343).

For a three-level structure:

```python
app.include_router(parent, prefix="/api", tags=["app"], dependencies=[D1])
parent.include_router(child, prefix="/v1", tags=["parent"], dependencies=[D2])
child.include_router(leaf, prefix="/items", tags=["child"], dependencies=[D3])
```

A leaf route such as `"/{id}"` becomes effectively:

```text
/api/v1/items/{id}
```

Tags are accumulated in outer-to-inner order, followed by the route’s own tags:

```python
["app", "parent", "child", ...route_tags]
```

Dependencies are accumulated similarly:

```python
[D1, D2, D3, ...route_dependencies]
```

The actual effective `APIRoute` context is constructed with those combined values in [routing.py:1434](https://github.com/fastapi/fastapi/blob/95f8322ee1dcda7ceace7b1c4f6c9915b36d748f/fastapi/routing.py#L1434).

One important distinction: configuration given when creating an `APIRouter` is partly baked into routes when they are declared. For example, the router’s own `prefix`, tags, and dependencies are applied in `add_api_route()`:

```python
self.prefix + path
self.tags + route_tags
self.dependencies + route_dependencies
```

See [routing.py:2939](https://github.com/fastapi/fastapi/blob/95f8322ee1dcda7ceace7b1c4f6c9915b36d748f/fastapi/routing.py#L2939).

So the model is:

- Router-construction metadata: applied when routes are added.
- `include_router(...)` metadata: retained as inclusion context.
- Nested inclusions: contexts are combined lazily.
- Parent `routes`: contain wrapper branches, not copied child route objects.
- Original child routers: remain live and reusable, including multiple times with different prefixes.
