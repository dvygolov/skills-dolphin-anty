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

# skills-dolphin-anty

Public Dolphin Anty skill for AI agents working on Windows platform

## What It Can Do

- manage browser profiles: list, create, update, delete, bulk ops, transfer, access sharing
- manage profile statuses
- manage proxies and run proxy checks through local API
- work with local Dolphin API: running profiles, start, stop, open URL
- manage folders, extensions, homepages, bookmarks, and team users
- import/export cookies and local storage
- use portable OpenAPI-to-CLI workflow

## Structure

- `SKILL.md` is a short index for gradual discovery
- `references/*.md` are split by domain to keep context small
- `scripts/` contains deterministic PowerShell wrappers

## Notes

- this repo is public-safe: no API tokens, no `.runtime`, no machine-local artifacts
- for protected local API operations, recover `LocalSessionToken` with `scripts/get-local-session-token.ps1`
