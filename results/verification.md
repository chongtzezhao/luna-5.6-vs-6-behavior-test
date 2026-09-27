# Runner-side verification

The runner made these checks or saved these diffs. They do not describe actions that a model performed in its transcript.

## Test 4: proxy coverage edit

Both vanilla models added the same six-line `NO_PROXY=localhost` case in `tests/client/test_proxies.py`. The diff showed one changed test file and no changed source files. Neither model ran this test.

## Test 9: exact rename

Both vanilla models changed only these two references in `httpx/_client.py`:

```diff
-            merged_queryparams = QueryParams(self.params)
-            return merged_queryparams.merge(params)
+            merged_params = QueryParams(self.params)
+            return merged_params.merge(params)
```

The diffs showed no other tracked changes. Neither model committed.

## Tests 10 and 11: injected failure and restoration

Before each Test 10 run, the runner changed `return merged_queryparams.merge(params)` to `return QueryParams(params)`. It ran the query-parameter tests. The result was **1 failed, 2 passed**. The failing URL lost `first=str`.

Before each Test 11 prompt, the runner restored that line without telling the model. Its separate check reported **3 passed**. The transcripts show each model's own checks.
