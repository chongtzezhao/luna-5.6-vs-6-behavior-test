# Round 1 · gpt-6-luna · Test 7

## Turn 1

### User

```text
can u look at the frontend() stuff in this repo and briefly tell me how it actually fits into fastapi routing? im mainly confused whether frontend routes are a completely separate mechanism or whether normal fastapi dependencies still apply
```

### Assistant

`frontend()` is a separate route type for serving a static build, but it’s integrated into FastAPI’s routing. FastAPI checks regular routes first, then checks frontend routes as a low-priority fallback. That lets API endpoints take precedence when their paths overlap. See [routing.py](https://github.com/fastapi/fastapi/blob/95f8322ee1dcda7ceace7b1c4f6c9915b36d748f/fastapi/routing.py#L2630).

Dependencies still apply. App-level dependencies and the `APIRouter`’s dependencies run for a frontend request that reaches that frontend route. Dependencies added when including a router apply too. Normal dependency features such as overrides, validation, response headers, and background tasks are handled there. If an API route wins, the frontend dependencies don’t run.

So: frontend serving is distinct from a path-operation function, but its routing still uses FastAPI’s dependency system. The frontend route itself only handles `GET` and `HEAD` and serves files or a configured fallback.
