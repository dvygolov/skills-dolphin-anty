# Local API

## Contents

1. Public local commands
2. Protected local commands
3. Local behavior
4. Command examples

## Public Local Commands

These work with only the external API token:

- `local-auth`
- `list-running-profiles`
- `start-profile`
- `stop-profile`
- `open-url`
- public `raw-local` such as `/browser_profiles/running`

## Protected Local Commands

These need `LocalSessionToken`:

- `check-proxy`
- `change-proxy-ip`
- `change-profile-proxy-ip`
- protected `raw-local`

Read `references/local-session-token.md` before using them.

## Local Behavior

Observed on a live machine:

- `POST /v1.0/auth/login-with-token` returns only `{ "success": true }`
- `local-auth` does not expose `LocalSessionToken`
- `GET /browser_profiles/running` works without `X-Anty-Session-Token`
- protected local endpoints reject missing or wrong session token with `401 invalid session token`

## Command Examples

- Authenticate local API:
  - `pwsh -File .\scripts\dolphin-anty.ps1 -Command local-auth`
- List running profiles:
  - `pwsh -File .\scripts\dolphin-anty.ps1 -Command list-running-profiles`
- Start profile:
  - `pwsh -File .\scripts\dolphin-anty.ps1 -Command start-profile -ProfileId "<id>"`
- Stop profile:
  - `pwsh -File .\scripts\dolphin-anty.ps1 -Command stop-profile -ProfileId "<id>"`
- Open URL in running profile:
  - `pwsh -File .\scripts\dolphin-anty.ps1 -Command open-url -ProfileId "<id>" -Url "https://example.com"`
- Raw local request:
  - `pwsh -File .\scripts\dolphin-anty.ps1 -Command raw-local -Path "/browser_profiles/running"`
