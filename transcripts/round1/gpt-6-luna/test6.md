# Round 1 · gpt-6-luna · Test 6

This continues the Test 5 session.

## Turn 1

### User

```text
what happens if i add another route to the child after it has already been included?
```

### Assistant

It should be picked up. The parent keeps a reference to the child router through `_IncludedRouter`, rather than copying its routes at inclusion time. When routes are requested, FastAPI checks the child router’s route version and rebuilds the cached effective routes if that version changed.

So a route added to the child **after** `include_router` can still be served through the parent, with the same accumulated prefix, tags, and dependencies. That depends on the child router’s normal route-adding methods, which bump its version.

## Turn 2

### User

```text
can u prove that with a minimal test? don't change library source
```

### Assistant

The minimal test confirms it: I included an empty child router at `/child`, then added `GET /late` to the child afterward. The parent served it at `/child/late`, and the OpenAPI operation included the inherited `included` tag:

```text
status: 200
json: {'route': 'added after include'}
openapi tags: ['included']
```

I ran the test against this checkout using the project’s `.venv`; I didn’t change library source.
