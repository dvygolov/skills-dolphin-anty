# Portability Notes

## Problem

Dolphin Anty publishes cloud and local endpoints in one OpenAPI document.

`openapi-to-cli` binds one `api_base_url` per profile, so one profile cannot safely serve both:

- cloud endpoints like `browser_profiles_get`
- local endpoints like `v1.0_auth_login-with-token`

## Solution

Keep two profiles and switch before each command:

- `dolphin-cloud-v1`
- `dolphin-local`

The wrapper does not rely on `--profile` because some `openapi-to-cli` builds ignore that flag for generated commands.

Instead it:

1. bootstraps a local runtime
2. runs `ocli use <profile>`
3. executes the target command

## Runtime Layout

```text
dolphin-ocli-portable/
  scripts/
  references/
  .runtime/
    tools/
    workspace/
      .ocli/
```

This keeps the machine-specific token and generated runtime outside the skill instructions while still staying inside the copied folder.

