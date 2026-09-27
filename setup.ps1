$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
Set-Location -LiteralPath $root
$env:UV_CACHE_DIR = Join-Path $root '.cache/uv'
$env:TEMP = Join-Path $root '.cache/tmp'
$env:TMP = $env:TEMP
New-Item -ItemType Directory -Force -Path repos, envs, runs, '.cache/tmp', '.codex_home' | Out-Null

if (-not (Test-Path -LiteralPath 'repos/httpx')) {
    & rtk git clone --branch 0.28.1 --depth 1 https://github.com/encode/httpx.git repos/httpx
    if ($LASTEXITCODE -ne 0) { throw 'HTTPX clone failed.' }
}
if (-not (Test-Path -LiteralPath 'repos/fastapi')) {
    & rtk git clone --branch 0.141.1 --depth 1 https://github.com/fastapi/fastapi.git repos/fastapi
    if ($LASTEXITCODE -ne 0) { throw 'FastAPI clone failed.' }
}

if (-not (Test-Path -LiteralPath 'envs/httpx/Scripts/python.exe')) {
    & rtk uv venv envs/httpx
    if ($LASTEXITCODE -ne 0) { throw 'HTTPX environment creation failed.' }
}
& rtk uv pip install --python envs/httpx/Scripts/python.exe -e repos/httpx pytest trio trustme uvicorn
if ($LASTEXITCODE -ne 0) { throw 'HTTPX dependency installation failed.' }

if (-not (Test-Path -LiteralPath 'envs/fastapi/Scripts/python.exe')) {
    & rtk uv venv envs/fastapi
    if ($LASTEXITCODE -ne 0) { throw 'FastAPI environment creation failed.' }
}
& rtk uv pip install --python envs/fastapi/Scripts/python.exe -e repos/fastapi pytest httpx
if ($LASTEXITCODE -ne 0) { throw 'FastAPI dependency installation failed.' }

Write-Host 'Local clones and environments are ready.'
