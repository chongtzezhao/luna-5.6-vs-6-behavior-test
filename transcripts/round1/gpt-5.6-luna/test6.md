# Round 1 · gpt-5.6-luna · Test 6

This continues the Test 5 session.

## Turn 1

### User

```text
what happens if i add another route to the child after it has already been included?
```

### Assistant

It becomes available automatically on the next route lookup—no need to call `include_router()` again.

When you add a route:

1. It is appended to the child router’s own `routes`.
2. The child’s `_routes_version` is incremented.
3. The parent’s included-router wrapper notices the version changed.
4. Its cached effective routes are rebuilt, applying the original inclusion metadata again.

Relevant code: [route addition/versioning](https://github.com/fastapi/fastapi/blob/95f8322ee1dcda7ceace7b1c4f6c9915b36d748f/fastapi/routing.py#L2570) and [cache refresh](https://github.com/fastapi/fastapi/blob/95f8322ee1dcda7ceace7b1c4f6c9915b36d748f/fastapi/routing.py#L1601).

Example:

```python
app.include_router(child, prefix="/api")

@child.get("/later")
def later():
    return {"ok": True}
```

The route is then available at:

```text
/api/later
```

Any nested prefixes, tags, and dependencies from the existing inclusion chain are applied to it too. OpenAPI also sees it because FastAPI tracks the route version and regenerates the schema when needed.

The only practical caveat is that an already-running request won’t change midway through; subsequent routing/OpenAPI operations see the new route.

## Turn 2

### User

```text
can u prove that with a minimal test? don't change library source
```

### Assistant

I couldn’t execute the runtime test because this checkout’s active Python environment is missing `starlette`:

```text
ModuleNotFoundError: No module named 'starlette'
```

The minimal test is:

```python
from fastapi import APIRouter, FastAPI
from fastapi.testclient import TestClient

child = APIRouter()
app = FastAPI()
app.include_router(child, prefix="/api")

client = TestClient(app)

assert client.get("/api/later").status_code == 404

child.add_api_route(
    "/later",
    lambda: {"ok": True},
    methods=["GET"],
)

assert client.get("/api/later").json() == {"ok": True}
assert "/api/later" in client.get("/openapi.json").json()["paths"]
```

The source path confirms why this should pass:

- Adding a route increments the child router’s route version: [routing.py:2570](https://github.com/fastapi/fastapi/blob/95f8322ee1dcda7ceace7b1c4f6c9915b36d748f/fastapi/routing.py#L2570)
- The included wrapper checks that version and rebuilds its cached effective routes: [routing.py:1601](https://github.com/fastapi/fastapi/blob/95f8322ee1dcda7ceace7b1c4f6c9915b36d748f/fastapi/routing.py#L1601)
- The parent still contains an `_IncludedRouter`, not a copied route list: [routing.py:3309](https://github.com/fastapi/fastapi/blob/95f8322ee1dcda7ceace7b1c4f6c9915b36d748f/fastapi/routing.py#L3309)

No files were changed.
