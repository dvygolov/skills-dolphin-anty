# Portable OCLI

## Contents

1. When to use it
2. Bootstrap
3. Command routing
4. Debugging

## When To Use It

Use portable OCLI when:

- a generated API command is easier than adding another wrapper branch
- you need exact endpoint naming from the OpenAPI document
- you need quick access to an endpoint not yet wrapped in `dolphin-anty.js`

Prefer `scripts/dolphin-anty.js` first for common work.

## Bootstrap

- `node ./scripts/bootstrap.js`

This installs local `openapi-to-cli` into `.runtime/tools` and prepares isolated config.

## Command Routing

- `node ./scripts/dolphin-ocli.js browser_profiles_get --limit 5`
- `node ./scripts/dolphin-ocli.js login-local`
- `node ./scripts/dolphin-ocli.js v1.0_browser_profiles_browserProfileId_start --browserProfileId 123`

Wrapper behavior:

- local commands starting with `v1.0_` use `dolphin-local`
- all other generated commands use `dolphin-cloud-v1`

## Debugging

If profile selection or runtime bootstrap is unclear, open:

- `references/portability-notes.md`

