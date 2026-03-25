# Extensions

## Contents

1. Coverage
2. Commands
3. Notes

## Coverage

Extension coverage in `scripts/dolphin-anty.ps1`:

- `list-extensions`
- `create-extension`
- `delete-extensions`
- `upload-extension-zip`

## Commands

- List extensions:
  - `pwsh -File .\scripts\dolphin-anty.ps1 -Command list-extensions -Query "meta"`
- Add from Chrome Web Store link:
  - `pwsh -File .\scripts\dolphin-anty.ps1 -Command create-extension -Json '{"url":"https://chromewebstore.google.com/detail/..."}'`
- Delete extensions:
  - `pwsh -File .\scripts\dolphin-anty.ps1 -Command delete-extensions -Json '{"ids":[1,2]}'`
- Upload zipped extension:
  - `pwsh -File .\scripts\dolphin-anty.ps1 -Command upload-extension-zip -FilePath "D:\Downloads\ext.zip"`

## Notes

- ZIP upload is multipart and therefore has a dedicated command
- For exact request schema, open `references/dolphinanty-public-api.json`
