#!/usr/bin/env node
const fs = require("fs");
const path = require("path");
const { spawnSync } = require("child_process");
const {
  ensureDir,
  getBundledSpecPath,
  getOcliConfigDir,
  getOcliRuntimeDir,
  getOcliSpecsDir,
  getOcliToolsDir,
  getOcliWorkspaceDir,
} = require("./lib/paths");
const { resolveApiToken } = require("./lib/tokens");
const { safeJsonStringify, sanitizeOutput } = require("./lib/utils");

function run(command, args, options = {}) {
  const result = spawnSync(command, args, {
    stdio: "pipe",
    encoding: "utf8",
    ...options,
  });
  if (result.error) {
    throw result.error;
  }
  if (result.status !== 0) {
    throw new Error(result.stderr || result.stdout || `${command} failed with exit code ${result.status}`);
  }
}

function parseArgs(argv) {
  const options = {};
  for (let index = 0; index < argv.length; index += 1) {
    const raw = argv[index];
    if (!raw.startsWith("-")) {
      continue;
    }
    const normalized = raw.replace(/^-+/, "").toLowerCase();
    const next = argv[index + 1];
    if (next === undefined || next.startsWith("-")) {
      throw new Error(`Missing value for ${raw}`);
    }
    if (normalized === "runtime-dir" || normalized === "runtimedir") {
      options.runtimeDir = next;
    }
    if (normalized === "token-file" || normalized === "tokenfile") {
      options.tokenFile = next;
    }
    index += 1;
  }
  return options;
}

function main() {
  const options = parseArgs(process.argv.slice(2));
  const runtimeDir = options.runtimeDir || getOcliRuntimeDir();
  const toolDir = getOcliToolsDir();
  const workspaceDir = getOcliWorkspaceDir();
  const ocliDir = getOcliConfigDir();
  const specsDir = getOcliSpecsDir();
  const bundledSpec = getBundledSpecPath();
  const localCache = path.join(specsDir, "dolphin-local.json");
  const cloudCache = path.join(specsDir, "dolphin-cloud-v1.json");
  const profilesIni = path.join(ocliDir, "profiles.ini");
  const currentFile = path.join(ocliDir, "current");
  const ocliExecutable = path.join(toolDir, "node_modules", ".bin", process.platform === "win32" ? "ocli.cmd" : "ocli");

  if (!fs.existsSync(bundledSpec)) {
    throw new Error(`Bundled spec not found: ${bundledSpec}`);
  }

  const token = resolveApiToken({ tokenFile: options.tokenFile });

  ensureDir(runtimeDir);
  ensureDir(toolDir);
  ensureDir(specsDir);

  if (!fs.existsSync(ocliExecutable)) {
    const npmCli = path.join(path.dirname(process.execPath), "node_modules", "npm", "bin", "npm-cli.js");
    if (fs.existsSync(npmCli)) {
      run(process.execPath, [npmCli, "install", "--prefix", toolDir, "openapi-to-cli"]);
    } else if (process.platform === "win32") {
      run("npm.cmd", ["install", "--prefix", toolDir, "openapi-to-cli"], { shell: true });
    } else {
      run("npm", ["install", "--prefix", toolDir, "openapi-to-cli"]);
    }
  }

  fs.copyFileSync(bundledSpec, localCache);
  fs.copyFileSync(bundledSpec, cloudCache);

  const safeSource = bundledSpec.replace(/\\/g, "/");
  const profilesContent = [
    "[dolphin-local]",
    "api_base_url=http://localhost:3001",
    "api_basic_auth=",
    `api_bearer_token=${token}`,
    `openapi_spec_source=${safeSource}`,
    `openapi_spec_cache=${localCache}`,
    "include_endpoints=",
    "exclude_endpoints=",
    "",
    "[dolphin-cloud-v1]",
    "api_base_url=https://anty-api.com",
    "api_basic_auth=",
    `api_bearer_token=${token}`,
    `openapi_spec_source=${safeSource}`,
    `openapi_spec_cache=${cloudCache}`,
    "include_endpoints=",
    "exclude_endpoints=",
    "",
  ].join("\n");

  fs.writeFileSync(profilesIni, profilesContent, "ascii");
  fs.writeFileSync(currentFile, "dolphin-cloud-v1\n", "ascii");

  process.stdout.write(
    `${safeJsonStringify(sanitizeOutput({
      runtime_dir: runtimeDir,
      workspace_dir: workspaceDir,
      ocli_profiles: ["dolphin-local", "dolphin-cloud-v1"],
    }))}\n`
  );
}

try {
  main();
} catch (error) {
  process.stderr.write(`${error.message || String(error)}\n`);
  process.exit(1);
}
