$ErrorActionPreference = "Stop"

$skillRoot = Split-Path $PSScriptRoot -Parent
$bootstrapScript = Join-Path $PSScriptRoot "bootstrap.ps1"
$runtimeDir = Join-Path $skillRoot ".runtime"
$workspaceDir = Join-Path $runtimeDir "workspace"
$localOcli = Join-Path $runtimeDir "tools\node_modules\.bin\ocli.cmd"
$tokenFile = Join-Path $skillRoot "dolphin-anty-api-token.txt"
$profilesIni = Join-Path $workspaceDir ".ocli\profiles.ini"

function Get-DolphinToken {
    if (Test-Path $tokenFile) {
        return (Get-Content $tokenFile -Raw).Trim()
    }
    if ($env:DOLPHIN_ANTY_TOKEN) {
        return $env:DOLPHIN_ANTY_TOKEN.Trim()
    }
    if (Test-Path $profilesIni) {
        $existingToken = Select-String -Path $profilesIni -Pattern '^api_bearer_token=(.+)$' | Select-Object -First 1
        if ($existingToken) {
            return $existingToken.Matches[0].Groups[1].Value.Trim()
        }
    }
    throw "Dolphin token not found. Put it into dolphin-anty-api-token.txt or set DOLPHIN_ANTY_TOKEN."
}

if ($args.Count -lt 1) {
    Write-Error "Usage: .\scripts\run-dolphin-ocli.ps1 <command> [args...]"
    exit 1
}

$command = [string]$args[0]
$forwardArgs = @()
if ($args.Count -gt 1) {
    $forwardArgs = $args[1..($args.Count - 1)]
}

& $bootstrapScript | Out-Null

if (-not (Test-Path $localOcli)) {
    throw "ocli executable not found after bootstrap: $localOcli"
}

$profile = if ($command.StartsWith("v1.0_") -or $command -eq "login-local") { "dolphin-local" } else { "dolphin-cloud-v1" }

if ($command -eq "login-local") {
    $command = "v1.0_auth_login-with-token"
    $forwardArgs = @("--token", (Get-DolphinToken))
}

Push-Location $workspaceDir
try {
    & $localOcli use $profile | Out-Null
    & $localOcli $command @forwardArgs
    $exitCode = $LASTEXITCODE
}
finally {
    Pop-Location
}

exit $exitCode
