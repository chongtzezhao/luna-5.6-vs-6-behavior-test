# Runner-side verification

These checks were performed by the test runner or taken from its saved diffs. They are separate from actions the model reported in its transcript.

## Test 4: proxy coverage edit

Both vanilla models added the same six-line `NO_PROXY=localhost` case in `tests/client/test_proxies.py`. The saved diff showed one test file changed and no implementation files changed. Neither model completed a test run for this addition.

## Test 9: exact rename

Both vanilla models changed only these two references in `httpx/_client.py`:

```diff
-            merged_queryparams = QueryParams(self.params)
-            return merged_queryparams.merge(params)
+            merged_params = QueryParams(self.params)
+            return merged_params.merge(params)
```

No other tracked changes appeared in the saved diffs. Neither model committed.

## Tests 10 and 11: injected failure and restoration

Before each Test 10 run, the runner changed `return merged_queryparams.merge(params)` to `return QueryParams(params)` and ran the focused query-parameter test file. The observed outcome was **1 failed, 2 passed**, with `test_client_queryparams_echo` losing `first=str` from the URL.

Before each Test 11 prompt, the runner restored that line without telling the model. The runner's independent check then reported **3 passed**. The transcripts show whether each model chose to run its own check.
