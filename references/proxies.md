# Proxies

## Contents

1. Coverage
2. Commands
3. Protected local operations
4. Fallback

## Coverage

Proxy coverage in `scripts/dolphin-anty.ps1`:

- `list-proxies`
- `get-proxy`
- `create-proxy`
- `update-proxy`
- `delete-proxy`
- `assign-proxy-to-profile`
- `check-proxy`
- `change-proxy-ip`
- `change-profile-proxy-ip`

## Commands

- List proxies:
  - `pwsh -File .\scripts\dolphin-anty.ps1 -Command list-proxies -Query "mobile"`
- Get proxy:
  - `pwsh -File .\scripts\dolphin-anty.ps1 -Command get-proxy -ProxyId "<id>"`
- Create proxy:
  - `pwsh -File .\scripts\dolphin-anty.ps1 -Command create-proxy -ProxyName "US-1" -ProxyType "http" -ProxyHost "1.2.3.4" -ProxyPort 8000`
- Update proxy:
  - `pwsh -File .\scripts\dolphin-anty.ps1 -Command update-proxy -ProxyId "<id>" -Set "name=US-2"`
- Delete proxy:
  - `pwsh -File .\scripts\dolphin-anty.ps1 -Command delete-proxy -ProxyId "<id>"`
- Assign proxy to profile:
  - `pwsh -File .\scripts\dolphin-anty.ps1 -Command assign-proxy-to-profile -ProfileId "<profile-id>" -ProxyId "<proxy-id>"`
- Check proxy:
  - `pwsh -File .\scripts\get-local-session-token.ps1`
  - `pwsh -File .\scripts\dolphin-anty.ps1 -Command check-proxy -ProxyId "<proxy-id>"`
- Change proxy IP:
  - `pwsh -File .\scripts\dolphin-anty.ps1 -Command change-proxy-ip -ProxyId "<proxy-id>"`
- Change profile proxy IP:
  - `pwsh -File .\scripts\dolphin-anty.ps1 -Command change-profile-proxy-ip -ProfileId "<profile-id>"`

## Protected Local Operations

These require `LocalSessionToken`:

- `check-proxy`
- `change-proxy-ip`
- `change-profile-proxy-ip`
- protected `raw-local`

If no cached token exists, run `scripts/get-local-session-token.ps1` first.

## Fallback

- If `check-proxy` fails because of helper payload validation like `changeIpUrl`, call:
  - `pwsh -File .\scripts\dolphin-anty.ps1 -Command raw-local -Path "/check/proxy" -Method POST -Json '{"type":"http","host":"127.0.0.1","port":1}'`
- Exact proxy schema lookup: `references/dolphinanty-public-api.json`
