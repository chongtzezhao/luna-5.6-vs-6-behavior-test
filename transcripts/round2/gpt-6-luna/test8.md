# Round 2 · gpt-6-luna · Test 8

## Turn 1

### User

```text
i noticed include_router doesn't seem to directly append all the child's APIRoutes anymore. is that actually a meaningful architecture change or am i reading too much into an implementation detail? can u check
```

### Assistant

Yes, it’s a real architecture change in FastAPI **0.137.0**. `include_router()` now stores an `_IncludedRouter` that points to the child router, so the route structure can remain a tree. FastAPI builds effective routes from that tree for matching, URL generation, and OpenAPI.

The practical change is that the child router and its `APIRoute` instances are preserved instead of cloned into one flat list. This lets routes added to a child *after* inclusion appear in the parent, and lets the same router be included in multiple places without cloning its routes. The release notes describe it as an internal refactor that also enables future router-level features.

So you’re reading the implementation correctly, and the change is meaningful under the hood. But `router.routes` is now explicitly an internal implementation detail; code that assumed it was a flat list of `APIRoute`s may break. See the [0.137.0 release notes](https://github.com/fastapi/fastapi/blob/master/docs/en/docs/release-notes.md) and the implementation in [routing.py](https://github.com/fastapi/fastapi/blob/95f8322ee1dcda7ceace7b1c4f6c9915b36d748f/fastapi/routing.py#L3133).
