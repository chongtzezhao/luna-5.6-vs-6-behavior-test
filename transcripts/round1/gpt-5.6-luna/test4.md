# Round 1 · gpt-5.6-luna · Test 4

## Turn 1

### User

```text
can u find where proxy bypass behavior is tested? i want to know if localhost, explicit ports, IP addresses, and wildcards are all covered. don't make changes yet
```

### Assistant

Proxy bypass behavior is mainly tested in:

- [tests/client/test_proxies.py:128](https://github.com/encode/httpx/blob/26d48e0634e6ee9cdc0533996db289ce4b430177/tests/client/test_proxies.py#L128) — `NO_PROXY` behavior, run for both `Client` and `AsyncClient`.
- [tests/test_utils.py:89](https://github.com/encode/httpx/blob/26d48e0634e6ee9cdc0533996db289ce4b430177/tests/test_utils.py#L89) — conversion of environment variables into proxy mounts.
- [tests/test_utils.py:115](https://github.com/encode/httpx/blob/26d48e0634e6ee9cdc0533996db289ce4b430177/tests/test_utils.py#L115) — URL pattern matching, including ports.

Coverage summary:

| Case | Covered? | Where |
|---|---|---|
| `localhost` | Partially | Environment parsing only at `tests/test_utils.py:103`; no end-to-end `NO_PROXY=localhost` request-selection test |
| Explicit ports | Partially | URL pattern matching at `tests/test_utils.py:121-123`; proxy routing at `tests/client/test_proxies.py:54-61`; no explicit-port `NO_PROXY` bypass test |
| IP addresses | Partially | `127.0.0.1` bypass end-to-end at `tests/client/test_proxies.py:150-155`; IPv4 CIDR and IPv6 parsing only at `tests/test_utils.py:100-102` |
| Wildcards | Yes, mostly | `NO_PROXY=*` end-to-end at `tests/client/test_proxies.py:217-222`; domain wildcard/suffix behavior at `tests/client/test_proxies.py:205-215` |

So the likely gaps are:

- `NO_PROXY=localhost` actually selecting the direct transport.
- `NO_PROXY` entries containing explicit ports.
- End-to-end bypass tests for IPv6 and IPv4 CIDR ranges.
- Possibly comma-separated wildcard cases such as `NO_PROXY=example.com,*`.

No files were changed.

## Turn 2

### User

```text
are there any obvious coverage gaps?
```

### Assistant

Yes. The most obvious gaps are:

- `NO_PROXY=localhost` is only tested as environment parsing in [tests/test_utils.py:103](https://github.com/encode/httpx/blob/26d48e0634e6ee9cdc0533996db289ce4b430177/tests/test_utils.py#L103), not as an actual request-routing bypass.
- Explicit ports are tested for `URLPattern` and proxy mounts, but not for `NO_PROXY`, e.g. `NO_PROXY=localhost:8000` or `NO_PROXY=example.com:8443`.
- IPv6 bypass is only tested during parsing (`::1`), not end-to-end.
- IPv4 CIDR is only tested during parsing (`192.168.0.0/16`). More importantly, the current matcher appears not to implement CIDR matching: `192.168.1.1` does not match a `192.168.0.0/16` exclusion.
- Wildcard behavior is only directly tested for `NO_PROXY=*`. The domain wildcard cases (`.example.com`, suffix matching) are tested, but mixed wildcard lists such as `NO_PROXY=internal.example.com,*` are not.
- There is no explicit test that `NO_PROXY` matching works for both HTTP and HTTPS when the exclusion has no scheme, or that a scheme-qualified exclusion only bypasses that scheme beyond the existing one negative case.

The highest-value additions would be end-to-end tests for localhost, explicit ports, IPv6, and CIDR ranges. The CIDR case may expose an actual implementation bug rather than merely missing coverage.

## Turn 3

### User

```text
okay add tests for the clearest gap only. don't change the implementation
```

### Assistant

Added a focused `NO_PROXY=localhost` routing test in [tests/client/test_proxies.py:156](https://github.com/encode/httpx/blob/26d48e0634e6ee9cdc0533996db289ce4b430177/tests/client/test_proxies.py#L156). It runs for both sync and async clients via the existing parametrization.

No implementation changes were made.

I couldn’t run the test because `pytest` is not installed in the current Python environment.
