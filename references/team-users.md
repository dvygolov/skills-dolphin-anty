# Team Users

## Contents

1. Coverage
2. Commands
3. Notes

## Coverage

Team user coverage in `scripts/dolphin-anty.ps1`:

- `list-team-users`
- `create-team-user`
- `update-team-user`
- `delete-team-user`

## Commands

- List team users:
  - `pwsh -File .\scripts\dolphin-anty.ps1 -Command list-team-users`
- Create team user:
  - `pwsh -File .\scripts\dolphin-anty.ps1 -Command create-team-user -Json '{"email":"user@example.com","role":"user"}'`
- Update team user:
  - `pwsh -File .\scripts\dolphin-anty.ps1 -Command update-team-user -TeamUserId "<id>" -Json '{"role":"admin"}'`
- Delete team user:
  - `pwsh -File .\scripts\dolphin-anty.ps1 -Command delete-team-user -TeamUserId "<id>"`

## Notes

- Create/delete use API v1 paths, list/update use API v2 paths, but the wrapper hides that split behind the same `/team/users` command surface
- Use `-Json` for all create/update calls
