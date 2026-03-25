param(
    [string]$RuntimeDir,
    [string]$TokenFile
)

$ErrorActionPreference = "Stop"

function Require-Command {
    param([string]$Name)

    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Required command not found: $Name"
    }
}

$skillRoot = Split-Path $PSScriptRoot -Parent
if (-not $RuntimeDir) {
    $RuntimeDir = Join-Path $skillRoot ".runtime"
}
if (-not $TokenFile) {
    $TokenFile = Join-Path $skillRoot "dolphin-anty-api-token.txt"
}

$toolDir = Join-Path $RuntimeDir "tools"
$workspaceDir = Join-Path $RuntimeDir "workspace"
$ocliDir = Join-Path $workspaceDir ".ocli"
$specsDir = Join-Path $ocliDir "specs"
$localOcli = Join-Path $toolDir "node_modules\.bin\ocli.cmd"
$bundledSpec = Join-Path $skillRoot "references\dolphinanty-public-api.json"
$localCache = Join-Path $specsDir "dolphin-local.json"
$cloudCache = Join-Path $specsDir "dolphin-cloud-v1.json"
$profilesIni = Join-Path $ocliDir "profiles.ini"
$currentFile = Join-Path $ocliDir "current"

if (-not (Test-Path $bundledSpec)) {
    throw "Bundled spec not found: $bundledSpec"
}

$token = $null
if (Test-Path $TokenFile) {
    $token = (Get-Content $TokenFile -Raw).Trim()
}
if (-not $token -and $env:DOLPHIN_ANTY_TOKEN) {
    $token = $env:DOLPHIN_ANTY_TOKEN.Trim()
}
if (-not $token -and (Test-Path $profilesIni)) {
    $existingToken = Select-String -Path $profilesIni -Pattern '^api_bearer_token=(.+)$' | Select-Object -First 1
    if ($existingToken) {
        $token = $existingToken.Matches[0].Groups[1].Value.Trim()
    }
}
if (-not $token) {
    throw "Dolphin token not found. Put it into dolphin-anty-api-token.txt or set DOLPHIN_ANTY_TOKEN."
}

Require-Command "node"
Require-Command "npm"

New-Item -ItemType Directory -Force -Path $toolDir | Out-Null
New-Item -ItemType Directory -Force -Path $specsDir | Out-Null

if (-not (Test-Path $localOcli)) {
    npm install --prefix $toolDir openapi-to-cli | Out-Host
}

Copy-Item $bundledSpec $localCache -Force
Copy-Item $bundledSpec $cloudCache -Force

$safeSource = $bundledSpec.Replace("\", "/")
$profilesContent = @"
[dolphin-local]
api_base_url=http://localhost:3001
api_basic_auth=
api_bearer_token=$token
openapi_spec_source=$safeSource
openapi_spec_cache=$localCache
include_endpoints=
exclude_endpoints=

[dolphin-cloud-v1]
api_base_url=https://dolphin-anty-api.com
api_basic_auth=
api_bearer_token=$token
openapi_spec_source=$safeSource
openapi_spec_cache=$cloudCache
include_endpoints=
exclude_endpoints=
"@

Set-Content -Path $profilesIni -Value $profilesContent -Encoding ASCII
Set-Content -Path $currentFile -Value "dolphin-cloud-v1" -Encoding ASCII

[pscustomobject]@{
    runtime_dir = $RuntimeDir
    workspace_dir = $workspaceDir
    ocli_cmd = $localOcli
    profiles = @("dolphin-local", "dolphin-cloud-v1")
} | ConvertTo-Json -Depth 3
