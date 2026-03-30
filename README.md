```text
                            Dolphin Anty Skill
    _            __     __  _ _             __          __  _
   | |           \ \   / / | | |            \ \        / / | |
   | |__  _   _   \ \_/ /__| | | _____      _\ \  /\  / /__| |__
   | '_ \| | | |   \   / _ \ | |/ _ \ \ /\ / /\ \/  \/ / _ \ '_ \
   | |_) | |_| |    | |  __/ | | (_) \ V  V /  \  /\  /  __/ |_) |
   |_.__/ \__, |    |_|\___|_|_|\___/ \_/\_/    \/  \/ \___|_.__/
           __/ |
          |___/             https://yellowweb.top
```

# dolphin-anty-public

Public Dolphin Anty skill for AI agents. The skill is now built around a cross-platform Node.js runtime instead of PowerShell-only wrappers.

## What It Can Do

- manage browser profiles: list, create, update, delete, bulk ops, transfer, access sharing
- manage profile statuses
- manage proxies and run live proxy checks through local API
- work with local Dolphin API: running profiles, start, stop, open URL
- manage folders, extensions, homepages, bookmarks, and team users
- import and export cookies and local storage
- recover and cache `LocalSessionToken` for protected local endpoints
- use a portable OpenAPI-to-CLI workflow for endpoints not wrapped explicitly

## Technical Requirements

- `Node.js` 18+ recommended
- `npm` available in the same environment as `node`
- Dolphin Anty API token
- Dolphin Anty desktop app installed and running when you need local API features
- access to the Dolphin user-data directory when you need `LocalSessionToken` recovery

Practical requirements by feature:

- Cloud API only:
  Dolphin API token is enough
- Local API read and control:
  Dolphin Anty must be running locally
- Protected local endpoints such as proxy check:
  Dolphin Anty must be running locally and `LocalSessionToken` must be recovered
- Portable OCLI:
  `node` and `npm` must be available so the isolated runtime can bootstrap `openapi-to-cli`

## Installation

1. Clone the repository.
2. Put your Dolphin API token into `dolphin-anty-api-token.txt` in the skill root, or export `DOLPHIN_ANTY_TOKEN`.
3. If you will use local protected endpoints, run:

```bash
node ./scripts/get-local-session-token.js
```

4. If you will use portable OCLI, run:

```bash
node ./scripts/bootstrap.js
```

The skill stores generated runtime state only in `.runtime/`. That directory is machine-local and intentionally not tracked.

## Quick Start

List profiles:

```bash
node ./scripts/dolphin-anty.js --command list-profiles --limit 50
```

List proxies:

```bash
node ./scripts/dolphin-anty.js --command list-proxies --limit 50
```

Check a proxy through local API:

```bash
node ./scripts/get-local-session-token.js
node ./scripts/dolphin-anty.js --command check-proxy --proxy-id 123456
```

Start a profile and open a page:

```bash
node ./scripts/dolphin-anty.js --command open-url --profile-name "My Profile" --url "https://iphey.com/"
```

Use portable OCLI:

```bash
node ./scripts/bootstrap.js
node ./scripts/dolphin-ocli.js browser_profiles_get --limit 5
```

## Structure

- `SKILL.md` is a short index for gradual discovery
- `references/*.md` are split by domain to keep context small
- `scripts/dolphin-anty.js` is the main wrapper
- `scripts/get-local-session-token.js` recovers the protected local token
- `scripts/dolphin-ocli.js` exposes portable OpenAPI-to-CLI access
- `scripts/lib/` contains the shared runtime and command modules

## Privacy And Publishing

- this repository is public-safe by design: no API tokens, no `.runtime`, no machine-local artifacts
- wrapper outputs mask common secrets such as token, login, password, and email fields
- do not publish Dolphin logs or raw local application state

## Notes

- local API behavior depends on a real running Dolphin Anty instance
- `LocalSessionToken` can expire after Dolphin restart or local session changes
- when protected local commands start failing with `invalid session token`, just run `node ./scripts/get-local-session-token.js` again
