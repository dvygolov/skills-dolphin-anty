# Proxies

## Contents

1. Coverage
2. Commands
3. Protected local operations
4. Fallback

## Coverage

Proxy coverage in `scripts/dolphin-anty.js`:

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
  - `node ./scripts/dolphin-anty.js --command list-proxies -Query "mobile"`
- Get proxy:
  - `node ./scripts/dolphin-anty.js --command get-proxy -ProxyId "<id>"`
- Create proxy:
  - `node ./scripts/dolphin-anty.js --command create-proxy -ProxyName "US-1" -ProxyType "http" -ProxyHost "1.2.3.4" -ProxyPort 8000`
- Update proxy:
  - `node ./scripts/dolphin-anty.js --command update-proxy -ProxyId "<id>" -Set "name=US-2"`
- Delete proxy:
  - `node ./scripts/dolphin-anty.js --command delete-proxy -ProxyId "<id>"`
- Assign proxy to profile:
  - `node ./scripts/dolphin-anty.js --command assign-proxy-to-profile -ProfileId "<profile-id>" -ProxyId "<proxy-id>"`
- Check proxy:
  - `node ./scripts/get-local-session-token.js`
  - `node ./scripts/dolphin-anty.js --command check-proxy -ProxyId "<proxy-id>"`
- Change proxy IP:
  - `node ./scripts/dolphin-anty.js --command change-proxy-ip -ProxyId "<proxy-id>"`
- Change profile proxy IP:
  - `node ./scripts/dolphin-anty.js --command change-profile-proxy-ip -ProfileId "<profile-id>"`

## Protected Local Operations

These require `LocalSessionToken`:

- `check-proxy`
- `change-proxy-ip`
- `change-profile-proxy-ip`
- protected `raw-local`

If no cached token exists, run `scripts/get-local-session-token.js` first.

## Fallback

- If `check-proxy` fails because of helper payload validation like `changeIpUrl`, call:
  - `node ./scripts/dolphin-anty.js --command raw-local -Path "/check/proxy" -Method POST -Json '{"type":"http","host":"127.0.0.1","port":1}'`
- Exact proxy schema lookup: `references/dolphinanty-public-api.json`

