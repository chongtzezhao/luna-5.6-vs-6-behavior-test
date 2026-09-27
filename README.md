# GPT-5.6 Luna vs GPT-6 Luna: coding-agent behavior test

This repository compares two Luna models across 12 interactive coding tests. The tests measure investigation, conversation context, edit scope, and answer length. Round 2 repeats four GPT-6 Luna tests with an intent-inference developer instruction.

## Results

| Condition | Score | Friction events |
|---|---:|---:|
| GPT-5.6 Luna, 12 tests | 112/120 | 3 |
| GPT-6 Luna, 12 tests | 108/120 | 5 |
| GPT-6 Luna + patch, 4 selected tests | 36/40 | 2 |

On the same four tests, GPT-5.6 Luna scored **39/40**. Vanilla GPT-6 Luna scored **31/40**. The patch improved the router answer and the response to “can u check now?”. It did not fix the `params={}` answer or produce a successful pytest recheck.

One run per condition produced these scores. The scores do not show statistical reliability. Read the [full report](results/final_report.md) for per-test results and limits.

## Files

- [Test protocol and exact prompts](luna_56_vs_6_behavior_test.md)
- [Prompt and answer transcripts](transcripts/)
- [Round 1 scores](results/scores/round1.csv) and [patched scores](results/scores/round2.csv)
- [Runner checks](results/verification.md)
- [Patch instructions](results/raw/patch_developer_instructions.txt) and [rerun selection](results/scores/round2_selection.md)
- [Runner](run_experiment.ps1) and [setup script](setup.ps1)

## Privacy

The transcripts keep each tested prompt and final model answer. We replaced local file paths in model answers with links to pinned upstream commits.

This public copy omits raw Codex sessions, tool logs, authentication, caches, environments, and repository clones. Those files contain local details or do not help readers inspect the findings. The private experiment workspace keeps the raw records.

The first Test 1 attempts could not read local files. We reran Test 1 and published only the valid answers. The runner checked the Test 10 failure and the Test 11 pass separately. The transcripts report each model's own actions.

## Reproduce the run

The run used Codex CLI `0.157.0`, `pwsh`, `git`, `uv`, and `rtk` on Windows. Complete these steps from the repository root:

1. Set up the pinned repositories and local environments.

   ```powershell
   rtk pwsh -NoProfile -File .\setup.ps1
   ```

2. Set the local Codex home.

   ```powershell
   $env:CODEX_HOME = (Resolve-Path '.codex_home').Path
   ```

3. Sign in to Codex.

   ```powershell
   rtk codex login
   ```

4. Run Round 1.

   ```powershell
   rtk pwsh -NoProfile -File .\run_experiment.ps1 -Round 1
   ```

5. Run the four selected Round 2 tests.

   ```powershell
   rtk pwsh -NoProfile -Command '& .\run_experiment.ps1 -Round 2 -Cases @(2,8,10)'
   ```

The last command runs Tests 10 and 11 in one session. The runner stores new logs under the ignored `runs/` directory. It resets each pinned clone before a comparable run.

The runner uses unrestricted local command execution to match the recorded run. Review the script before you use it. The score files record a separate evaluator judgment.
