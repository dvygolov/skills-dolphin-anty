---
name: dolphin-anty-public
description: Manage Dolphin Anty browser profiles, proxies, local API, cloud API, and portable OpenAPI-to-CLI access from a shareable Windows skill folder. Use when starting or stopping profiles, opening URLs in profiles, creating or editing profiles, sharing profile access, changing profile statuses, listing or assigning proxies, checking or rotating proxy IPs, running raw Dolphin API requests with token auth, or bootstrapping portable OCLI access on a new machine.
---

# Dolphin Anty Public

Use deterministic scripts from `scripts/` instead of composing raw HTTP manually.

## Privacy Rules

- Read API token only at runtime from `dolphin-anty-api-token.txt`, `DOLPHIN_ANTY_TOKEN`, or existing local runtime config.
- Never print, commit, or rewrite real token values in chat, skill files, or references.
- Treat `.runtime/` as machine-local generated state and do not publish it.
- Do not publish Dolphin app logs, config dumps, or local profile state from `%APPDATA%\dolphin_anty`.

## Main Tools

- `scripts/dolphin-anty.ps1`
  Main wrapper for browser profiles, profile statuses, proxies, local API, and raw cloud/local requests.
- `scripts/get-local-session-token.ps1`
  Recover and cache `LocalSessionToken` for protected local endpoints.
- `scripts/dolphin-ocli.cmd`
  Portable `openapi-to-cli` wrapper.
- `scripts/bootstrap.ps1`
  Prepare isolated portable runtime for OCLI.

## Table Of Contents

Open only the section that matches the task:

1. Browser profiles CRUD, bulk ops, access sharing:
   `references/browser-profiles.md`
2. Browser profile statuses:
   `references/profile-statuses.md`
3. Proxies and proxy checks:
   `references/proxies.md`
4. Local API, running profiles, start/stop, open-url:
   `references/local-api.md`
5. LocalSessionToken recovery and cache behavior:
   `references/local-session-token.md`
6. Folders and profile grouping:
   `references/folders.md`
7. Extensions:
   `references/extensions.md`
8. Homepages and bookmarks:
   `references/homepages-bookmarks.md`
9. Team users:
   `references/team-users.md`
10. Cookies and Local Storage:
   `references/cookies-local-storage.md`
11. Portable OCLI and runtime bootstrap:
   `references/portable-ocli.md`
12. Exact schema or endpoint lookup:
   `references/dolphinanty-public-api.json`

## Workflow

1. Identify the domain: profiles, statuses, folders, proxies, extensions, homepages/bookmarks, team users, local API, cookies/local storage, or OCLI.
2. Read only the matching reference file from the table above.
3. Use `scripts/dolphin-anty.ps1` unless the task explicitly needs portable OCLI.
4. Use `raw-cloud`, `raw-local`, or `dolphin-ocli.cmd` only when no explicit wrapper command exists yet.

## Token Rules

- External API token is enough for cloud API operations and unprotected local API calls.
- Protected local endpoints require `LocalSessionToken`.
- Before a protected local call, run `scripts/get-local-session-token.ps1` if no cached token exists.
- `dolphin-anty.ps1` auto-loads `LocalSessionToken` from:
  1. `-LocalSessionToken`
  2. `DOLPHIN_ANTY_LOCAL_SESSION_TOKEN`
  3. `.runtime\local-session-token.txt`

## Reliability Rules

- Authenticate local calls through `POST /v1.0/auth/login-with-token`.
- Prefer explicit wrapper commands over raw requests.
- For bulk or complex payloads, prefer `-Json` over many `-Set` fragments.
- If protected local calls start failing with `invalid session token`, refresh the cache with `scripts/get-local-session-token.ps1`.
- Keep outputs minimal and avoid returning secrets, proxy credentials, or full raw payloads unless the user explicitly needs them.
