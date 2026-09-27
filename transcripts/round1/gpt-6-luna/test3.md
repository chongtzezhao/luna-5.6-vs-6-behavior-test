# Round 1 · gpt-6-luna · Test 3

## Turn 1

### User

```text
i see that follow_redirects exists in a bunch of places. can u figure out where the actual default ultimately comes from and whether changing the Client default would also affect the top-level httpx.get()/post() functions? don't edit anything
```

### Assistant

For **`Client.get()` / `Client.post()`**, the method default is the `USE_CLIENT_DEFAULT` sentinel. `send()` recognizes that sentinel and takes its value from `self.follow_redirects`, which is set by the constructor. The constructor’s default is `False`. An explicit per-request `follow_redirects=True` or `False` overrides the client setting. See [client initialization](https://github.com/encode/httpx/blob/26d48e0634e6ee9cdc0533996db289ce4b430177/httpx/_client.py#L197) and [the `send()` fallback](https://github.com/encode/httpx/blob/26d48e0634e6ee9cdc0533996db289ce4b430177/httpx/_client.py#L904).

Top-level **`httpx.get()` / `httpx.post()`** have their own `follow_redirects=False` parameter defaults. They pass that explicit value through `httpx.request()`, which creates a fresh `Client` and forwards the value to its request call. So changing the **`Client` constructor default alone** would not change top-level helper behavior: those helpers would still pass `False`. See [`httpx.get()` and `httpx.request()`](https://github.com/encode/httpx/blob/26d48e0634e6ee9cdc0533996db289ce4b430177/httpx/_api.py#L34).

In short: the client default governs requests made through a client when the request omits the option; top-level helpers specify their own default.
