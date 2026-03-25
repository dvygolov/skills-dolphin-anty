[CmdletBinding()]
param(
    [string]$Token,
    [string]$TokenFile = (Join-Path $PSScriptRoot "..\dolphin-anty-api-token.txt"),
    [string]$SessionStorageDir = (Join-Path $env:APPDATA "dolphin_anty\Session Storage"),
    [string]$LocalBase = "http://127.0.0.1:3001/v1.0",
    [string]$OutputFile = (Join-Path $PSScriptRoot "..\.runtime\local-session-token.txt"),
    [switch]$SkipValidation
)

$ErrorActionPreference = "Stop"
$script:ResolvedToken = $null

function ConvertTo-JsonSafe {
    param([Parameter(Mandatory = $true)]$Value)
    if ($Value -is [string]) {
        return $Value
    }
    return ($Value | ConvertTo-Json -Depth 20)
}

function Parse-TokenFromText {
    param([Parameter(Mandatory = $true)][string]$Text)

    $trimmed = $Text.Trim()
    if ([string]::IsNullOrWhiteSpace($trimmed)) {
        throw "Token text is empty."
    }

    if ($trimmed.StartsWith("{")) {
        try {
            $json = $trimmed | ConvertFrom-Json -ErrorAction Stop
            foreach ($key in @("token", "api_token", "apiKey", "key")) {
                if ($json.PSObject.Properties.Name -contains $key) {
                    $candidate = [string]$json.$key
                    if (-not [string]::IsNullOrWhiteSpace($candidate)) {
                        return $candidate.Trim()
                    }
                }
            }
        } catch {
        }
    }

    foreach ($line in ($Text -split "`r?`n")) {
        $candidate = $line.Trim()
        if ([string]::IsNullOrWhiteSpace($candidate)) {
            continue
        }
        if ($candidate.StartsWith("#")) {
            continue
        }

        if ($candidate -match "^\s*(token|api_token|apiKey|key)\s*[:=]\s*(.+)$") {
            return $Matches[2].Trim().Trim("'").Trim('"')
        }

        return $candidate.Trim().Trim("'").Trim('"')
    }

    throw "Failed to parse token from text."
}

function Resolve-Token {
    if ($script:ResolvedToken) {
        return $script:ResolvedToken
    }

    if (-not [string]::IsNullOrWhiteSpace($Token)) {
        $script:ResolvedToken = $Token.Trim()
        return $script:ResolvedToken
    }

    if (-not [string]::IsNullOrWhiteSpace($env:DOLPHIN_ANTY_TOKEN)) {
        $script:ResolvedToken = $env:DOLPHIN_ANTY_TOKEN.Trim()
        return $script:ResolvedToken
    }

    if (-not (Test-Path -LiteralPath $TokenFile)) {
        throw "Token file not found: $TokenFile"
    }

    $raw = Get-Content -LiteralPath $TokenFile -Raw
    $script:ResolvedToken = Parse-TokenFromText -Text $raw
    return $script:ResolvedToken
}

function Mask-Token {
    param([string]$TokenValue)

    if ([string]::IsNullOrWhiteSpace($TokenValue)) {
        return $null
    }

    if ($TokenValue.Length -le 8) {
        return ("*" * $TokenValue.Length)
    }

    return "{0}***{1}" -f $TokenValue.Substring(0, 4), $TokenValue.Substring($TokenValue.Length - 4)
}

function Invoke-JsonRequest {
    param(
        [Parameter(Mandatory = $true)][string]$Method,
        [Parameter(Mandatory = $true)][string]$Uri,
        [hashtable]$Headers,
        [object]$Body
    )

    $params = @{
        Method      = $Method
        Uri         = $Uri
        ErrorAction = "Stop"
    }

    if ($Headers) {
        $params.Headers = $Headers
    }

    if ($PSBoundParameters.ContainsKey("Body") -and $null -ne $Body) {
        if ($Body -is [string]) {
            $params.Body = $Body
        } else {
            $params.Body = ($Body | ConvertTo-Json -Depth 20)
        }
        $params.ContentType = "application/json"
    }

    try {
        $resp = Invoke-RestMethod @params
        return @{
            ok     = $true
            status = 200
            body   = $resp
        }
    } catch {
        $statusCode = $null
        try {
            if ($_.Exception.Response -and $_.Exception.Response.StatusCode) {
                $statusCode = [int]$_.Exception.Response.StatusCode
            }
        } catch {
        }

        $details = $null
        if ($_.ErrorDetails -and $_.ErrorDetails.Message) {
            $details = $_.ErrorDetails.Message
        } else {
            $details = $_.Exception.Message
        }

        return @{
            ok      = $false
            status  = $statusCode
            message = [string]$details
        }
    }
}

