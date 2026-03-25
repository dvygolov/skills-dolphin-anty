[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet(
        "help",
        "local-auth",
        "list-profiles",
        "create-profile",
        "get-profile",
        "delete-profile",
        "bulk-delete-profiles",
        "bulk-create-profiles",
        "transfer-profiles",
        "share-profile-access",
        "share-profiles-access",
        "list-profile-statuses",
        "get-profile-status",
        "create-profile-status",
        "update-profile-status",
        "delete-profile-status",
        "bulk-delete-profile-statuses",
        "bulk-change-profile-statuses",
        "list-folders",
        "create-folder",
        "get-folder",
        "update-folder",
        "delete-folder",
        "reorder-folders",
        "attach-profiles-to-folder",
        "detach-profiles-from-folders",
        "list-folder-profile-ids",
        "list-extensions",
        "create-extension",
        "delete-extensions",
        "upload-extension-zip",
        "list-homepages",
        "create-homepages",
        "update-homepage",
        "delete-homepages",
        "list-bookmarks",
        "create-bookmark",
        "update-bookmark",
        "delete-bookmarks",
        "list-team-users",
        "create-team-user",
        "update-team-user",
        "delete-team-user",
        "export-local-storage",
        "export-local-storage-mass",
        "import-local-storage",
        "import-cookies",
        "export-cookies",
        "run-cookie-robot",
        "stop-cookie-robot",
        "list-running-profiles",
        "start-profile",
        "stop-profile",
        "update-profile",
        "open-url",
        "list-proxies",
        "get-proxy",
        "create-proxy",
        "update-proxy",
        "delete-proxy",
        "assign-proxy-to-profile",
        "check-proxy",
        "change-proxy-ip",
        "change-profile-proxy-ip",
        "raw-cloud",
        "raw-local"
    )]
    [string]$Command,

    [string]$ProfileId,
    [string]$ProfileName,
    [string]$Url,
    [int]$Port,
    [int]$Automation = 1,
    [switch]$Headless,

    [string]$Method = "GET",
    [string]$Path,
    [string]$Json,
    [string[]]$Set,

    [string]$Token,
    [string]$TokenFile = (Join-Path $PSScriptRoot "..\dolphin-anty-api-token.txt"),
    [string]$CloudBase = "https://anty-api.com",
    [string]$LocalBase = "http://127.0.0.1:3001/v1.0",
    [int]$Page = 1,
    [int]$Limit = 50,
    [string]$Query,
    [string]$SortBy,
    [string]$Order,
    [string[]]$Ids,
    [switch]$SkipLocalAuth,

    [string]$ProxyId,
    [string]$ProxyName,
    [string]$ProxyType,
    [string]$ProxyHost,
    [int]$ProxyPort,
    [string]$ProxyLogin,
    [string]$ProxyPassword,
    [string]$ProxyChangeIpUrl,
    [string]$ProfileStatusId,
    [string]$FolderId,
    [string]$HomepageId,
    [string]$BookmarkId,
    [string]$TeamUserId,
    [string]$FilePath,

    [string]$LocalSessionToken,
    [string]$LocalSessionTokenFile = (Join-Path $PSScriptRoot "..\.runtime\local-session-token.txt"),
    [switch]$SkipTlsCheck,
    [switch]$ChangeProviderProxy
)

$ErrorActionPreference = "Stop"
$script:ResolvedToken = $null
$script:ResolvedLocalSessionToken = $null

function ConvertTo-JsonSafe {
    param([Parameter(Mandatory = $true)]$Value)
    if ($Value -is [string]) {
        return $Value
    }
    return ($Value | ConvertTo-Json -Depth 30)
}

