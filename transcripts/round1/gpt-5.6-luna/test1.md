# Round 1 · gpt-5.6-luna · Test 1

## Turn 1

### User

```text
can u check how NO_PROXY is actually handled here? if HTTP_PROXY is set but localhost is in NO_PROXY, where does HTTPX decide to bypass the proxy? don't change anything
```

### Assistant

HTTPX handles `NO_PROXY` by turning it into a special transport mount.

Flow for:

```text
HTTP_PROXY=http://proxy:8080
NO_PROXY=localhost
http://localhost:8000
```

1. `get_environment_proxies()` calls Python’s `urllib.request.getproxies()`, which reads the proxy environment variables ([`_utils.py:30-37`](https://github.com/encode/httpx/blob/26d48e0634e6ee9cdc0533996db289ce4b430177/httpx/_utils.py#L30)).

2. `HTTP_PROXY` becomes:

```python
{"http://": "http://proxy:8080"}
```

3. `NO_PROXY=localhost` adds an exclusion mount:

```python
{"all://localhost": None}
```

See [`_utils.py:47-74`](https://github.com/encode/httpx/blob/26d48e0634e6ee9cdc0533996db289ce4b430177/httpx/_utils.py#L47).

4. The client converts proxy URLs into proxy transports, while `None` means “use the normal direct transport” ([`_client.py:239-247`](https://github.com/encode/httpx/blob/26d48e0634e6ee9cdc0533996db289ce4b430177/httpx/_client.py#L239)).

5. Mounts are sorted by specificity, so `all://localhost` is checked before the generic `http://` proxy mount ([`_client.py:697-716`](https://github.com/encode/httpx/blob/26d48e0634e6ee9cdc0533996db289ce4b430177/httpx/_client.py#L697)). When routing the request, the matching `None` mount returns the base transport instead of the proxy transport ([`_client.py:763-769`](https://github.com/encode/httpx/blob/26d48e0634e6ee9cdc0533996db289ce4b430177/httpx/_client.py#L763).

So the bypass decision happens in `Client._transport_for_url()`: `NO_PROXY` has already been represented as a more-specific mount whose transport is `None`.

This also applies to `AsyncClient` through its equivalent routing method. `trust_env=False`, or supplying an explicit transport, prevents environment proxy mounts from being created in the first place.
