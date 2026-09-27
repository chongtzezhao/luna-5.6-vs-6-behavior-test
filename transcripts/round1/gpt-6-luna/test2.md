# Round 1 · gpt-6-luna · Test 2

## Turn 1

### User

```text
can u look at how client-level query params and request-level params get combined? don't change anything. im particularly interested in whether Client and AsyncClient behave differently here
```

### Assistant

`Client` and `AsyncClient` use the same parameter merge logic in the shared base class, so they behave the same.

During `build_request()`, HTTPX combines client parameters with request parameters. Request parameters override client parameters when they use the same key; other client parameters are kept. For example, client params `a=1&b=2` plus request params `b=3&c=4` produce `a=1&b=3&c=4`. A request value with multiple values replaces the client’s values for that key.

The merge happens when building the request, not in `send()`. So if you pass an already-built `Request` to `send()`, its URL is sent as-is; client-level params are not added then.

The implementation is in [`_merge_queryparams()`](https://github.com/encode/httpx/blob/26d48e0634e6ee9cdc0533996db289ce4b430177/httpx/_client.py#L433), called by the shared [`build_request()`](https://github.com/encode/httpx/blob/26d48e0634e6ee9cdc0533996db289ce4b430177/httpx/_client.py#L340). `QueryParams.merge()` implements the override behavior in [`_urls.py`](https://github.com/encode/httpx/blob/26d48e0634e6ee9cdc0533996db289ce4b430177/httpx/_urls.py#L582). The existing echo test covers adding distinct client and request keys in [`test_queryparams.py`](https://github.com/encode/httpx/blob/26d48e0634e6ee9cdc0533996db289ce4b430177/tests/client/test_queryparams.py#L25).

## Turn 2

### User

```text
what about params={} vs params=None?
```

### Assistant

For client-level params, `params={}` and `params=None` behave the same: both mean “no request-level parameters,” so any client-level params are retained.

The merge code checks whether either side is truthy. If client params exist, it copies them and merges the request params. An empty mapping adds nothing; `None` also adds nothing. If the client has no params either, both are passed through to `Request`, where neither changes the URL.

So neither `{}` nor `None` clears client-level params. A request-level value with the same key overrides that client key.

## Turn 3

### User

```text
so if i wanted only AsyncClient to behave differently, is that actually a localized change?
```

### Assistant

Yes, **if the difference should apply only when building requests through `AsyncClient`**, it can be localized: `AsyncClient` inherits `build_request()` from the shared base class, so it could override that method or the query-parameter merge helper.

One caveat: overriding the shared `_merge_queryparams()` helper would affect any code path using it on the async client, but leave `Client` unchanged. The exact behavior you want for `params={}` versus `params=None` matters: currently both are treated as “no request-level params,” so client-level params remain. If you want `{}` to clear client-level params for `AsyncClient`, the merge logic needs to distinguish an explicitly empty mapping from `None`.
