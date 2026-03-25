# Local Session Token

## Contents

1. Why it exists
2. Recovery flow
3. Cache behavior
4. Failure rule

## Why It Exists

Protected local endpoints require header `X-Anty-Session-Token`.

`local-auth` alone is not enough because Dolphin local API does not return the token in its login response.

## Recovery Flow

Use:

- `pwsh -File .\scripts\get-local-session-token.ps1`

What it does:

- scans `%APPDATA%\dolphin_anty\Session Storage`
- extracts `map-<n>-sessionToken` candidates
- validates candidates against a protected local endpoint
- writes the winning token to `.runtime\local-session-token.txt`

## Cache Behavior

`scripts/dolphin-anty.ps1` loads `LocalSessionToken` from:

1. `-LocalSessionToken`
2. `DOLPHIN_ANTY_LOCAL_SESSION_TOKEN`
3. `.runtime\local-session-token.txt`

Refresh the cache when:

- Dolphin Anty was restarted
- protected local commands return `invalid session token`
- the local session changed

## Failure Rule

If token recovery fails:

- do not call protected local endpoints
- tell the user the action is blocked by missing `LocalSessionToken`
- for proxy checks, explicitly say verification is unavailable until token recovery succeeds
