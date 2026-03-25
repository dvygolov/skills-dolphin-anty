# Profile Statuses

## Contents

1. Coverage
2. Commands
3. Payload guidance

## Coverage

Cloud `browser_profiles/statuses*` coverage in `scripts/dolphin-anty.ps1`:

- `list-profile-statuses`
- `get-profile-status`
- `create-profile-status`
- `update-profile-status`
- `delete-profile-status`
- `bulk-delete-profile-statuses`
- `bulk-change-profile-statuses`

## Commands

- List statuses:
  - `pwsh -File .\scripts\dolphin-anty.ps1 -Command list-profile-statuses -Limit 50`
- Get one status:
  - `pwsh -File .\scripts\dolphin-anty.ps1 -Command get-profile-status -ProfileStatusId "<id>"`
- Create status:
  - `pwsh -File .\scripts\dolphin-anty.ps1 -Command create-profile-status -Json '{"name":"In Progress","color":"green"}'`
- Update status:
  - `pwsh -File .\scripts\dolphin-anty.ps1 -Command update-profile-status -ProfileStatusId "<id>" -Set "name=Ready"`
- Delete status:
  - `pwsh -File .\scripts\dolphin-anty.ps1 -Command delete-profile-status -ProfileStatusId "<id>"`
- Bulk delete statuses:
  - `pwsh -File .\scripts\dolphin-anty.ps1 -Command bulk-delete-profile-statuses -Json '{"ids":[42,43]}'`
- Bulk assign/change status:
  - `pwsh -File .\scripts\dolphin-anty.ps1 -Command bulk-change-profile-statuses -Json '{"ids":[123,124],"status":{"id":42}}'`

## Payload Guidance

- For create/update of one status, `-Set` is fine for flat fields
- For bulk status changes, use `-Json`
- If you need the exact backend schema, open `references/dolphinanty-public-api.json`
