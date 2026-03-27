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
  - `node ./scripts/dolphin-anty.js --command export-local-storage -ProfileId "<id>" -Json '{"transfer":0,"plan":"base"}'`
- Export local storage for a locked profile:
  - `node ./scripts/dolphin-anty.js --command export-local-storage -ProfileId "<id>" -Json '{"transfer":0,"plan":"base","browserProfilePassword":"secret"}'`
- Export local storage mass:
  - `node ./scripts/dolphin-anty.js --command export-local-storage-mass`
- Import local storage:
  - `node ./scripts/dolphin-anty.js --command import-local-storage -Json '{...}'`
- Import cookies:
  - `node ./scripts/dolphin-anty.js --command import-cookies -Json '{...}'`
- Export cookies:
  - `node ./scripts/dolphin-anty.js --command export-cookies -Json '{"browserProfiles":[{"id":123456,"name":"Real Profile Name","transfer":0}],"plan":"base","doNotSave":true}'`
- Run cookie robot:
  - `node ./scripts/dolphin-anty.js --command run-cookie-robot -ProfileId "<id>" -Json '{"data":["https://example.com"],"headless":false,"imageless":true}'`
- Stop cookie robot:
  - `node ./scripts/dolphin-anty.js --command stop-cookie-robot -ProfileId "<id>"`

## Notes

- These are local API operations and require Dolphin Anty running on the same machine
- Use `-Json` for import/export payloads
- `export-local-storage` requires `transfer` and `plan`
- `export-cookies` should include real profile names and usually an explicit `plan`
- Exact cookie/local-storage schemas live in `references/dolphinanty-public-api.json`

