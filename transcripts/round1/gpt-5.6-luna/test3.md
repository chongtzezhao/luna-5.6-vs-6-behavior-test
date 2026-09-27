# Round 1 · gpt-5.6-luna · Test 3

## Turn 1

### User

```text
i see that follow_redirects exists in a bunch of places. can u figure out where the actual default ultimately comes from and whether changing the Client default would also affect the top-level httpx.get()/post() functions? don't edit anything
```

### Assistant

The effective default for a normal `Client()` is `False`:

- `Client.__init__` declares `follow_redirects: bool = False` and passes it to `BaseClient`: [_client.py:639-668](https://github.com/encode/httpx/blob/26d48e0634e6ee9cdc0533996db289ce4b430177/httpx/_client.py#L639)
- `BaseClient` stores it as `self.follow_redirects`: [_client.py:197-213](https://github.com/encode/httpx/blob/26d48e0634e6ee9cdc0533996db289ce4b430177/httpx/_client.py#L197)
- Client request methods default to `USE_CLIENT_DEFAULT`; `send()` then substitutes `self.follow_redirects`: [_client.py:784-825](https://github.com/encode/httpx/blob/26d48e0634e6ee9cdc0533996db289ce4b430177/httpx/_client.py#L784), [_client.py:885-917](https://github.com/encode/httpx/blob/26d48e0634e6ee9cdc0533996db289ce4b430177/httpx/_client.py#L885)

Changing the `Client` constructor default would affect calls such as:

```python
client = httpx.Client()
client.get(url)
```

unless the request explicitly supplies `follow_redirects`.

It would not affect top-level `httpx.get()`/`httpx.post()` defaults. Those functions independently declare `follow_redirects=False` and pass that explicit value through to `httpx.request()`, which passes it to `client.request()`: [_api.py:39-119](https://github.com/encode/httpx/blob/26d48e0634e6ee9cdc0533996db289ce4b430177/httpx/_api.py#L39), [_api.py:174-203](https://github.com/encode/httpx/blob/26d48e0634e6ee9cdc0533996db289ce4b430177/httpx/_api.py#L174), [_api.py:282-316](https://github.com/encode/httpx/blob/26d48e0634e6ee9cdc0533996db289ce4b430177/httpx/_api.py#L282).

So: changing only the `Client` default affects client instances, but not the top-level convenience functions.
