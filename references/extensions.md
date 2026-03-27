# Extensions

## Contents

1. Coverage
2. Commands
3. Notes

## Coverage

Extension coverage in `scripts/dolphin-anty.js`:

- `list-extensions`
- `create-extension`
- `delete-extensions`
- `upload-extension-zip`

## Commands

- List extensions:
  - `node ./scripts/dolphin-anty.js --command list-extensions -Query "meta"`
- Add from Chrome Web Store link:
  - `node ./scripts/dolphin-anty.js --command create-extension -Json '{"url":"https://chromewebstore.google.com/detail/..."}'`
- Delete extensions:
  - `node ./scripts/dolphin-anty.js --command delete-extensions -Json '{"ids":[1,2]}'`
- Upload zipped extension:
  - `node ./scripts/dolphin-anty.js --command upload-extension-zip -FilePath "D:\Downloads\ext.zip"`

## Notes

- ZIP upload is multipart and therefore has a dedicated command
- For exact request schema, open `references/dolphinanty-public-api.json`

