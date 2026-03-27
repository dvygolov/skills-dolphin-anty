# Profile Statuses

## Contents

1. Coverage
2. Commands
3. Payload guidance

## Coverage

Cloud `browser_profiles/statuses*` coverage in `scripts/dolphin-anty.js`:

- `list-profile-statuses`
- `get-profile-status`
- `create-profile-status`
- `update-profile-status`
- `delete-profile-status`
- `bulk-delete-profile-statuses`
- `bulk-change-profile-statuses`

## Commands

- List statuses:
  - `node ./scripts/dolphin-anty.js --command list-profile-statuses -Limit 50`
- Get one status:
  - `node ./scripts/dolphin-anty.js --command get-profile-status -ProfileStatusId "<id>"`
- Create status:
  - `node ./scripts/dolphin-anty.js --command create-profile-status -Json '{"name":"In Progress","color":"green"}'`
- Update status:
  - `node ./scripts/dolphin-anty.js --command update-profile-status -ProfileStatusId "<id>" -Set "name=Ready"`
- Delete status:
  - `node ./scripts/dolphin-anty.js --command delete-profile-status -ProfileStatusId "<id>"`
- Bulk delete statuses:
  - `node ./scripts/dolphin-anty.js --command bulk-delete-profile-statuses -Json '{"ids":[42,43]}'`
- Bulk assign/change status:
  - `node ./scripts/dolphin-anty.js --command bulk-change-profile-statuses -Json '{"ids":[123,124],"status":{"id":42}}'`

## Payload Guidance

- For create/update of one status, `-Set` is fine for flat fields
- For bulk status changes, use `-Json`
- If you need the exact backend schema, open `references/dolphinanty-public-api.json`

