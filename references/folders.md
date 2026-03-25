# Folders

## Contents

1. Coverage
2. Commands
3. Payload guidance

## Coverage

Folder coverage in `scripts/dolphin-anty.ps1`:

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
  - `pwsh -File .\scripts\dolphin-anty.ps1 -Command list-folders -Query "QA"`
- Create folder:
  - `pwsh -File .\scripts\dolphin-anty.ps1 -Command create-folder -Json '{"name":"QA"}'`
- Get folder:
  - `pwsh -File .\scripts\dolphin-anty.ps1 -Command get-folder -FolderId "<id>"`
- Update folder:
  - `pwsh -File .\scripts\dolphin-anty.ps1 -Command update-folder -FolderId "<id>" -Set "name=QA 2"`
- Delete folder:
  - `pwsh -File .\scripts\dolphin-anty.ps1 -Command delete-folder -FolderId "<id>"`
- Reorder folders:
  - `pwsh -File .\scripts\dolphin-anty.ps1 -Command reorder-folders -Json '{"ids":[3,1,2]}'`
- Attach profiles:
  - `pwsh -File .\scripts\dolphin-anty.ps1 -Command attach-profiles-to-folder -Json '{"folderId":12,"browserProfileIds":[123,124]}'`
- Detach profiles:
  - `pwsh -File .\scripts\dolphin-anty.ps1 -Command detach-profiles-from-folders -Json '{"browserProfileIds":[123,124]}'`
- List folder profile ids:
  - `pwsh -File .\scripts\dolphin-anty.ps1 -Command list-folder-profile-ids -FolderId "<id>"`

## Payload Guidance

- Use `-Json` for reorder/attach/detach
- Use `-Set` for simple one-folder edits
