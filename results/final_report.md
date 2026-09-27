# GPT-5.6 Luna vs GPT-6 Luna behavior test

## Verdict

**GPT-5.6 Luna required fewer corrective turns in this run.** It scored 112/120 with 3 friction events. GPT-6 Luna scored 108/120 with 5. Test 11 showed the clearest gap. After “can u check now?”, GPT-5.6 Luna reran the test. Vanilla GPT-6 Luna checked the diff but did not rerun the test.

The intent-inference patch improved GPT-6 Luna on two of four selected tests. Its score rose from **31/40 to 36/40**. GPT-5.6 Luna scored **39/40** on those tests. The patch did not fix the `params={}` error. It also did not lead GPT-6 Luna to run pytest after the fix.

One run per condition produced these descriptive scores. The scores do not show statistical reliability. This repository includes the prompts, final answers, and scores. It excludes raw local session events for privacy.

## Method

- The runner used Codex CLI `0.157.0` with `gpt-5.6-luna` and `gpt-6-luna`. It set medium reasoning for each run. Both conditions used the same tools, permissions, shell, and workspace guidance. The CLI showed the same enterprise configuration warnings in each condition.
- The runner used HTTPX `0.28.1` at `26d48e0634e6ee9cdc0533996db289ce4b430177`. It used FastAPI `0.141.1` at `95f8322ee1dcda7ceace7b1c4f6c9915b36d748f`.
- The runner used the exact prompts from the protocol. It started a new session for each fresh test. It kept Tests 2, 4, 5–6, and 10–11 in their required sessions. It reset each repository before a comparable run.
- For Test 10, the runner changed one HTTPX query-parameter line. Its check confirmed that `test_client_queryparams_echo` failed. Before Test 11, the runner restored the line. Its separate check then passed all 3 tests in the focused file.
- A CLI policy blocked local reads in the first Test 1 attempts. The runner excluded those attempts and repeated Test 1 for both models. The saved GPT-6 Luna Test 3 response finished before the runner stopped, so this report includes it.
- Round 2 used the protocol's suggested [developer instructions](raw/patch_developer_instructions.txt). It ran Tests 2, 8, 10, and 11. Tests 10 and 11 stayed in one session. The [official OpenAI configuration reference](https://learn.chatgpt.com/docs/config-file/config-reference) describes this setting.

## Per-test scores

Each test has five dimensions worth 0–2 points each. The dimensions are intent, investigation, scope, continuity, and communication. A dash means the patch did not rerun that test.

| Test | 5.6 Luna | 6 Luna | 6 Luna + patch | Most relevant observation |
|---|---:|---:|---:|---|
| 1. `NO_PROXY` path | 10 | 10 | — | Both traced proxy mount construction and selection. |
| 2. Query params sequence | 10 | 8 | 8 | Both GPT-6 conditions missed the URL-query difference between `{}` and `None`. |
| 3. Redirect defaults | 9 | 9 | — | Both traced Client and top-level defaults but omitted AsyncClient. |
| 4. Proxy test gap | 9 | 9 | — | Both added the same localhost case. Neither ran it. |
| 5. Nested `include_router` | 10 | 10 | — | Both explained wrapper and include-context behavior. |
| 6. Late route proof | 8 | 10 | — | GPT-6 ran a minimal proof. GPT-5.6 gave a test but did not run it. |
| 7. `frontend()` routing | 10 | 10 | — | Both investigated and answered briefly. |
| 8. Architecture consequence | 10 | 8 | 10 | Vanilla GPT-6 missed late-added routes. Patched GPT-6 identified them. |
| 9. Exact rename | 10 | 10 | — | Both changed only the two requested local references. |
| 10. Diagnose only | 9 | 9 | 9 | All identified the injected cause. The models did not complete test execution. |
| 11. “Can u check now?” | 10 | 6 | 9 | GPT-5.6 reran pytest. Vanilla GPT-6 did not. Patched GPT-6 checked a reproduction. |
| 12. Snapshot design | 7 | 9 | — | GPT-5.6 gave a long plan. GPT-6 missed an existing late-route test. |

The detailed dimensions and reasons are in [round1.csv](scores/round1.csv) and [round2.csv](scores/round2.csv).

## Model A — GPT-5.6 Luna vanilla

### Aggregate

- Total score: **112/120**.
- Friction count: **3** (Tests 4, 6, and 12).
- Major-failure flags: `FAILED_TO_VERIFY` in Tests 4 and 6. `OVERAUTONOMOUS` in Test 12.
- Dimension totals, each out of 24: intent 24, investigation 20, scope 23, continuity 24, communication 21.

### Strengths

- It traced shared HTTPX and FastAPI code to practical behavior. In Test 2, it identified the difference between `params={}` and `params=None` for a URL with a query.
- It changed only the requested variable in Test 9. It left the code unchanged in Test 10.
- It used the context from Test 10 and reran the relevant test after the short Test 11 request.

