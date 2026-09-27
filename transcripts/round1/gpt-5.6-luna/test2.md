# Round 1 · gpt-5.6-luna · Test 2

## Turn 1

### User

```text
can u look at how client-level query params and request-level params get combined? don't change anything. im particularly interested in whether Client and AsyncClient behave differently here
```

### Assistant

Client and AsyncClient behave the same here.

The shared implementation is in [`BaseClient._merge_queryparams()`](https://github.com/encode/httpx/blob/26d48e0634e6ee9cdc0533996db289ce4b430177/httpx/_client.py#L433):

- Client-level params are copied first.
- Request-level params are merged on top.
- If the same key exists at both levels, the request-level value replaces the client-level value.
- Different keys are combined.
- Repeated values within one level, such as `{"x": ["1", "2"]}`, are preserved.

Both `Client` and `AsyncClient` inherit [`BaseClient.build_request()`](https://github.com/encode/httpx/blob/26d48e0634e6ee9cdc0533996db289ce4b430177/httpx/_client.py#L340), so their `get()`, `request()`, etc. all use the same merging logic. The only difference is whether sending is synchronous or asynchronous.

One important edge case: effective `params` are passed to `Request`, whose constructor replaces any query string already present in the URL ([`_models.py:399`](https://github.com/encode/httpx/blob/26d48e0634e6ee9cdc0533996db289ce4b430177/httpx/_models.py#L399)). For example:

```python
client = httpx.Client(params={"a": "client"})
client.build_request(
    "GET",
    "https://example.com/?url=value",
    params={"b": "request"},
).url
# https://example.com/?a=client&b=request
```

The original `url=value` query is discarded. This is identical for `AsyncClient`.

The existing test coverage directly checks the synchronous case in [`tests/client/test_queryparams.py`](https://github.com/encode/httpx/blob/26d48e0634e6ee9cdc0533996db289ce4b430177/tests/client/test_queryparams.py#L25), but there does not appear to be a corresponding AsyncClient-specific query-param test. I also verified the same resulting URL from both clients at runtime. No files were changed.

## Turn 2

### User

```text
what about params={} vs params=None?
```

### Assistant

`params={}` and `params=None` differ mainly when the URL already has a query string.

- `params=None`: no request-level params are supplied. If the client has no params, the URL’s existing query is preserved.
- `params={}`: explicitly supplies an empty parameter set. This is passed to `Request`, which replaces the URL query with an empty one—effectively removing it.

Examples:

```python
client = httpx.Client()

client.build_request("GET", "https://example.com/?a=1", params=None).url
# https://example.com/?a=1

client.build_request("GET", "https://example.com/?a=1", params={}).url
# https://example.com/
```

With client-level params:

```python
client = httpx.Client(params={"client": "1"})

client.build_request("GET", "https://example.com/?url=1", params=None).url
# https://example.com/?client=1

client.build_request("GET", "https://example.com/?url=1", params={}).url
# https://example.com/?client=1
```

In that case, `{}` does not suppress client-level params; it simply contributes nothing to the merge.

This behavior is shared by `Client` and `AsyncClient`, through [`_merge_queryparams()`](https://github.com/encode/httpx/blob/26d48e0634e6ee9cdc0533996db289ce4b430177/httpx/_client.py#L433) and [`Request`](https://github.com/encode/httpx/blob/26d48e0634e6ee9cdc0533996db289ce4b430177/httpx/_models.py#L399).

## Turn 3

### User

```text
so if i wanted only AsyncClient to behave differently, is that actually a localized change?
```

### Assistant

Yes—if the desired difference is specifically query-param merging, it can be localized to `AsyncClient`.

The smallest design would be for `AsyncClient` to override `_merge_queryparams()`, while `Client` continues using the shared [`BaseClient` implementation](https://github.com/encode/httpx/blob/26d48e0634e6ee9cdc0533996db289ce4b430177/httpx/_client.py#L433). Since `build_request()` is inherited, all AsyncClient request paths would then consistently use the altered behavior.

That would affect:

- `AsyncClient.request()`
- `get()`, `post()`, etc.
- `stream()`
- direct `AsyncClient.build_request()`

If the difference should apply only to one async method, then that method—or `build_request()`—would need to be overridden instead.

So: localized in code, yes, but potentially broad across all AsyncClient request construction. A focused async test should accompany the change.
