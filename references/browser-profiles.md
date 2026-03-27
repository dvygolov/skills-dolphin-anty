# Browser Profiles

## Contents

1. Coverage
2. Commands
3. Common payload pattern
4. Fallback

## Coverage

Cloud `browser_profiles*` coverage in `scripts/dolphin-anty.js`:

- `list-profiles`
- `create-profile`
- `get-profile`
- `update-profile`
- `delete-profile`
- `bulk-create-profiles`
- `bulk-delete-profiles`
- `transfer-profiles`
- `share-profile-access`
- `share-profiles-access`

## Commands

- Find profiles:
  - `node ./scripts/dolphin-anty.js --command list-profiles -Query "shop-us"`
- Create profile:
  - `node ./scripts/dolphin-anty.js --command create-profile -Json '{"name":"QA Profile","platform":"windows","browserType":"anty"}'`
- Get profile:
  - `node ./scripts/dolphin-anty.js --command get-profile -ProfileId "<id>"`
- Update profile:
  - `node ./scripts/dolphin-anty.js --command update-profile -ProfileId "<id>" -Set "name=New Name"`
- Delete profile:
  - `node ./scripts/dolphin-anty.js --command delete-profile -ProfileId "<id>"`
- Bulk create:
  - `node ./scripts/dolphin-anty.js --command bulk-create-profiles -Json '{"items":[{"name":"QA-1"},{"name":"QA-2"}]}'`
- Bulk delete:
  - `node ./scripts/dolphin-anty.js --command bulk-delete-profiles -Json '{"ids":[123,124]}'`
- Transfer:
  - `node ./scripts/dolphin-anty.js --command transfer-profiles -Json '{"ids":[123],"userId":999}'`
- Share one profile:
  - `node ./scripts/dolphin-anty.js --command share-profile-access -ProfileId "<id>" -Json '{"userIds":[999]}'`
- Share multiple profiles:
  - `node ./scripts/dolphin-anty.js --command share-profiles-access -Json '{"browserProfileIds":[123,124],"userIds":[999]}'`

## Common Payload Pattern

- Simple updates: use `-Set key=value`
- Complex profile bodies, bulk ops, transfer, and access sharing: use `-Json`
- When name lookup is acceptable, `-ProfileName` can replace `-ProfileId` for single-profile commands

## Fallback

- Exact schema lookup: `references/dolphinanty-public-api.json`
- Unwrapped endpoint fallback: `raw-cloud`

