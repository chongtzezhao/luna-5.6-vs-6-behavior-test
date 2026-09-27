# Patched rerun selection

Round 1 scoring is in `round1.csv`. The four GPT-6 Luna tests selected for the intent-inference patch are **2, 8, 10, and 11**.

- Test 2: missed the practical difference between `params={}` and `params=None` for a URL that already has a query.
- Test 8: described the wrapper but missed the consequential live-route behavior.
- Test 10: diagnosed from a cached failure without executing the focused test.
- Test 11: did not rerun the relevant test after the terse follow-up.

Tests 10 and 11 must run as one sequence. Test 2's three prompts must also stay in one session. The patched round will therefore run three fresh sessions covering four scored tests.
