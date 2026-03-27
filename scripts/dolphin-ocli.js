#!/usr/bin/env node
const fs = require("fs");
const path = require("path");
const { spawnSync } = require("child_process");
const { getOcliConfigDir, getOcliToolsDir, getOcliWorkspaceDir } = require("./lib/paths");
const { maskSensitiveText, safeJsonStringify, sanitizeOutput } = require("./lib/utils");

function getOcliExecutable() {
  const binName = process.platform === "win32" ? "ocli.cmd" : "ocli";
  return path.join(getOcliToolsDir(), "node_modules", ".bin", binName);
}

function getDolphinTokenFromProfiles(profilesIni) {
  if (!fs.existsSync(profilesIni)) {
    return null;
  }
  const content = fs.readFileSync(profilesIni, "utf8");
  const matched = content.match(/^api_bearer_token=(.+)$/m);
  return matched ? matched[1].trim() : null;
}

function bootstrapIfNeeded() {
  const bootstrapPath = path.join(__dirname, "bootstrap.js");
  const result = spawnSync(process.execPath, [bootstrapPath], {
    stdio: "pipe",
    encoding: "utf8",
  });
  if (result.status !== 0) {
    throw new Error(result.stderr || result.stdout || "bootstrap failed");
  }
}

function quoteForShell(value) {
  if (/^[A-Za-z0-9_./:=+-]+$/.test(value)) {
    return value;
  }
  return `"${String(value).replace(/"/g, '\\"')}"`;
}

function runOcli(ocli, args, options = {}) {
  if (process.platform === "win32") {
    const command = [quoteForShell(ocli), ...args.map(quoteForShell)].join(" ");
    return spawnSync(command, {
      shell: true,
      ...options,
    });
  }

  return spawnSync(ocli, args, options);
}

function main() {
  const args = process.argv.slice(2);
  if (!args.length) {
    throw new Error("Usage: node ./scripts/dolphin-ocli.js <command> [args...]");
  }

  let command = args[0];
  let forwardArgs = args.slice(1);

  bootstrapIfNeeded();

  const ocli = getOcliExecutable();
  if (!fs.existsSync(ocli)) {
    throw new Error(`ocli executable not found after bootstrap: ${ocli}`);
  }

  const profilesIni = path.join(getOcliConfigDir(), "profiles.ini");
  const workspaceDir = getOcliWorkspaceDir();
  const token = process.env.DOLPHIN_ANTY_TOKEN || getDolphinTokenFromProfiles(profilesIni);

  const profile = command.startsWith("v1.0_") || command === "login-local" ? "dolphin-local" : "dolphin-cloud-v1";
  if (command === "login-local") {
    if (!token) {
      throw new Error("Dolphin token not found. Put it into dolphin-anty-api-token.txt or set DOLPHIN_ANTY_TOKEN.");
    }
    command = "v1.0_auth_login-with-token";
    forwardArgs = ["--token", token];
  }

  const useResult = runOcli(ocli, ["use", profile], {
    cwd: workspaceDir,
    stdio: "pipe",
    encoding: "utf8",
  });
  if (useResult.status !== 0) {
    throw new Error(useResult.stderr || useResult.stdout || "ocli use failed");
  }

  const runResult = runOcli(ocli, [command, ...forwardArgs], {
    cwd: workspaceDir,
    stdio: "pipe",
    encoding: "utf8",
  });
  if (runResult.stdout) {
    const stdout = String(runResult.stdout);
    try {
      process.stdout.write(`${safeJsonStringify(sanitizeOutput(JSON.parse(stdout)))}\n`);
    } catch {
      process.stdout.write(`${maskSensitiveText(stdout)}${stdout.endsWith("\n") ? "" : "\n"}`);
    }
  }
  if (runResult.stderr) {
    process.stderr.write(maskSensitiveText(String(runResult.stderr)));
  }
  process.exit(runResult.status ?? 0);
}

try {
  main();
} catch (error) {
  process.stderr.write(`${maskSensitiveText(error.message || String(error))}\n`);
  process.exit(1);
}
