# Patched rerun selection

See `round1.csv` for the Round 1 scores. The runner selected GPT-6 Luna Tests **2, 8, 10, and 11** for the patch.

- Test 2: It missed the difference between `params={}` and `params=None` for a URL with a query.
- Test 8: It described the wrapper but missed the live-route behavior.
- Test 10: It used a cached failure and did not run the focused test.
- Test 11: It did not rerun the test after the short follow-up.

Tests 10 and 11 share one session. Test 2 keeps its three prompts in one session. Round 2 uses three sessions for four scored tests.
