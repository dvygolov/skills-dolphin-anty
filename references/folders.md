# Folders

## Contents

1. Coverage
2. Commands
3. Payload guidance

## Coverage

Folder coverage in `scripts/dolphin-anty.js`:

- `list-folders`
- `create-folder`
- `get-folder`
- `update-folder`
- `delete-folder`
- `reorder-folders`
- `attach-profiles-to-folder`
- `detach-profiles-from-folders`
- `list-folder-profile-ids`

## Commands

- List folders:
  - `node ./scripts/dolphin-anty.js --command list-folders -Query "QA"`
- Create folder:
  - `node ./scripts/dolphin-anty.js --command create-folder -Json '{"name":"QA"}'`
- Get folder:
  - `node ./scripts/dolphin-anty.js --command get-folder -FolderId "<id>"`
- Update folder:
  - `node ./scripts/dolphin-anty.js --command update-folder -FolderId "<id>" -Set "name=QA 2"`
- Delete folder:
  - `node ./scripts/dolphin-anty.js --command delete-folder -FolderId "<id>"`
- Reorder folders:
  - `node ./scripts/dolphin-anty.js --command reorder-folders -Json '{"ids":[3,1,2]}'`
- Attach profiles:
  - `node ./scripts/dolphin-anty.js --command attach-profiles-to-folder -Json '{"folderId":12,"browserProfileIds":[123,124]}'`
- Detach profiles:
  - `node ./scripts/dolphin-anty.js --command detach-profiles-from-folders -Json '{"browserProfileIds":[123,124]}'`
- List folder profile ids:
  - `node ./scripts/dolphin-anty.js --command list-folder-profile-ids -FolderId "<id>"`

## Payload Guidance

- Use `-Json` for reorder/attach/detach
- Use `-Set` for simple one-folder edits

