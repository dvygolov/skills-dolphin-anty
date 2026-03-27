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
  - `node ./scripts/dolphin-anty.js --command list-homepages`
- Create homepages:
  - `node ./scripts/dolphin-anty.js --command create-homepages -Json '{"items":[{"title":"Main","url":"https://example.com"}]}'`
- Update homepage:
  - `node ./scripts/dolphin-anty.js --command update-homepage -HomepageId "<id>" -Json '{"title":"New"}'`
- Delete homepages:
  - `node ./scripts/dolphin-anty.js --command delete-homepages -Json '{"ids":[1,2]}'`
- List bookmarks:
  - `node ./scripts/dolphin-anty.js --command list-bookmarks`
- Create bookmark:
  - `node ./scripts/dolphin-anty.js --command create-bookmark -Json '{"title":"Docs","url":"https://example.com"}'`
- Update bookmark:
  - `node ./scripts/dolphin-anty.js --command update-bookmark -BookmarkId "<id>" -Json '{"title":"Docs 2"}'`
- Delete bookmarks:
  - `node ./scripts/dolphin-anty.js --command delete-bookmarks -Json '{"ids":[1,2]}'`