function Ensure-ParentDirectory {
    param([Parameter(Mandatory = $true)][string]$FilePath)

    $parent = Split-Path -Parent $FilePath
    if ([string]::IsNullOrWhiteSpace($parent)) {
        return
    }

    if (-not (Test-Path -LiteralPath $parent)) {
        $null = New-Item -ItemType Directory -Path $parent -Force
    }
}

function Get-SessionTokenCandidates {
    if (-not (Test-Path -LiteralPath $SessionStorageDir)) {
        throw "Session Storage directory not found: $SessionStorageDir"
    }

    $pattern = "map-[0-9][0-9][0-9]-sessionToken|map-[0-9][0-9][0-9]-intercom-test"
    $all = @()

    $files = Get-ChildItem -LiteralPath $SessionStorageDir -File |
        Where-Object { $_.Extension -in @(".log", ".ldb") } |
        Sort-Object @{ Expression = "LastWriteTime"; Descending = $true }, @{ Expression = "Name"; Descending = $true }

    foreach ($file in $files) {
        $raw = & rg -a --no-filename $pattern -- $file.FullName 2>$null
        if ($LASTEXITCODE -gt 1) {
            continue
        }

        $text = ($raw | Out-String)
        if ([string]::IsNullOrWhiteSpace($text)) {
            continue
        }

        $matches = [regex]::Matches($text, "map-(\d+)-sessionToken(?<token>.*?)map-\1-intercom-test", "Singleline")
        foreach ($match in $matches) {
            $tokenValue = ($match.Groups["token"].Value -replace "`0", "")
            $tokenValue = ($tokenValue -replace "[^A-Za-z0-9\-_]", "")
            if ($tokenValue.Length -lt 100) {
                continue
            }

            $all += [pscustomobject]@{
                map_id = [int]$match.Groups[1].Value
                token  = $tokenValue
                file   = $file.FullName
            }
        }
    }

    if (-not $all.Count) {
        throw "No LocalSessionToken candidates found in Session Storage."
    }

    $seen = @{}
    $unique = @()
    foreach ($item in ($all | Sort-Object map_id -Descending)) {
        if ($seen.ContainsKey($item.token)) {
            continue
        }
        $seen[$item.token] = $true
        $unique += $item
    }

    return $unique
}

function Ensure-LocalAuth {
    $tokenValue = Resolve-Token
    $uri = "{0}/auth/login-with-token" -f $LocalBase.TrimEnd("/")
    $resp = Invoke-JsonRequest -Method "POST" -Uri $uri -Body @{ token = $tokenValue }
    if (-not $resp.ok) {
        throw "Local auth failed: $($resp.message)"
    }
}

function Test-LocalSessionTokenCandidate {
    param([Parameter(Mandatory = $true)][string]$Candidate)

    $uri = "{0}/check/proxy" -f $LocalBase.TrimEnd("/")
    $probe = Invoke-JsonRequest -Method "POST" -Uri $uri -Headers @{
        "X-Anty-Session-Token" = $Candidate
    } -Body @{
        type = "http"
        host = "127.0.0.1"
        port = 1
    }

    $details = [string]$probe.message
    $isInvalid = (($probe.status -eq 401) -or ($details -match "(?i)invalid session token"))

    return @{
        valid   = (-not $isInvalid)
        status  = $probe.status
        details = $details
    }
}

try {
    $candidates = Get-SessionTokenCandidates
    $validationMode = if ($SkipValidation) { "skipped" } else { "protected-endpoint" }

    if (-not $SkipValidation) {
        Ensure-LocalAuth
    }

    foreach ($candidate in $candidates) {
        $validation = @{
            valid   = $true
            status  = $null
            details = $null
        }

        if (-not $SkipValidation) {
            $validation = Test-LocalSessionTokenCandidate -Candidate $candidate.token
        }

        if ($validation.valid) {
            Ensure-ParentDirectory -FilePath $OutputFile
            Set-Content -LiteralPath $OutputFile -Value $candidate.token -NoNewline

            $result = [ordered]@{
                success         = $true
                output_file     = (Resolve-Path -LiteralPath $OutputFile).Path
                masked_token    = (Mask-Token -TokenValue $candidate.token)
                token_length    = $candidate.token.Length
                map_id          = $candidate.map_id
                source_file     = $candidate.file
                validation_mode = $validationMode
                validation_code = $validation.status
            }

            Write-Output (ConvertTo-JsonSafe -Value $result)
            exit 0
        }
    }

    throw "Failed to recover a valid LocalSessionToken from Session Storage."
} catch {
    Write-Error $_.Exception.Message
    exit 1
}
