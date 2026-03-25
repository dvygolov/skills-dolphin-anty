# Cookies And Local Storage

## Contents

1. Cookies coverage
2. Local Storage coverage
3. Commands
4. Notes

## Cookies Coverage

- `import-cookies`
- `export-cookies`
- `run-cookie-robot`
- `stop-cookie-robot`

## Local Storage Coverage

- `export-local-storage`
- `export-local-storage-mass`
- `import-local-storage`

## Commands

- Export local storage for one profile:
  - `pwsh -File .\scripts\dolphin-anty.ps1 -Command export-local-storage -ProfileId "<id>" -Json '{"transfer":0,"plan":"base"}'`
- Export local storage for a locked profile:
  - `pwsh -File .\scripts\dolphin-anty.ps1 -Command export-local-storage -ProfileId "<id>" -Json '{"transfer":0,"plan":"base","browserProfilePassword":"secret"}'`
- Export local storage mass:
  - `pwsh -File .\scripts\dolphin-anty.ps1 -Command export-local-storage-mass`
- Import local storage:
  - `pwsh -File .\scripts\dolphin-anty.ps1 -Command import-local-storage -Json '{...}'`
- Import cookies:
  - `pwsh -File .\scripts\dolphin-anty.ps1 -Command import-cookies -Json '{...}'`
- Export cookies:
  - `pwsh -File .\scripts\dolphin-anty.ps1 -Command export-cookies -Json '{"browserProfiles":[{"id":123456,"name":"Real Profile Name","transfer":0}],"plan":"base","doNotSave":true}'`
- Run cookie robot:
  - `pwsh -File .\scripts\dolphin-anty.ps1 -Command run-cookie-robot -ProfileId "<id>" -Json '{"data":["https://example.com"],"headless":false,"imageless":true}'`
- Stop cookie robot:
  - `pwsh -File .\scripts\dolphin-anty.ps1 -Command stop-cookie-robot -ProfileId "<id>"`

## Notes

- These are local API operations and require Dolphin Anty running on the same machine
- Use `-Json` for import/export payloads
- `export-local-storage` requires `transfer` and `plan`
- `export-cookies` should include real profile names and usually an explicit `plan`
- Exact cookie/local-storage schemas live in `references/dolphinanty-public-api.json`