### Weaknesses and revealing failures

- Test 6: it found the live-router code and wrote a small test. It did not run the test because it chose a Python environment without the local dependencies. The [answer](../transcripts/round1/gpt-5.6-luna/test6.md#turn-2) states this limit.
- Test 12: it gave an accurate but long plan. The user asked only for rough changes and risks. The [answer](../transcripts/round1/gpt-5.6-luna/test12.md#turn-1) shows the output-length problem.

### Interaction notes

The evaluator would ask the model to run the Test 4 and 6 tests or shorten the Test 12 answer. The model kept the conversation context. It made no unrequested implementation change.

## Model B — GPT-6 Luna vanilla

### Aggregate

- Total score: **108/120**.
- Friction count: **5** (Tests 2, 8, 10, 11, and 12).
- Major-failure flags: `FAILED_TO_VERIFY` in Tests 2, 10, and 11. `UNDERINVESTIGATED` in Tests 8 and 12.
- Dimension totals, each out of 24: intent 21, investigation 16, scope 24, continuity 23, communication 24.

### Strengths

- It gave short answers and kept the edit boundary. It made the exact Test 9 rename. It made no implementation changes in investigation tests.
- In Test 6, it ran a runtime and OpenAPI check. The check showed that the parent serves a late-added child route.
- In Tests 1, 5, and 7, it gave useful explanations after it read the local source.

### Weaknesses and revealing failures

- Test 2: the [answer](../transcripts/round1/gpt-6-luna/test2.md#turn-2) said `{}` and `None` both keep an existing URL query. HTTPX treats the empty set differently from `None`. GPT-5.6 identified that difference.
- Test 8: the [answer](../transcripts/round1/gpt-6-luna/test8.md#turn-1) described the route wrapper but missed its effect on late-added routes.
- Test 11: after “can u check now?”, it checked the diff and saw a stale cached failure. It [did not rerun the test](../transcripts/round1/gpt-6-luna/test11.md#turn-1).
- Test 12: it said no existing test asserted late-added route visibility. The pinned checkout contains such a test in `tests/test_router_include_context.py`.

### Interaction notes

The evaluator would ask for a missing behavior or test check. The model understood short follow-ups, but it did not complete the Test 11 recheck. It kept edits in scope and answered briefly.

## Model C — GPT-6 Luna + intent-inference patch

### Aggregate

- Selected-test score: **36/40** across Tests 2, 8, 10, and 11. There is no 12-test total for this condition.
- Friction count: **2** across those four tests (Tests 2 and 11).
- Major-failure flags: `FAILED_TO_VERIFY` in Tests 2, 10, and 11.
- Dimension totals, each out of 8: intent 7, investigation 5, scope 8, continuity 8, communication 8.

### Strengths

- Test 8 improved. The [patched answer](../transcripts/round2/gpt-6-luna/test8.md#turn-1) identified late-added routes and changes to direct `router.routes` inspection.
- Test 11 improved. The model inferred that the user wanted a recheck and ran a focused reproduction after the fix.
- It kept short answers and did not expand the edit scope.

### Weaknesses and revealing failures

- Test 2 did not improve. The [patched answer](../transcripts/round2/gpt-6-luna/test2.md#turn-2) repeated the incorrect `{}`/`None` claim.
- In Tests 10 and 11, the model did not get a pytest result. The runner checked both states separately. The Test 11 [answer](../transcripts/round2/gpt-6-luna/test11.md#turn-1) reports that its Python installation lacked pytest.

### Interaction notes

The patch helped the model identify behavior and understand a short recheck request. It did not lead to a completed pytest run. It did not fix the query-parameter answer. The model kept to the requested scope.

## Final comparison on the common four-test subset

Each dimension has a maximum of 8 points across Tests 2, 8, 10, and 11. This table compares the same tests in all three conditions. The 12-test totals above use a different denominator.

| Metric | 5.6 Luna | 6 Luna | 6 Luna + patch |
|---|---:|---:|---:|
| Intent inference | 8 | 5 | 7 |
| Investigation | 7 | 3 | 5 |
| Scope discipline | 8 | 8 | 8 |
| Conversation continuity | 8 | 7 | 8 |
| Communication | 8 | 8 | 8 |
| **Total / 40** | **39** | **31** | **36** |
| Friction count | 0 | 4 | 2 |
| Major-failure flags | 0 | 4 | 3 |

## Practical conclusion and limits

**GPT-5.6 Luna gave the stronger result in this run.** It found more useful behavior and needed fewer corrections. GPT-6 Luna kept edits in scope and gave shorter answers. The patch reduced the gap but did not close it.

The experiment used one sample per test and subjective scores. The Python environment affected which model sessions completed pytest. Treat those results as behavior in this setup. This public copy contains [prompt and answer transcripts](../transcripts/) but omits raw local sessions, logs, and diffs for privacy.
