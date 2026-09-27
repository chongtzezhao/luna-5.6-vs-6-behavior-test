param(
    [int[]]$Cases = @(1, 2, 3, 4, 5, 7, 8, 9, 10, 12),
    [ValidateSet(1, 2)][int]$Round = 1
)

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$env:CODEX_HOME = Join-Path $root '.codex_home'
$env:UV_CACHE_DIR = Join-Path $root '.cache/uv'
$env:TEMP = Join-Path $root '.cache/tmp'
$env:TMP = $env:TEMP
New-Item -ItemType Directory -Force -Path $env:TEMP | Out-Null
$protocol = [IO.File]::ReadAllText((Join-Path $root 'luna_56_vs_6_behavior_test.md'))
$patchConfig = $null
if ($Round -eq 2) {
    $patchText = [IO.File]::ReadAllText((Join-Path $root 'results/raw/patch_developer_instructions.txt')).Trim()
    $patchConfig = 'developer_instructions=' + (ConvertTo-Json -InputObject $patchText -Compress)
}
$sections = @{}
$matches = [regex]::Matches($protocol, '(?ms)^# Test (\d+) .+?(?=^# Test \d+ |^# Scoring Rubric)')
foreach ($match in $matches) {
    $number = [int]$match.Groups[1].Value
    $prompts = @([regex]::Matches($match.Value, '(?ms)^```text\r?\n(.*?)\r?\n```') | ForEach-Object { $_.Groups[1].Value })
    $sections[$number] = $prompts
}

function Reset-Repo([string]$repo) {
    Push-Location $repo
    try {
        & rtk git reset --hard HEAD | Out-Null
        & rtk git clean -fd | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "git clean failed in $repo" }
    } finally { Pop-Location }
}

function Save-State([string]$repo, [string]$dir, [string]$label) {
    Push-Location $repo
    try {
        & rtk git status --short 2>&1 | Set-Content -Encoding utf8 (Join-Path $dir "$label.status.txt")
        & rtk git diff --no-ext-diff 2>&1 | Set-Content -Encoding utf8 (Join-Path $dir "$label.diff.txt")
    } finally { Pop-Location }
}

function Invoke-Prompt([string]$repo, [string]$model, [int]$number, [int]$step, [string]$prompt, [string]$thread) {
    $dir = Join-Path $root "runs/round$Round/$model/test$number"
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    [IO.File]::WriteAllText((Join-Path $dir "prompt$step.txt"), $prompt)
    $raw = Join-Path $dir "step$step.jsonl"
    Write-Host "RUN model=$model test=$number step=$step"
    Push-Location $repo
    try {
        if ($thread) {
            if ($patchConfig) {
                & rtk codex exec resume -m $model -c 'model_reasoning_effort="medium"' -c $patchConfig --dangerously-bypass-approvals-and-sandbox --json $thread $prompt 2>&1 | Set-Content -Encoding utf8 $raw
            } else {
                & rtk codex exec resume -m $model -c 'model_reasoning_effort="medium"' --dangerously-bypass-approvals-and-sandbox --json $thread $prompt 2>&1 | Set-Content -Encoding utf8 $raw
            }
        } else {
            if ($patchConfig) {
                & rtk codex exec -m $model -c 'model_reasoning_effort="medium"' -c $patchConfig --dangerously-bypass-approvals-and-sandbox --skip-git-repo-check --json $prompt 2>&1 | Set-Content -Encoding utf8 $raw
            } else {
                & rtk codex exec -m $model -c 'model_reasoning_effort="medium"' --dangerously-bypass-approvals-and-sandbox --skip-git-repo-check --json $prompt 2>&1 | Set-Content -Encoding utf8 $raw
            }
        }
        $exitCode = $LASTEXITCODE
    } finally { Pop-Location }
    $events = @()
    foreach ($line in [IO.File]::ReadAllLines($raw)) {
        try { $events += $line | ConvertFrom-Json -Depth 100 } catch { }
    }
    $started = $events | Where-Object type -eq 'thread.started' | Select-Object -First 1
    if ($started) { $thread = $started.thread_id }
    $messages = @($events | Where-Object { $_.type -eq 'item.completed' -and $_.item.type -eq 'agent_message' } | ForEach-Object { $_.item.text })
    if ($messages.Count -gt 0) { [IO.File]::WriteAllText((Join-Path $dir "step$step.answer.txt"), $messages[-1]) }
    [IO.File]::WriteAllText((Join-Path $dir "step$step.exit.txt"), "$exitCode")
    Save-State $repo $dir "step$step"
    if ($exitCode -ne 0) { Write-Host "ERROR model=$model test=$number step=$step exit=$exitCode" }
    Write-Host "DONE model=$model test=$number step=$step exit=$exitCode thread=$thread"
    return $thread
}

foreach ($case in $Cases) {
    if ($case -in @(6, 11)) { throw 'Run Test 6 with 5 and Test 11 with 10.' }
    $repoName = if ($case -in @(5, 7, 8, 12)) { 'fastapi' } else { 'httpx' }
    $repo = Join-Path $root "repos/$repoName"
    $models = if ($Round -eq 2) { @('gpt-6-luna') } elseif ($case % 2 -eq 0) { @('gpt-6-luna', 'gpt-5.6-luna') } else { @('gpt-5.6-luna', 'gpt-6-luna') }
    foreach ($model in $models) {
        Reset-Repo $repo
        $oldPath = $env:PATH
        $env:PATH = (Join-Path $root "envs/$repoName/Scripts") + [IO.Path]::PathSeparator + $oldPath
        try {
            if ($case -eq 10) {
                $source = Join-Path $repo 'httpx/_client.py'
                $content = [IO.File]::ReadAllText($source)
                $needle = 'return merged_queryparams.merge(params)'
                if (-not $content.Contains($needle)) { throw 'Cannot inject Test 10 failure.' }
                [IO.File]::WriteAllText($source, $content.Replace($needle, 'return QueryParams(params)'))
                $dir = Join-Path $root "runs/round$Round/$model/test10"
                New-Item -ItemType Directory -Force -Path $dir | Out-Null
                Push-Location $repo
                try { & rtk (Join-Path $root 'envs/httpx/Scripts/python.exe') -m pytest tests/client/test_queryparams.py -q 2>&1 | Set-Content -Encoding utf8 (Join-Path $dir 'injected_failure.txt') } finally { Pop-Location }
            }
            $thread = $null
            $step = 0
            foreach ($prompt in $sections[$case]) {
                $step++
                $thread = Invoke-Prompt $repo $model $case $step $prompt $thread
            }
            if ($case -eq 5) {
                $step = 0
                foreach ($prompt in $sections[6]) {
                    $step++
                    $thread = Invoke-Prompt $repo $model 6 $step $prompt $thread
                }
            }
            if ($case -eq 10) {
                $content = [IO.File]::ReadAllText($source)
                [IO.File]::WriteAllText($source, $content.Replace('return QueryParams(params)', $needle))
                $thread = Invoke-Prompt $repo $model 11 1 $sections[11][0] $thread
                $dir = Join-Path $root "runs/round$Round/$model/test11"
                Push-Location $repo
                try { & rtk (Join-Path $root 'envs/httpx/Scripts/python.exe') -m pytest tests/client/test_queryparams.py -q 2>&1 | Set-Content -Encoding utf8 (Join-Path $dir 'verified_test.txt') } finally { Pop-Location }
            }
        } finally { $env:PATH = $oldPath }
    }
}
