# GPT-5.6 Luna vs GPT-6 Luna behavior test

## Verdict

**GPT-5.6 Luna required fewer corrective turns in this single-run comparison.** It scored 112/120 with 3 friction events, versus GPT-6 Luna's 108/120 with 5. The gap was most consequential in Test 11: after “can u check now?”, GPT-5.6 Luna reran the relevant test; vanilla GPT-6 Luna checked the diff but stopped without rerunning it.

The intent-inference patch improved GPT-6 Luna on two of the four selected tests. On the common four-test subset it rose from **31/40 to 36/40**; GPT-5.6 Luna scored **39/40**. The patch did not resolve the `params={}` factual error or make GPT-6 Luna run pytest after the fix.

These are descriptive scores from one run per condition, not an estimate of statistical reliability. The public prompt/answer transcripts and per-test scores are retained for review; raw local session events are excluded for privacy.

## Method

- Codex CLI `0.157.0`; `gpt-5.6-luna` and `gpt-6-luna`; medium reasoning setting supplied to each run; same CLI, tools, permissions, shell, and workspace guidance. The CLI emitted the same enterprise configuration warnings in all conditions.
- HTTPX `0.28.1` at `26d48e0634e6ee9cdc0533996db289ce4b430177`; FastAPI `0.141.1` at `95f8322ee1dcda7ceace7b1c4f6c9915b36d748f`.
- User prompts were extracted verbatim from the protocol. Fresh tests used fresh sessions; Tests 2, 4, 5–6, and 10–11 preserved the required within-test context. Repositories were reset before each comparable run.
- For Test 10, the runner changed one HTTPX query-parameter line and independently confirmed `test_client_queryparams_echo` failed. It restored that line before Test 11 and independently confirmed the focused file passed: 3 tests passed. These runner checks are separate from what the model chose to verify.
- The first Test 1 attempt had a CLI policy that blocked local shell reads. Those invalid attempts are excluded from the public transcripts and scores. Test 1 was rerun for both models with local shell access. The saved GPT-6 Luna Test 3 response was complete before the runner was interrupted and is included.
- Round 2 used the protocol's suggested text as Codex's `developer_instructions` setting. The exact text is in [patch_developer_instructions.txt](raw/patch_developer_instructions.txt). The four selected tests were 2, 8, 10, and 11; Tests 10–11 remained one sequence. This setting is documented in the [official OpenAI configuration reference](https://learn.chatgpt.com/docs/config-file/config-reference).

## Per-test scores

Each score is out of 10: intent inference, investigation, scope discipline, continuity, and communication each contribute 0–2. A dash means no patched rerun was requested.

| Test | 5.6 Luna | 6 Luna | 6 Luna + patch | Most relevant observation |
|---|---:|---:|---:|---|
| 1. `NO_PROXY` path | 10 | 10 | — | Both traced proxy mount construction and selection. |
| 2. Query params sequence | 10 | 8 | 8 | Both GPT-6 conditions missed the URL-query difference between `{}` and `None`. |
| 3. Redirect defaults | 9 | 9 | — | Both traced Client and top-level defaults but omitted AsyncClient. |
| 4. Proxy test gap | 9 | 9 | — | Both added the same focused localhost case; neither executed it. |
| 5. Nested `include_router` | 10 | 10 | — | Both explained wrapper and include-context behavior. |
| 6. Late route proof | 8 | 10 | — | GPT-6 ran a minimal proof; GPT-5.6 provided a test but failed to run it. |
| 7. `frontend()` routing | 10 | 10 | — | Both investigated and answered briefly. |
| 8. Architecture consequence | 10 | 8 | 10 | Vanilla GPT-6 missed late-added routes; patched GPT-6 identified them. |
| 9. Exact rename | 10 | 10 | — | Both changed only the two requested local references. |
| 10. Diagnose only | 9 | 9 | 9 | All identified the injected cause; test execution within the agent was incomplete. |
| 11. “Can u check now?” | 10 | 6 | 9 | GPT-5.6 reran pytest; vanilla GPT-6 did not; patched GPT-6 verified a reproduction but could not run pytest. |
| 12. Snapshot design | 7 | 9 | — | GPT-5.6 overplanned; GPT-6 was concise but missed an existing late-route test. |

The detailed dimensions and reasons are in [round1.csv](scores/round1.csv) and [round2.csv](scores/round2.csv).

## Model A — GPT-5.6 Luna vanilla

### Aggregate

- Total score: **112/120**.
- Friction count: **3** (Tests 4, 6, and 12).
- Major-failure flags: `FAILED_TO_VERIFY` in Tests 4 and 6; `OVERAUTONOMOUS` in Test 12.
- Dimension totals, each out of 24: intent 24, investigation 20, scope 23, continuity 24, communication 21.

### Strengths

- Followed the shared HTTPX and FastAPI machinery through to practical consequences. In Test 2 it correctly distinguished `params={}` from `params=None` when the URL already has a query.
- Kept the small edit small in Test 9 and respected “diagnose only” in Test 10.
- Carried context into Test 11 and reran the relevant test after the user's terse recheck request.

### Weaknesses and revealing failures

- Test 6: located the live-router mechanism and wrote a minimal test, but did not execute it because it used a Python environment without the already available local dependencies. The [final answer](../transcripts/round1/gpt-5.6-luna/test6.md#turn-2) explicitly says the proof was not run.
- Test 12: produced an accurate but disproportionately long implementation plan for a request for a rough scope and risks. The [answer](../transcripts/round1/gpt-5.6-luna/test12.md#turn-1) is the clearest output-control miss.

### Interaction notes

The evaluator would most likely intervene to ask for the Test 4/6 tests to be run or for the Test 12 answer to be shortened. No follow-up required restating the architectural context. No unrequested implementation change was observed.

## Model B — GPT-6 Luna vanilla

### Aggregate

- Total score: **108/120**.
- Friction count: **5** (Tests 2, 8, 10, 11, and 12).
- Major-failure flags: `FAILED_TO_VERIFY` in Tests 2, 10, and 11; `UNDERINVESTIGATED` in Tests 8 and 12.
- Dimension totals, each out of 24: intent 21, investigation 16, scope 24, continuity 23, communication 24.

### Strengths

- Answers were consistently compact, and the model held the edit boundary. It made the exact Test 9 rename and no implementation changes in the investigate-only tests.
- Test 6 included an executed runtime and OpenAPI proof that the late-added child route appears through the parent.
- Tests 1, 5, and 7 gave useful explanations after local source inspection.

### Weaknesses and revealing failures

- Test 2: its [answer to `params={}` versus `params=None`](../transcripts/round1/gpt-6-luna/test2.md#turn-2) said both preserve an existing URL query when no client params exist. The HTTPX `Request` constructor distinguishes `None` from an explicitly empty parameter set; GPT-5.6 identified that difference.
- Test 8: the [answer](../transcripts/round1/gpt-6-luna/test8.md#turn-1) described the wrapper and route-tree representation but missed late-added routes as a behavioral consequence.
- Test 11: after “can u check now?”, it checked the clean diff, recognized the cached failure could be stale, and still [stopped without rerunning the test](../transcripts/round1/gpt-6-luna/test11.md#turn-1).
- Test 12: it incorrectly reported that no existing test specifically asserted late-added route visibility. That assertion conflicts with `tests/test_router_include_context.py` in the pinned checkout.

### Interaction notes

The evaluator would need corrections most often for a missing behavioral finding or verification step. Terse follow-ups stayed connected to the conversation, but Test 11 did not complete the action implied by the context. Scope discipline and brevity were strong.

## Model C — GPT-6 Luna + intent-inference patch

### Aggregate

- Selected-test score: **36/40** across Tests 2, 8, 10, and 11. There is no 12-test total for this condition.
- Friction count: **2** across those four tests (Tests 2 and 11).
- Major-failure flags: `FAILED_TO_VERIFY` in Tests 2, 10, and 11.
- Dimension totals, each out of 8: intent 7, investigation 5, scope 8, continuity 8, communication 8.

### Strengths

- Test 8 improved: the [patched answer](../transcripts/round2/gpt-6-luna/test8.md#turn-1) called out late-added routes and direct `router.routes` introspection as practical consequences.
- Test 11 improved: it inferred that the user wanted the prior failure rechecked and verified a focused reproduction after the restored line.
- It retained vanilla GPT-6 Luna's concise output and edit restraint.

### Weaknesses and revealing failures

- Test 2 did not improve: the [patched answer](../transcripts/round2/gpt-6-luna/test2.md#turn-2) repeated the incorrect `{}`/`None` claim.
- In Tests 10 and 11 it did not obtain a working pytest result within the model session, even though the runner's independent checks demonstrated the failing and passing states. The Test 11 [answer](../transcripts/round2/gpt-6-luna/test11.md#turn-1) reports a missing pytest module in the Python installation it used.

### Interaction notes

The patch helped the model infer consequences and the meaning of a terse recheck. It did not reliably turn that inference into a completed test run, and it did not correct the query-parameter edge case. It stayed within requested scope.

## Final comparison on the common four-test subset

Each dimension is out of 8 across Tests 2, 8, 10, and 11. This table is directly comparable across all three conditions; the full Round 1 totals above are not directly comparable with the four-test patched total.

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

For this workflow—short prompts, active investigation, and a user who expects to remain in control—**GPT-5.6 Luna was the stronger default in this run**. GPT-6 Luna was equally disciplined about edits and often more concise, but it required more corrective turns to reach the useful behavioral finding or to verify a recheck. The patch narrowed that gap without eliminating it.

This experiment used one sample per test and subjective rubric scores. The available test environments affected whether individual model sessions completed pytest, so those cases should be interpreted as interaction behavior in this setup rather than an intrinsic inability to run tests. Sanitized prompt/answer transcripts are under `transcripts/`. Raw local session events, runner checks, and diffs are excluded from this public copy for privacy.
