# GPT-5.6 Luna vs GPT-6 Luna: coding-agent behavior test

A 12-test comparison of two Luna models in short, interactive coding workflows. The tests emphasize investigation depth, conversational follow-ups, edit restraint, and concise answers. A second round reruns four selected GPT-6 Luna tests with an intent-inference developer instruction.

## Result

| Condition | Score | Friction events |
|---|---:|---:|
| GPT-5.6 Luna, 12 tests | 112/120 | 3 |
| GPT-6 Luna, 12 tests | 108/120 | 5 |
| GPT-6 Luna + patch, 4 selected tests | 36/40 | 2 |

On the same four selected tests, GPT-5.6 Luna scored **39/40** and vanilla GPT-6 Luna scored **31/40**. The patch improved GPT-6 Luna's router-architecture answer and its response to “can u check now?”, but did not fix the `params={}` edge-case answer or produce a successful in-session pytest recheck. These are one-run, rubric-based observations, not statistical estimates.

Read the [full report](results/final_report.md) for per-test scores, evidence, and limitations.

## Contents

- [Test protocol and exact prompts](luna_56_vs_6_behavior_test.md)
- [Sanitized prompt/answer transcripts](transcripts/)
- [Round 1 scores](results/scores/round1.csv) and [patched scores](results/scores/round2.csv)
- [Runner-side verification](results/verification.md)
- [Patch instructions](results/raw/patch_developer_instructions.txt) and [rerun selection](results/scores/round2_selection.md)
- [Runner](run_experiment.ps1) and [local setup script](setup.ps1)

## Privacy and provenance

The transcripts preserve the tested user prompts and model final answers. Local absolute paths in model answers were converted to links to the pinned upstream repository commits. Raw Codex session records, tool-event logs, authentication, caches, virtual environments, and repository clones are excluded because they contain local environment details or are unnecessary to inspect the published findings. The full raw records remain in the private experiment workspace.

The original Test 1 runs were invalid because local shell reads were blocked; both were rerun and only the valid runs are represented here. The runner independently confirmed the injected Test 10 failure and the restored Test 11 pass. The public transcripts show what each model itself reported and do not silently substitute the runner's verification for a model's actions.

## Reproduce locally

The historical run used Codex CLI `0.157.0`, `pwsh`, `git`, `uv`, and `rtk` on Windows. From this repository root:

```powershell
rtk pwsh -NoProfile -File .\setup.ps1
$env:CODEX_HOME = (Resolve-Path '.codex_home').Path
rtk codex login
rtk pwsh -NoProfile -File .\run_experiment.ps1 -Round 1
rtk pwsh -NoProfile -Command '& .\run_experiment.ps1 -Round 2 -Cases @(2,8,10)'
```

The last command covers Tests 10 and 11 together. The runner stores new raw results under ignored `runs/` and resets the pinned clones before comparable runs. It uses unrestricted local command execution to match this experiment's session configuration; review the runner and use an isolated workspace when reproducing it. Scoring is a separate evaluator judgment documented in the CSV files.