function Mask-SensitiveText {
    param([string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return $Text
    }

    $out = $Text
    $out = [regex]::Replace($out, "(?i)Bearer\s+[A-Za-z0-9\-_\.=+/]+", "Bearer ***")
    $out = [regex]::Replace($out, "(?i)X-Anty-Session-Token\s*[:=]\s*['""][^'""]+['""]", "X-Anty-Session-Token='***'")
    $out = [regex]::Replace($out, "(?i)""(token|api_token|access_token|refresh_token)""\s*:\s*""[^""]+""", """$1"":""***""")
    $out = [regex]::Replace($out, "\b[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}\b", "***jwt***")

    $max = 1200
    if ($out.Length -gt $max) {
        $out = $out.Substring(0, $max) + "... [truncated]"
    }

    return $out
}

function Join-Endpoint {
    param(
        [Parameter(Mandatory = $true)][string]$Base,
        [Parameter(Mandatory = $true)][string]$PathPart
    )

    $b = $Base.TrimEnd("/")
    $p = $PathPart
    if (-not $p.StartsWith("/")) {
        $p = "/$p"
    }
    return "$b$p"
}

function Add-QueryString {
    param(
        [Parameter(Mandatory = $true)][string]$Uri,
        [hashtable]$QueryParams
    )

    if (-not $QueryParams) {
        return $Uri
    }

    $pairs = @()
    foreach ($key in $QueryParams.Keys) {
        $value = $QueryParams[$key]
        if ($null -eq $value) {
            continue
        }
        $valueText = [string]$value
        if ([string]::IsNullOrWhiteSpace($valueText)) {
            continue
        }
        $pairs += ("{0}={1}" -f [uri]::EscapeDataString([string]$key), [uri]::EscapeDataString($valueText))
    }

    if (-not $pairs.Count) {
        return $Uri
    }

    $separator = "?"
    if ($Uri.Contains("?")) {
        $separator = "&"
    }
    return "$Uri$separator$($pairs -join "&")"
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

function Resolve-LocalSessionTokenValue {
    if ($script:ResolvedLocalSessionToken) {
        return $script:ResolvedLocalSessionToken
    }

    if (-not [string]::IsNullOrWhiteSpace($LocalSessionToken)) {
        $script:ResolvedLocalSessionToken = $LocalSessionToken.Trim()
        return $script:ResolvedLocalSessionToken
    }

    if (-not [string]::IsNullOrWhiteSpace($env:DOLPHIN_ANTY_LOCAL_SESSION_TOKEN)) {
        $script:ResolvedLocalSessionToken = $env:DOLPHIN_ANTY_LOCAL_SESSION_TOKEN.Trim()
        return $script:ResolvedLocalSessionToken
    }

    if (Test-Path -LiteralPath $LocalSessionTokenFile) {
        try {
            $raw = Get-Content -LiteralPath $LocalSessionTokenFile -Raw
            $parsed = Parse-TokenFromText -Text $raw
            if (-not [string]::IsNullOrWhiteSpace($parsed)) {
                $script:ResolvedLocalSessionToken = $parsed.Trim()
                return $script:ResolvedLocalSessionToken
            }
        } catch {
        }
    }

    return $null
}

function Invoke-DolphinRequest {
    param(
        [Parameter(Mandatory = $true)][string]$MethodIn,
        [Parameter(Mandatory = $true)][string]$Uri,
        [hashtable]$Headers,
        [object]$Body,
        [switch]$RawContent
    )

    $invokeParams = @{
        Method      = $MethodIn
        Uri         = $Uri
        ErrorAction = "Stop"
    }

    if ($Headers) {
        $invokeParams.Headers = $Headers
    }
    if ($SkipTlsCheck) {
        $invokeParams.SkipCertificateCheck = $true
    }

    if ($PSBoundParameters.ContainsKey("Body") -and $null -ne $Body) {
        if ($Body -is [string]) {
            $invokeParams.Body = $Body
            $invokeParams.ContentType = "application/json"
        } else {
            $invokeParams.Body = ($Body | ConvertTo-Json -Depth 30)
            $invokeParams.ContentType = "application/json"
        }
    }

    try {
        if ($RawContent) {
            $response = Invoke-WebRequest @invokeParams
            return $response.Content
        }
        return Invoke-RestMethod @invokeParams
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

        $safeDetails = Mask-SensitiveText -Text $details
        if ($statusCode) {
            throw "HTTP ${statusCode}: $safeDetails"
        }
        throw $safeDetails
    }
}

function Invoke-CloudApi {
    param(
        [Parameter(Mandatory = $true)][string]$MethodIn,
        [Parameter(Mandatory = $true)][string]$PathPart,
        [hashtable]$QueryParams,
        [object]$Body
    )

    $tokenValue = Resolve-Token
    $headers = @{
        Authorization = "Bearer $tokenValue"
        Accept        = "application/json"
    }

    $uri = Join-Endpoint -Base $CloudBase -PathPart $PathPart
    $uri = Add-QueryString -Uri $uri -QueryParams $QueryParams

    if ($PSBoundParameters.ContainsKey("Body")) {
        return Invoke-DolphinRequest -MethodIn $MethodIn -Uri $uri -Headers $headers -Body $Body
    }

    return Invoke-DolphinRequest -MethodIn $MethodIn -Uri $uri -Headers $headers
}

function Ensure-LocalAuth {
    if ($SkipLocalAuth) {
        return @{
            skipped = $true
        }
    }

    $tokenValue = Resolve-Token
    $uri = Join-Endpoint -Base $LocalBase -PathPart "/auth/login-with-token"
    return Invoke-DolphinRequest -MethodIn "POST" -Uri $uri -Body @{ token = $tokenValue }
}

function Invoke-LocalApi {
    param(
        [Parameter(Mandatory = $true)][string]$MethodIn,
        [Parameter(Mandatory = $true)][string]$PathPart,
        [hashtable]$QueryParams,
        [object]$Body,
        [switch]$NoAuth
    )

    if (-not $NoAuth) {
        $null = Ensure-LocalAuth
    }

    $uri = Join-Endpoint -Base $LocalBase -PathPart $PathPart
    $uri = Add-QueryString -Uri $uri -QueryParams $QueryParams

    $headers = $null
    $resolvedLocalSessionToken = Resolve-LocalSessionTokenValue
    if (-not [string]::IsNullOrWhiteSpace($resolvedLocalSessionToken)) {
        $headers = @{
            "X-Anty-Session-Token" = $resolvedLocalSessionToken
        }
    }

    if ($PSBoundParameters.ContainsKey("Body")) {
        if ($headers) {
            return Invoke-DolphinRequest -MethodIn $MethodIn -Uri $uri -Headers $headers -Body $Body
        }
        return Invoke-DolphinRequest -MethodIn $MethodIn -Uri $uri -Body $Body
    }

    if ($headers) {
        return Invoke-DolphinRequest -MethodIn $MethodIn -Uri $uri -Headers $headers
    }
    return Invoke-DolphinRequest -MethodIn $MethodIn -Uri $uri
}

function Convert-ScalarValue {
    param([string]$InputValue)

    if ($InputValue -eq "null") {
        return $null
    }

    if ($InputValue -match "^(?i:true|false)$") {
        return [System.Convert]::ToBoolean($InputValue)
    }

    if ($InputValue -match "^-?\d+$") {
        return [int64]$InputValue
    }

    if ($InputValue -match "^-?\d+\.\d+$") {
        return [double]$InputValue
    }

    return $InputValue
}

function Add-SetPairsToMap {
    param(
        [Parameter(Mandatory = $true)][hashtable]$Map,
        [string[]]$Pairs
    )

    if (-not $Pairs) {
        return
    }

    foreach ($entry in $Pairs) {
        if ([string]::IsNullOrWhiteSpace($entry)) {
            continue
        }

        $index = $entry.IndexOf("=")
        if ($index -lt 1) {
            throw "Invalid -Set value '$entry'. Use key=value."
        }

        $key = $entry.Substring(0, $index).Trim()
        $valueRaw = $entry.Substring($index + 1)
        $Map[$key] = Convert-ScalarValue -InputValue $valueRaw
    }
}

function New-PayloadFromInput {
    $payload = @{}
    if (-not [string]::IsNullOrWhiteSpace($Json)) {
        $payload = $Json | ConvertFrom-Json -AsHashtable -ErrorAction Stop
    }
    Add-SetPairsToMap -Map $payload -Pairs $Set
    return $payload
}

function Resolve-NamedIdValue {
    param(
        [string]$DirectId,
        [string]$NameValue,
        [string]$ListPath,
        [string[]]$CollectionKeys,
        [string]$EntityLabel
    )

    if (-not [string]::IsNullOrWhiteSpace($DirectId)) {
        return $DirectId
    }

    if ([string]::IsNullOrWhiteSpace($NameValue)) {
        throw "Specify direct id or name for $EntityLabel."
    }

    $resp = Invoke-CloudApi -MethodIn "GET" -PathPart $ListPath -QueryParams @{
        query = $NameValue
        limit = 100
        page  = 1
    }

    $items = @()
    foreach ($key in $CollectionKeys) {
        if ($resp.PSObject.Properties.Name -contains $key) {
            $candidate = $resp.$key
            if ($candidate -is [System.Collections.IEnumerable] -and -not ($candidate -is [string])) {
                $items = @($candidate)
                break
            }
        }
    }

    if (-not $items.Count -and $resp -is [System.Collections.IEnumerable] -and -not ($resp -is [string])) {
        $items = @($resp)
    }

    if (-not $items.Count) {
        throw "No $EntityLabel found for name: $NameValue"
    }

    $exact = $items | Where-Object { $_.name -eq $NameValue } | Select-Object -First 1
    if ($exact) {
        return [string]$exact.id
    }

    return [string]$items[0].id
}

function Resolve-FolderIdValue {
    param([string]$IdValue, [string]$NameValue)
    return Resolve-NamedIdValue -DirectId $IdValue -NameValue $NameValue -ListPath "/folders" -CollectionKeys @("data","items","folders","result") -EntityLabel "folder"
}

function Resolve-HomepageIdValue {
    param([string]$IdValue, [string]$NameValue)
    return Resolve-NamedIdValue -DirectId $IdValue -NameValue $NameValue -ListPath "/homepages" -CollectionKeys @("data","items","homepages","result") -EntityLabel "homepage"
}

function Resolve-BookmarkIdValue {
    param([string]$IdValue, [string]$NameValue)
    return Resolve-NamedIdValue -DirectId $IdValue -NameValue $NameValue -ListPath "/bookmarks" -CollectionKeys @("data","items","bookmarks","result") -EntityLabel "bookmark"
}

function Resolve-TeamUserIdValue {
    param([string]$IdValue, [string]$NameValue)
    return Resolve-NamedIdValue -DirectId $IdValue -NameValue $NameValue -ListPath "/team/users" -CollectionKeys @("data","items","users","result") -EntityLabel "team user"
}

function Invoke-CloudMultipart {
    param(
        [Parameter(Mandatory = $true)][string]$PathPart,
        [Parameter(Mandatory = $true)][string]$UploadPath,
        [string]$FieldName = "file"
    )

    $tokenValue = Resolve-Token
    if (-not (Test-Path -LiteralPath $UploadPath)) {
        throw "File not found: $UploadPath"
    }

    $uri = Join-Endpoint -Base $CloudBase -PathPart $PathPart
    $form = @{
        $FieldName = Get-Item -LiteralPath $UploadPath
    }

    try {
        return Invoke-RestMethod -Method POST -Uri $uri -Headers @{ Authorization = "Bearer $tokenValue"; Accept = "application/json" } -Form $form -ErrorAction Stop
    } catch {
        $details = if ($_.ErrorDetails -and $_.ErrorDetails.Message) { $_.ErrorDetails.Message } else { $_.Exception.Message }
        throw (Mask-SensitiveText -Text ([string]$details))
    }
}

function Select-ProfileCollection {
    param($Response)

    if ($null -eq $Response) {
        return @()
    }

    foreach ($key in @("data", "items", "browser_profiles", "profiles", "result")) {
        if ($Response.PSObject.Properties.Name -contains $key) {
            $candidate = $Response.$key
            if ($candidate -is [System.Collections.IEnumerable] -and -not ($candidate -is [string])) {
                return @($candidate)
            }
        }
    }

    if ($Response -is [System.Collections.IEnumerable] -and -not ($Response -is [string])) {
        return @($Response)
    }

    return @()
}

function Select-ProxyCollection {
    param($Response)

    if ($null -eq $Response) {
        return @()
    }

    foreach ($key in @("data", "items", "proxies", "result")) {
        if ($Response.PSObject.Properties.Name -contains $key) {
            $candidate = $Response.$key
            if ($candidate -is [System.Collections.IEnumerable] -and -not ($candidate -is [string])) {
                return @($candidate)
            }
        }
    }

    if ($Response -is [System.Collections.IEnumerable] -and -not ($Response -is [string])) {
        return @($Response)
    }

    return @()
}

function Resolve-ProfileIdValue {
    param(
        [string]$IdValue,
        [string]$NameValue
    )

    if (-not [string]::IsNullOrWhiteSpace($IdValue)) {
        return $IdValue
    }

    if ([string]::IsNullOrWhiteSpace($NameValue)) {
        throw "Specify -ProfileId or -ProfileName."
    }

    $resp = Invoke-CloudApi -MethodIn "GET" -PathPart "/browser_profiles" -QueryParams @{
        query = $NameValue
        page  = 1
        limit = 100
    }

    $profiles = Select-ProfileCollection -Response $resp
    if (-not $profiles.Count) {
        throw "No profiles found for name: $NameValue"
    }

    $exact = $profiles | Where-Object { $_.name -eq $NameValue } | Select-Object -First 1
    if ($exact) {
        return [string]$exact.id
    }

    return [string]$profiles[0].id
}

function Resolve-AutomationPort {
    param($StartResponse)

    if ($null -eq $StartResponse) {
        return $null
    }

    if ($StartResponse.PSObject.Properties.Name -contains "automation") {
        $a = $StartResponse.automation
        if ($a -and ($a.PSObject.Properties.Name -contains "port")) {
            return [int]$a.port
        }
    }

    foreach ($key in @("automation_port", "remote_debugging_port", "port")) {
        if ($StartResponse.PSObject.Properties.Name -contains $key) {
            $v = $StartResponse.$key
            if ($v -as [int]) {
                return [int]$v
            }
        }
    }

    foreach ($parent in @("data", "result")) {
        if ($StartResponse.PSObject.Properties.Name -contains $parent) {
            $nested = Resolve-AutomationPort -StartResponse $StartResponse.$parent
            if ($nested) {
                return $nested
            }
        }
    }

    return $null
}

function Resolve-ProxyIdValue {
    param(
        [string]$IdValue,
        [string]$NameValue
    )

    if (-not [string]::IsNullOrWhiteSpace($IdValue)) {
        return $IdValue
    }

    if ([string]::IsNullOrWhiteSpace($NameValue)) {
        throw "Specify -ProxyId or -ProxyName."
    }

    $resp = Invoke-CloudApi -MethodIn "GET" -PathPart "/proxy" -QueryParams @{
        query = $NameValue
        page  = 1
        limit = 100
    }

    $proxies = Select-ProxyCollection -Response $resp
    if (-not $proxies.Count) {
        throw "No proxies found for name: $NameValue"
    }

    $exact = $proxies | Where-Object { $_.name -eq $NameValue } | Select-Object -First 1
    if ($exact) {
        return [string]$exact.id
    }

    return [string]$proxies[0].id
}

function Add-ProxyFieldsToPayload {
    param(
        [Parameter(Mandatory = $true)][hashtable]$Payload
    )

    if (-not [string]::IsNullOrWhiteSpace($ProxyName)) {
        $Payload.name = $ProxyName
    }
    if (-not [string]::IsNullOrWhiteSpace($ProxyType)) {
        $Payload.type = $ProxyType
    }
    if (-not [string]::IsNullOrWhiteSpace($ProxyHost)) {
        $Payload.host = $ProxyHost
    }
    if ($ProxyPort -gt 0) {
        $Payload.port = $ProxyPort
    }
    if (-not [string]::IsNullOrWhiteSpace($ProxyLogin)) {
        $Payload.login = $ProxyLogin
    }
    if (-not [string]::IsNullOrWhiteSpace($ProxyPassword)) {
        $Payload.password = $ProxyPassword
    }
    if (-not [string]::IsNullOrWhiteSpace($ProxyChangeIpUrl)) {
        $Payload.change_ip_url = $ProxyChangeIpUrl
    }
}

function Set-ProfileProxyInternal {
    param(
        [Parameter(Mandatory = $true)][string]$ResolvedProfileId,
        [Parameter(Mandatory = $true)][string]$ResolvedProxyId
    )

    $attempts = @(
        @{ proxy = @{ id = $ResolvedProxyId } },
        @{ proxy_id = $ResolvedProxyId }
    )
    $errors = @()

    foreach ($payload in $attempts) {
        try {
            $resp = Invoke-CloudApi -MethodIn "PATCH" -PathPart "/browser_profiles/$ResolvedProfileId" -Body $payload
            return @{
                update = $resp
                sent   = $payload
            }
        } catch {
            $errors += $_.Exception.Message
        }
    }

    throw "Failed to assign proxy to profile. Attempts: $($errors -join ' | ')"
}

function Start-ProfileInternal {
    param(
        [Parameter(Mandatory = $true)][string]$ResolvedProfileId
    )

    $queryMap = @{
        automation = $Automation
    }
    if ($Headless) {
        $queryMap.headless = 1
    }

    return Invoke-LocalApi -MethodIn "GET" -PathPart "/browser_profiles/$ResolvedProfileId/start" -QueryParams $queryMap
}

function Show-HelpText {
    $text = @"
Commands:
  help
  local-auth
  list-profiles
  create-profile
  get-profile
  delete-profile
  bulk-delete-profiles
  bulk-create-profiles
  transfer-profiles
  share-profile-access
  share-profiles-access
  list-profile-statuses
  get-profile-status
  create-profile-status
  update-profile-status
  delete-profile-status
  bulk-delete-profile-statuses
  bulk-change-profile-statuses
  list-folders
  create-folder
  get-folder
  update-folder
  delete-folder
  reorder-folders
  attach-profiles-to-folder
  detach-profiles-from-folders
  list-folder-profile-ids
  list-extensions
  create-extension
  delete-extensions
  upload-extension-zip
  list-homepages
  create-homepages
  update-homepage
  delete-homepages
  list-bookmarks
  create-bookmark
  update-bookmark
  delete-bookmarks
  list-team-users
  create-team-user
  update-team-user
  delete-team-user
  export-local-storage
  export-local-storage-mass
  import-local-storage
  import-cookies
  export-cookies
  run-cookie-robot
  stop-cookie-robot
  list-running-profiles
  start-profile
  stop-profile
  update-profile
  open-url
  list-proxies
  get-proxy
  create-proxy
  update-proxy
  delete-proxy
  assign-proxy-to-profile
  check-proxy
  change-proxy-ip
  change-profile-proxy-ip
  raw-cloud
  raw-local

Protected local endpoints auto-use LocalSessionToken from:
  1. -LocalSessionToken
  2. DOLPHIN_ANTY_LOCAL_SESSION_TOKEN
  3. .runtime\local-session-token.txt

Refresh cached LocalSessionToken:
  pwsh -File .\scripts\get-local-session-token.ps1

Examples:
  pwsh -File .\scripts\dolphin-anty.ps1 -Command list-profiles -Query "shop"
  pwsh -File .\scripts\dolphin-anty.ps1 -Command create-profile -Json '{"name":"QA Profile","platform":"windows","browserType":"anty"}'
  pwsh -File .\scripts\dolphin-anty.ps1 -Command start-profile -ProfileId "123456"
  pwsh -File .\scripts\dolphin-anty.ps1 -Command update-profile -ProfileId "123456" -Set "name=QA Profile"
  pwsh -File .\scripts\dolphin-anty.ps1 -Command delete-profile -ProfileId "123456"
  pwsh -File .\scripts\dolphin-anty.ps1 -Command bulk-delete-profiles -Json '{"ids":[123456,123457]}'
  pwsh -File .\scripts\dolphin-anty.ps1 -Command bulk-create-profiles -Json '{"items":[{"name":"QA-1"},{"name":"QA-2"}]}'
  pwsh -File .\scripts\dolphin-anty.ps1 -Command transfer-profiles -Json '{"ids":[123456],"userId":999}'
  pwsh -File .\scripts\dolphin-anty.ps1 -Command share-profile-access -ProfileId "123456" -Json '{"userIds":[999]}'
  pwsh -File .\scripts\dolphin-anty.ps1 -Command list-profile-statuses
  pwsh -File .\scripts\dolphin-anty.ps1 -Command list-folders
  pwsh -File .\scripts\dolphin-anty.ps1 -Command create-folder -Json '{"name":"QA"}'
  pwsh -File .\scripts\dolphin-anty.ps1 -Command list-extensions
  pwsh -File .\scripts\dolphin-anty.ps1 -Command upload-extension-zip -FilePath "D:\Downloads\ext.zip"
  pwsh -File .\scripts\dolphin-anty.ps1 -Command list-homepages
  pwsh -File .\scripts\dolphin-anty.ps1 -Command list-bookmarks
  pwsh -File .\scripts\dolphin-anty.ps1 -Command list-team-users
  pwsh -File .\scripts\dolphin-anty.ps1 -Command export-local-storage -ProfileId "123456" -Json '{"transfer":0,"plan":"base"}'
  pwsh -File .\scripts\dolphin-anty.ps1 -Command export-cookies -Json '{"browserProfiles":[{"id":123456,"name":"Real Profile Name","transfer":0}],"plan":"base","doNotSave":true}'
  pwsh -File .\scripts\dolphin-anty.ps1 -Command open-url -ProfileId "123456" -Url "https://example.com"
  pwsh -File .\scripts\dolphin-anty.ps1 -Command list-proxies -Query "resi"
  pwsh -File .\scripts\dolphin-anty.ps1 -Command create-proxy -ProxyName "US-1" -ProxyType "http" -ProxyHost "1.2.3.4" -ProxyPort 8000
  pwsh -File .\scripts\dolphin-anty.ps1 -Command assign-proxy-to-profile -ProfileId "123456" -ProxyId "98765"
  pwsh -File .\scripts\dolphin-anty.ps1 -Command check-proxy -ProxyId "98765"
  pwsh -File .\scripts\dolphin-anty.ps1 -Command change-proxy-ip -ProxyId "98765"
  pwsh -File .\scripts\dolphin-anty.ps1 -Command change-profile-proxy-ip -ProfileId "123456"
"@
    return $text.Trim()
}

try {
    $result = $null
    $resolvedProfileId = $null

    switch ($Command) {
        "help" {
            $result = Show-HelpText
        }

        "local-auth" {
            $result = Ensure-LocalAuth
        }

        "list-profiles" {
            $result = Invoke-CloudApi -MethodIn "GET" -PathPart "/browser_profiles" -QueryParams @{
                page  = $Page
                limit = $Limit
                query = $Query
                sortBy = $SortBy
                order = $Order
                ids = if ($Ids) { ($Ids -join ",") } else { $null }
            }
        }

        "create-profile" {
            $payload = New-PayloadFromInput
            if (-not $payload.Count) {
                throw "Provide profile data via -Json and/or -Set key=value."
            }
            $createResp = Invoke-CloudApi -MethodIn "POST" -PathPart "/browser_profiles" -Body $payload
            $result = @{
                create = $createResp
                sent   = $payload
            }
        }

        "get-profile" {
            $resolvedProfileId = Resolve-ProfileIdValue -IdValue $ProfileId -NameValue $ProfileName
            $result = Invoke-CloudApi -MethodIn "GET" -PathPart "/browser_profiles/$resolvedProfileId"
        }

        "delete-profile" {
            $resolvedProfileId = Resolve-ProfileIdValue -IdValue $ProfileId -NameValue $ProfileName
            $deleteResp = Invoke-CloudApi -MethodIn "DELETE" -PathPart "/browser_profiles/$resolvedProfileId"
            $result = @{
                profile_id = $resolvedProfileId
                delete     = $deleteResp
            }
        }

        "bulk-delete-profiles" {
            $payload = New-PayloadFromInput
            if (-not $payload.Count) {
                throw "Provide bulk delete payload via -Json and/or -Set key=value."
            }
            $deleteResp = Invoke-CloudApi -MethodIn "DELETE" -PathPart "/browser_profiles" -Body $payload
            $result = @{
                delete = $deleteResp
                sent   = $payload
            }
        }

        "bulk-create-profiles" {
            $payload = New-PayloadFromInput
            if (-not $payload.Count) {
                throw "Provide bulk create payload via -Json and/or -Set key=value."
            }
            $createResp = Invoke-CloudApi -MethodIn "POST" -PathPart "/browser_profiles/mass" -Body $payload
            $result = @{
                create = $createResp
                sent   = $payload
            }
        }

        "transfer-profiles" {
            $payload = New-PayloadFromInput
            if (-not $payload.Count) {
                throw "Provide transfer payload via -Json and/or -Set key=value."
            }
            $transferResp = Invoke-CloudApi -MethodIn "POST" -PathPart "/browser_profiles/transfer" -Body $payload
            $result = @{
                transfer = $transferResp
                sent     = $payload
            }
        }

        "share-profile-access" {
            $resolvedProfileId = Resolve-ProfileIdValue -IdValue $ProfileId -NameValue $ProfileName
            $payload = New-PayloadFromInput
            if (-not $payload.Count) {
                throw "Provide access payload via -Json and/or -Set key=value."
            }
            $shareResp = Invoke-CloudApi -MethodIn "PATCH" -PathPart "/browser_profiles/$resolvedProfileId/access" -Body $payload
            $result = @{
                profile_id = $resolvedProfileId
                access     = $shareResp
                sent       = $payload
            }
        }

        "share-profiles-access" {
            $payload = New-PayloadFromInput
            if (-not $payload.Count) {
                throw "Provide multi-profile access payload via -Json and/or -Set key=value."
            }
            $shareResp = Invoke-CloudApi -MethodIn "POST" -PathPart "/browser_profiles/access" -Body $payload
            $result = @{
                access = $shareResp
                sent   = $payload
            }
        }

        "list-profile-statuses" {
            $result = Invoke-CloudApi -MethodIn "GET" -PathPart "/browser_profiles/statuses" -QueryParams @{
                limit = $Limit
                query = $Query
            }
        }

        "get-profile-status" {
            if ([string]::IsNullOrWhiteSpace($ProfileStatusId)) {
                throw "Specify -ProfileStatusId for get-profile-status."
            }
            $result = Invoke-CloudApi -MethodIn "GET" -PathPart "/browser_profiles/statuses/$ProfileStatusId"
        }

        "create-profile-status" {
            $payload = New-PayloadFromInput
            if (-not $payload.Count) {
                throw "Provide profile status data via -Json and/or -Set key=value."
            }
            $createResp = Invoke-CloudApi -MethodIn "POST" -PathPart "/browser_profiles/statuses" -Body $payload
            $result = @{
                create = $createResp
                sent   = $payload
            }
        }

        "update-profile-status" {
            if ([string]::IsNullOrWhiteSpace($ProfileStatusId)) {
                throw "Specify -ProfileStatusId for update-profile-status."
            }
            $payload = New-PayloadFromInput
            if (-not $payload.Count) {
                throw "Provide profile status update data via -Json and/or -Set key=value."
            }
            $updateResp = Invoke-CloudApi -MethodIn "PATCH" -PathPart "/browser_profiles/statuses/$ProfileStatusId" -Body $payload
            $result = @{
                profile_status_id = $ProfileStatusId
                update            = $updateResp
                sent              = $payload
            }
        }

        "delete-profile-status" {
            if ([string]::IsNullOrWhiteSpace($ProfileStatusId)) {
                throw "Specify -ProfileStatusId for delete-profile-status."
            }
            $deleteResp = Invoke-CloudApi -MethodIn "DELETE" -PathPart "/browser_profiles/statuses/$ProfileStatusId"
            $result = @{
                profile_status_id = $ProfileStatusId
                delete            = $deleteResp
            }
        }

        "bulk-delete-profile-statuses" {
            $payload = New-PayloadFromInput
            if (-not $payload.Count) {
                throw "Provide bulk delete profile statuses payload via -Json and/or -Set key=value."
            }
            $deleteResp = Invoke-CloudApi -MethodIn "DELETE" -PathPart "/browser_profiles/statuses" -Body $payload
            $result = @{
                delete = $deleteResp
                sent   = $payload
            }
        }

        "bulk-change-profile-statuses" {
            $payload = New-PayloadFromInput
            if (-not $payload.Count) {
                throw "Provide bulk change profile statuses payload via -Json and/or -Set key=value."
            }
            $changeResp = Invoke-CloudApi -MethodIn "PUT" -PathPart "/browser_profiles/statuses/bulk" -Body $payload
            $result = @{
                change = $changeResp
                sent   = $payload
            }
        }

        "list-folders" {
            $result = Invoke-CloudApi -MethodIn "GET" -PathPart "/folders" -QueryParams @{ query = $Query }
        }

        "create-folder" {
            $payload = New-PayloadFromInput
            if (-not $payload.Count) { throw "Provide folder data via -Json and/or -Set key=value." }
            $createResp = Invoke-CloudApi -MethodIn "POST" -PathPart "/folders" -Body $payload
            $result = @{ create = $createResp; sent = $payload }
        }

        "get-folder" {
            $resolvedFolderId = Resolve-FolderIdValue -IdValue $FolderId -NameValue $Query
            $result = Invoke-CloudApi -MethodIn "GET" -PathPart "/folders/$resolvedFolderId"
        }

        "update-folder" {
            $resolvedFolderId = Resolve-FolderIdValue -IdValue $FolderId -NameValue $Query
            $payload = New-PayloadFromInput
            if (-not $payload.Count) { throw "Provide folder update data via -Json and/or -Set key=value." }
            $updateResp = Invoke-CloudApi -MethodIn "PATCH" -PathPart "/folders/$resolvedFolderId" -Body $payload
            $result = @{ folder_id = $resolvedFolderId; update = $updateResp; sent = $payload }
        }

        "delete-folder" {
            $resolvedFolderId = Resolve-FolderIdValue -IdValue $FolderId -NameValue $Query
            $deleteResp = Invoke-CloudApi -MethodIn "DELETE" -PathPart "/folders/$resolvedFolderId"
            $result = @{ folder_id = $resolvedFolderId; delete = $deleteResp }
        }

        "reorder-folders" {
            $payload = New-PayloadFromInput
            if (-not $payload.Count) { throw "Provide folders order payload via -Json and/or -Set key=value." }
            $orderResp = Invoke-CloudApi -MethodIn "PUT" -PathPart "/folders/order" -Body $payload
            $result = @{ reorder = $orderResp; sent = $payload }
        }

        "attach-profiles-to-folder" {
            $payload = New-PayloadFromInput
            if (-not $payload.Count) { throw "Provide attach payload via -Json and/or -Set key=value." }
            $attachResp = Invoke-CloudApi -MethodIn "POST" -PathPart "/folders/mass/attach-profiles" -Body $payload
            $result = @{ attach = $attachResp; sent = $payload }
        }

        "detach-profiles-from-folders" {
            $payload = New-PayloadFromInput
            if (-not $payload.Count) { throw "Provide detach payload via -Json and/or -Set key=value." }
            $detachResp = Invoke-CloudApi -MethodIn "DELETE" -PathPart "/folders/mass/detach-profiles" -Body $payload
            $result = @{ detach = $detachResp; sent = $payload }
        }

        "list-folder-profile-ids" {
            $resolvedFolderId = Resolve-FolderIdValue -IdValue $FolderId -NameValue $Query
            $result = Invoke-CloudApi -MethodIn "GET" -PathPart "/folders/$resolvedFolderId/profile-ids"
        }

        "list-extensions" {
            $result = Invoke-CloudApi -MethodIn "GET" -PathPart "/extensions" -QueryParams @{ limit = $Limit; query = $Query }
        }

        "create-extension" {
            $payload = New-PayloadFromInput
            if (-not $payload.Count) { throw "Provide extension create payload via -Json and/or -Set key=value." }
            $createResp = Invoke-CloudApi -MethodIn "POST" -PathPart "/extensions" -Body $payload
            $result = @{ create = $createResp; sent = $payload }
        }

        "delete-extensions" {
            $payload = New-PayloadFromInput
            if (-not $payload.Count) { throw "Provide extension delete payload via -Json and/or -Set key=value." }
            $deleteResp = Invoke-CloudApi -MethodIn "DELETE" -PathPart "/extensions" -Body $payload
            $result = @{ delete = $deleteResp; sent = $payload }
        }

        "upload-extension-zip" {
            if ([string]::IsNullOrWhiteSpace($FilePath)) { throw "Specify -FilePath for upload-extension-zip." }
            $uploadResp = Invoke-CloudMultipart -PathPart "/extensions/upload-zipped" -UploadPath $FilePath
            $result = @{ upload = $uploadResp; file = $FilePath }
        }

        "list-homepages" {
            $result = Invoke-CloudApi -MethodIn "GET" -PathPart "/homepages" -QueryParams @{ limit = $Limit; query = $Query }
        }

        "create-homepages" {
            $payload = New-PayloadFromInput
            if (-not $payload.Count) { throw "Provide homepage payload via -Json and/or -Set key=value." }
            $createResp = Invoke-CloudApi -MethodIn "POST" -PathPart "/homepages" -Body $payload
            $result = @{ create = $createResp; sent = $payload }
        }

        "update-homepage" {
            if ([string]::IsNullOrWhiteSpace($HomepageId)) { throw "Specify -HomepageId for update-homepage." }
            $payload = New-PayloadFromInput
            if (-not $payload.Count) { throw "Provide homepage update payload via -Json and/or -Set key=value." }
            $updateResp = Invoke-CloudApi -MethodIn "PATCH" -PathPart "/homepages/$HomepageId" -Body $payload
            $result = @{ homepage_id = $HomepageId; update = $updateResp; sent = $payload }
        }

        "delete-homepages" {
            $payload = New-PayloadFromInput
            if (-not $payload.Count) { throw "Provide homepage delete payload via -Json and/or -Set key=value." }
            $deleteResp = Invoke-CloudApi -MethodIn "DELETE" -PathPart "/homepages" -Body $payload
            $result = @{ delete = $deleteResp; sent = $payload }
        }

        "list-bookmarks" {
            $result = Invoke-CloudApi -MethodIn "GET" -PathPart "/bookmarks" -QueryParams @{ limit = $Limit; query = $Query }
        }

        "create-bookmark" {
            $payload = New-PayloadFromInput
            if (-not $payload.Count) { throw "Provide bookmark payload via -Json and/or -Set key=value." }
            $createResp = Invoke-CloudApi -MethodIn "POST" -PathPart "/bookmarks" -Body $payload
            $result = @{ create = $createResp; sent = $payload }
        }

        "update-bookmark" {
            if ([string]::IsNullOrWhiteSpace($BookmarkId)) { throw "Specify -BookmarkId for update-bookmark." }
            $payload = New-PayloadFromInput
            if (-not $payload.Count) { throw "Provide bookmark update payload via -Json and/or -Set key=value." }
            $updateResp = Invoke-CloudApi -MethodIn "PATCH" -PathPart "/bookmarks/$BookmarkId" -Body $payload
            $result = @{ bookmark_id = $BookmarkId; update = $updateResp; sent = $payload }
        }

        "delete-bookmarks" {
            $payload = New-PayloadFromInput
            if (-not $payload.Count) { throw "Provide bookmark delete payload via -Json and/or -Set key=value." }
            $deleteResp = Invoke-CloudApi -MethodIn "DELETE" -PathPart "/bookmarks" -Body $payload
            $result = @{ delete = $deleteResp; sent = $payload }
        }

        "list-team-users" {
            $result = Invoke-CloudApi -MethodIn "GET" -PathPart "/team/users" -QueryParams @{ limit = $Limit; query = $Query }
        }

        "create-team-user" {
            $payload = New-PayloadFromInput
            if (-not $payload.Count) { throw "Provide team user payload via -Json and/or -Set key=value." }
            $createResp = Invoke-CloudApi -MethodIn "POST" -PathPart "/team/users" -Body $payload
            $result = @{ create = $createResp; sent = $payload }
        }

        "update-team-user" {
            $resolvedTeamUserId = Resolve-TeamUserIdValue -IdValue $TeamUserId -NameValue $Query
            $payload = New-PayloadFromInput
            if (-not $payload.Count) { throw "Provide team user update payload via -Json and/or -Set key=value." }
            $updateResp = Invoke-CloudApi -MethodIn "PATCH" -PathPart "/team/users/$resolvedTeamUserId" -Body $payload
            $result = @{ team_user_id = $resolvedTeamUserId; update = $updateResp; sent = $payload }
        }

        "delete-team-user" {
            $resolvedTeamUserId = Resolve-TeamUserIdValue -IdValue $TeamUserId -NameValue $Query
            $deleteResp = Invoke-CloudApi -MethodIn "DELETE" -PathPart "/team/users/$resolvedTeamUserId"
            $result = @{ team_user_id = $resolvedTeamUserId; delete = $deleteResp }
        }

        "export-local-storage" {
            $resolvedProfileId = Resolve-ProfileIdValue -IdValue $ProfileId -NameValue $ProfileName
            $payload = New-PayloadFromInput
            if (-not $payload.Count) {
                throw "Provide export-local-storage payload via -Json with at least transfer and plan."
            }
            if (-not $payload.ContainsKey("transfer") -or -not $payload.ContainsKey("plan")) {
                throw "export-local-storage requires transfer and plan in -Json."
            }
            $result = Invoke-LocalApi -MethodIn "POST" -PathPart "/local-storage/export/$resolvedProfileId" -Body $payload
        }

        "export-local-storage-mass" {
            $result = Invoke-LocalApi -MethodIn "GET" -PathPart "/local-storage/export"
        }

        "import-local-storage" {
            $payload = New-PayloadFromInput
            if (-not $payload.Count) { throw "Provide local storage import payload via -Json and/or -Set key=value." }
            $importResp = Invoke-LocalApi -MethodIn "POST" -PathPart "/local-storage/import" -Body $payload
            $result = @{ import = $importResp; sent = $payload }
        }

        "import-cookies" {
            $payload = New-PayloadFromInput
            if (-not $payload.Count) { throw "Provide cookies import payload via -Json and/or -Set key=value." }
            $importResp = Invoke-LocalApi -MethodIn "POST" -PathPart "/cookies/import" -Body $payload
            $result = @{ import = $importResp; sent = $payload }
        }

        "export-cookies" {
            $payload = New-PayloadFromInput
            if (-not $payload.Count) { throw "Provide cookies export payload via -Json and/or -Set key=value." }
            $exportResp = Invoke-LocalApi -MethodIn "POST" -PathPart "/export-cookies" -Body $payload
            $result = @{ export = $exportResp; sent = $payload }
        }

        "run-cookie-robot" {
            $resolvedProfileId = Resolve-ProfileIdValue -IdValue $ProfileId -NameValue $ProfileName
            $payload = New-PayloadFromInput
            if (-not $payload.Count) { throw "Provide cookie robot payload via -Json and/or -Set key=value." }
            $robotResp = Invoke-LocalApi -MethodIn "POST" -PathPart "/import/cookies/$resolvedProfileId/robot" -Body $payload
            $result = @{ profile_id = $resolvedProfileId; robot = $robotResp; sent = $payload }
        }

        "stop-cookie-robot" {
            $resolvedProfileId = Resolve-ProfileIdValue -IdValue $ProfileId -NameValue $ProfileName
            $robotResp = Invoke-LocalApi -MethodIn "GET" -PathPart "/import/cookies/$resolvedProfileId/robot-stop"
            $result = @{ profile_id = $resolvedProfileId; stop = $robotResp }
        }

        "list-running-profiles" {
            $result = Invoke-LocalApi -MethodIn "GET" -PathPart "/browser_profiles/running"
        }

        "start-profile" {
            $resolvedProfileId = Resolve-ProfileIdValue -IdValue $ProfileId -NameValue $ProfileName
            $startResp = Start-ProfileInternal -ResolvedProfileId $resolvedProfileId
            $result = @{
                profile_id = $resolvedProfileId
                start      = $startResp
                port       = Resolve-AutomationPort -StartResponse $startResp
            }
        }

        "stop-profile" {
            $resolvedProfileId = Resolve-ProfileIdValue -IdValue $ProfileId -NameValue $ProfileName
            $stopResp = Invoke-LocalApi -MethodIn "GET" -PathPart "/browser_profiles/$resolvedProfileId/stop"
            $result = @{
                profile_id = $resolvedProfileId
                stop       = $stopResp
            }
        }

        "update-profile" {
            $resolvedProfileId = Resolve-ProfileIdValue -IdValue $ProfileId -NameValue $ProfileName
            $payload = @{}
            if (-not [string]::IsNullOrWhiteSpace($Json)) {
                $payload = $Json | ConvertFrom-Json -AsHashtable -ErrorAction Stop
            }
            Add-SetPairsToMap -Map $payload -Pairs $Set
            if (-not $payload.Count) {
                throw "Provide update data via -Json and/or -Set key=value."
            }
            $updateResp = Invoke-CloudApi -MethodIn "PATCH" -PathPart "/browser_profiles/$resolvedProfileId" -Body $payload
            $result = @{
                profile_id = $resolvedProfileId
                update     = $updateResp
                sent       = $payload
            }
        }

        "open-url" {
            if ([string]::IsNullOrWhiteSpace($Url)) {
                throw "Specify -Url for open-url command."
            }

            $resolvedProfileId = Resolve-ProfileIdValue -IdValue $ProfileId -NameValue $ProfileName
            $effectivePort = $Port
            $startInfo = $null

            if (-not $effectivePort) {
                $startInfo = Start-ProfileInternal -ResolvedProfileId $resolvedProfileId
                $effectivePort = Resolve-AutomationPort -StartResponse $startInfo
            }

            if (-not $effectivePort) {
                throw "Unable to resolve automation/debugging port. Pass -Port explicitly."
            }

            $encodedUrl = [uri]::EscapeDataString($Url)
            $newTabUri = "http://127.0.0.1:$effectivePort/json/new?$encodedUrl"

            $tabResult = $null
            $lastError = $null
            foreach ($m in @("PUT", "POST", "GET")) {
                try {
                    $raw = Invoke-DolphinRequest -MethodIn $m -Uri $newTabUri -RawContent
                    try {
                        $parsed = $raw | ConvertFrom-Json -ErrorAction Stop
                        $tabResult = @{
                            method = $m
                            value  = $parsed
                        }
                    } catch {
                        $tabResult = @{
                            method = $m
                            value  = $raw
                        }
                    }
                    break
                } catch {
                    $lastError = $_
                }
            }

            if (-not $tabResult) {
                throw "Failed to open URL on debug endpoint. Last error: $($lastError.Exception.Message)"
            }

            $result = @{
                profile_id     = $resolvedProfileId
                debugging_port = $effectivePort
                started        = $startInfo
                opened         = $tabResult
            }
        }

        "list-proxies" {
            $result = Invoke-CloudApi -MethodIn "GET" -PathPart "/proxy" -QueryParams @{
                page  = $Page
                limit = $Limit
                query = $Query
                sortBy = $SortBy
                order = $Order
                ids = if ($Ids) { ($Ids -join ",") } else { $null }
            }
        }

        "get-proxy" {
            $resolvedProxyId = Resolve-ProxyIdValue -IdValue $ProxyId -NameValue $ProxyName
            $result = Invoke-CloudApi -MethodIn "GET" -PathPart "/proxy/$resolvedProxyId"
        }

        "create-proxy" {
            $payload = @{}
            if (-not [string]::IsNullOrWhiteSpace($Json)) {
                $payload = $Json | ConvertFrom-Json -AsHashtable -ErrorAction Stop
            }
            Add-SetPairsToMap -Map $payload -Pairs $Set
            Add-ProxyFieldsToPayload -Payload $payload
            if (-not $payload.Count) {
                throw "Provide proxy data via -Json, -Set key=value, or typed proxy params."
            }
            $createResp = Invoke-CloudApi -MethodIn "POST" -PathPart "/proxy" -Body $payload
            $result = @{
                create = $createResp
                sent   = $payload
            }
        }

        "update-proxy" {
            $resolvedProxyId = Resolve-ProxyIdValue -IdValue $ProxyId -NameValue $ProxyName
            $payload = @{}
            if (-not [string]::IsNullOrWhiteSpace($Json)) {
                $payload = $Json | ConvertFrom-Json -AsHashtable -ErrorAction Stop
            }
            Add-SetPairsToMap -Map $payload -Pairs $Set
            Add-ProxyFieldsToPayload -Payload $payload
            if (-not $payload.Count) {
                throw "Provide proxy update data via -Json, -Set key=value, or typed proxy params."
            }
            $updateResp = Invoke-CloudApi -MethodIn "PATCH" -PathPart "/proxy/$resolvedProxyId" -Body $payload
            $result = @{
                proxy_id = $resolvedProxyId
                update   = $updateResp
                sent     = $payload
            }
        }

        "delete-proxy" {
            $resolvedProxyId = Resolve-ProxyIdValue -IdValue $ProxyId -NameValue $ProxyName
            $deleteResp = Invoke-CloudApi -MethodIn "DELETE" -PathPart "/proxy/$resolvedProxyId"
            $result = @{
                proxy_id = $resolvedProxyId
                delete   = $deleteResp
            }
        }

        "assign-proxy-to-profile" {
            $resolvedProfileId = Resolve-ProfileIdValue -IdValue $ProfileId -NameValue $ProfileName
            $resolvedProxyId = Resolve-ProxyIdValue -IdValue $ProxyId -NameValue $ProxyName
            $assignResp = Set-ProfileProxyInternal -ResolvedProfileId $resolvedProfileId -ResolvedProxyId $resolvedProxyId
            $result = @{
                profile_id = $resolvedProfileId
                proxy_id   = $resolvedProxyId
                assign     = $assignResp.update
                sent       = $assignResp.sent
            }
        }

        "check-proxy" {
            $resolvedProxyId = $null
            $payload = @{}

            if (-not [string]::IsNullOrWhiteSpace($Json)) {
                $payload = $Json | ConvertFrom-Json -AsHashtable -ErrorAction Stop
            }
            Add-SetPairsToMap -Map $payload -Pairs $Set
            Add-ProxyFieldsToPayload -Payload $payload

            if (
                (-not $payload.ContainsKey("type") -or [string]::IsNullOrWhiteSpace([string]$payload.type)) -or
                (-not $payload.ContainsKey("host") -or [string]::IsNullOrWhiteSpace([string]$payload.host)) -or
                (-not $payload.ContainsKey("port") -or [string]::IsNullOrWhiteSpace([string]$payload.port))
            ) {
                if (-not [string]::IsNullOrWhiteSpace($ProxyId) -or -not [string]::IsNullOrWhiteSpace($ProxyName)) {
                    $resolvedProxyId = Resolve-ProxyIdValue -IdValue $ProxyId -NameValue $ProxyName
                    $proxyResp = Invoke-CloudApi -MethodIn "GET" -PathPart "/proxy/$resolvedProxyId"
                    $proxyData = $proxyResp
                    if ($proxyResp.PSObject.Properties.Name -contains "data") {
                        $proxyData = $proxyResp.data
                    }

                    if (-not $payload.ContainsKey("type") -and $proxyData.PSObject.Properties.Name -contains "type") { $payload.type = $proxyData.type }
                    if (-not $payload.ContainsKey("host") -and $proxyData.PSObject.Properties.Name -contains "host") { $payload.host = $proxyData.host }
                    if (-not $payload.ContainsKey("port") -and $proxyData.PSObject.Properties.Name -contains "port") { $payload.port = $proxyData.port }
                    if (-not $payload.ContainsKey("login") -and $proxyData.PSObject.Properties.Name -contains "login") { $payload.login = $proxyData.login }
                    if (-not $payload.ContainsKey("password") -and $proxyData.PSObject.Properties.Name -contains "password") { $payload.password = $proxyData.password }
                    if (-not $payload.ContainsKey("name") -and $proxyData.PSObject.Properties.Name -contains "name") { $payload.name = $proxyData.name }
                    if (-not $payload.ContainsKey("changeIpUrl") -and $proxyData.PSObject.Properties.Name -contains "changeIpUrl") { $payload.changeIpUrl = $proxyData.changeIpUrl }
                    if (-not $payload.ContainsKey("changeIpUrl") -and $proxyData.PSObject.Properties.Name -contains "change_ip_url") { $payload.changeIpUrl = $proxyData.change_ip_url }
                }
            }

            if (
                (-not $payload.ContainsKey("type") -or [string]::IsNullOrWhiteSpace([string]$payload.type)) -or
                (-not $payload.ContainsKey("host") -or [string]::IsNullOrWhiteSpace([string]$payload.host)) -or
                (-not $payload.ContainsKey("port") -or [string]::IsNullOrWhiteSpace([string]$payload.port))
            ) {
                throw "check-proxy requires type/host/port. Pass typed proxy args, -Json, or -ProxyId/-ProxyName."
            }

            $hasLogin = $payload.ContainsKey("login")
            $hasPassword = $payload.ContainsKey("password")
            if ($hasLogin -xor $hasPassword) {
                throw "Proxy auth requires both login and password for check-proxy."
            }

            if ($ChangeProviderProxy) {
                $payload.changeProviderProxy = $true
                if ($resolvedProxyId) {
                    $payload.id = [int64]$resolvedProxyId
                }
            }

            $checkResp = Invoke-LocalApi -MethodIn "POST" -PathPart "/check/proxy" -Body $payload
            $result = @{
                proxy_id = $resolvedProxyId
                check    = $checkResp
                sent     = $payload
            }
        }

        "change-proxy-ip" {
            $resolvedProxyId = Resolve-ProxyIdValue -IdValue $ProxyId -NameValue $ProxyName
            $changeResp = Invoke-LocalApi -MethodIn "GET" -PathPart "/proxy/$resolvedProxyId/change_proxy_ip"
            $result = @{
                proxy_id = $resolvedProxyId
                change   = $changeResp
            }
        }

        "change-profile-proxy-ip" {
            $resolvedProfileId = Resolve-ProfileIdValue -IdValue $ProfileId -NameValue $ProfileName
            $changeResp = Invoke-LocalApi -MethodIn "GET" -PathPart "/browser_profiles/$resolvedProfileId/change_proxy_ip"
            $result = @{
                profile_id = $resolvedProfileId
                change     = $changeResp
            }
        }

        "raw-cloud" {
            if ([string]::IsNullOrWhiteSpace($Path)) {
                throw "Specify -Path for raw-cloud."
            }
            $bodyValue = $null
            if (-not [string]::IsNullOrWhiteSpace($Json)) {
                $bodyValue = $Json | ConvertFrom-Json -AsHashtable -ErrorAction Stop
            }
            if ($null -ne $bodyValue) {
                $result = Invoke-CloudApi -MethodIn $Method.ToUpperInvariant() -PathPart $Path -Body $bodyValue
            } else {
                $result = Invoke-CloudApi -MethodIn $Method.ToUpperInvariant() -PathPart $Path
            }
        }

        "raw-local" {
            if ([string]::IsNullOrWhiteSpace($Path)) {
                throw "Specify -Path for raw-local."
            }
            $bodyValue = $null
            if (-not [string]::IsNullOrWhiteSpace($Json)) {
                $bodyValue = $Json | ConvertFrom-Json -AsHashtable -ErrorAction Stop
            }
            if ($null -ne $bodyValue) {
                $result = Invoke-LocalApi -MethodIn $Method.ToUpperInvariant() -PathPart $Path -Body $bodyValue
            } else {
                $result = Invoke-LocalApi -MethodIn $Method.ToUpperInvariant() -PathPart $Path
            }
        }
    }

    Write-Output (ConvertTo-JsonSafe -Value $result)
} catch {
    $message = $_.Exception.Message
    if ($_.ErrorDetails -and $_.ErrorDetails.Message) {
        $message = "$message`n$($_.ErrorDetails.Message)"
    }
    if ($message -match "(?i)invalid session token") {
        $message = "$message`nHint: run .\scripts\get-local-session-token.ps1 or provide -LocalSessionToken '<token>' for protected local endpoints."
    }
    Write-Error (Mask-SensitiveText -Text $message)
    exit 1
}
