# Homepages And Bookmarks

## Contents

1. Homepage coverage
2. Bookmark coverage
3. Commands

## Homepage Coverage

- `list-homepages`
- `create-homepages`
- `update-homepage`
- `delete-homepages`

## Bookmark Coverage

- `list-bookmarks`
- `create-bookmark`
- `update-bookmark`
- `delete-bookmarks`

## Commands

- List homepages:
  - `pwsh -File .\scripts\dolphin-anty.ps1 -Command list-homepages`
- Create homepages:
  - `pwsh -File .\scripts\dolphin-anty.ps1 -Command create-homepages -Json '{"items":[{"title":"Main","url":"https://example.com"}]}'`
- Update homepage:
  - `pwsh -File .\scripts\dolphin-anty.ps1 -Command update-homepage -HomepageId "<id>" -Json '{"title":"New"}'`
- Delete homepages:
  - `pwsh -File .\scripts\dolphin-anty.ps1 -Command delete-homepages -Json '{"ids":[1,2]}'`
- List bookmarks:
  - `pwsh -File .\scripts\dolphin-anty.ps1 -Command list-bookmarks`
- Create bookmark:
  - `pwsh -File .\scripts\dolphin-anty.ps1 -Command create-bookmark -Json '{"title":"Docs","url":"https://example.com"}'`
- Update bookmark:
  - `pwsh -File .\scripts\dolphin-anty.ps1 -Command update-bookmark -BookmarkId "<id>" -Json '{"title":"Docs 2"}'`
- Delete bookmarks:
  - `pwsh -File .\scripts\dolphin-anty.ps1 -Command delete-bookmarks -Json '{"ids":[1,2]}'`
