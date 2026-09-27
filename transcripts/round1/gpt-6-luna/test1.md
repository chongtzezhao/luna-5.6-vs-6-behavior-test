# Round 1 · gpt-6-luna · Test 1

## Turn 1

### User

```text
can u check how NO_PROXY is actually handled here? if HTTP_PROXY is set but localhost is in NO_PROXY, where does HTTPX decide to bypass the proxy? don't change anything
```

### Assistant

With the default `trust_env=True`, HTTPX reads environment proxies when you create a client. `get_environment_proxies()` in [httpx/_utils.py](https://github.com/encode/httpx/blob/26d48e0634e6ee9cdc0533996db289ce4b430177/httpx/_utils.py#L31) turns `HTTP_PROXY` into an `http://` mount and `NO_PROXY=localhost` into an `all://localhost` mount with no proxy transport.

When sending a request, [`_transport_for_url()`](https://github.com/encode/httpx/blob/26d48e0634e6ee9cdc0533996db289ce4b430177/httpx/_client.py#L760) checks the mounts in specificity order. For `http://localhost/...`, the `all://localhost` rule matches before the general `http://` rule, so HTTPX uses its normal transport and bypasses the proxy. Requests to other HTTP hosts can use `HTTP_PROXY`.

The `localhost` rule also matches `localhost` with a port. The bypass applies when environment proxies are enabled; for example, `trust_env=False` disables reading them.
