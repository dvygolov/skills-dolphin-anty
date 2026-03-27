#!/usr/bin/env node
const { createApi } = require("./lib/api");
const { recoverLocalSessionToken } = require("./lib/local-session-token");
const {
  getLocalSessionTokenFilePath,
  getSessionStorageDir,
  getTokenFilePath,
} = require("./lib/paths");
const { resolveApiToken, writeLocalSessionToken } = require("./lib/tokens");
const { maskSensitiveText, safeJsonStringify, sanitizeOutput } = require("./lib/utils");

function parseArgs(argv) {
  const options = {
    localBase: "http://127.0.0.1:3001/v1.0",
    outputFile: getLocalSessionTokenFilePath(),
    sessionStorageDir: getSessionStorageDir(),
    skipValidation: false,
    tokenFile: getTokenFilePath(),
  };

  const aliases = {
    localbase: "localBase",
    "local-base": "localBase",
    outputfile: "outputFile",
    "output-file": "outputFile",
    sessionstoragedir: "sessionStorageDir",
    "session-storage-dir": "sessionStorageDir",
    skipvalidation: "skipValidation",
    "skip-validation": "skipValidation",
    token: "token",
    tokenfile: "tokenFile",
    "token-file": "tokenFile",
  };

  for (let index = 0; index < argv.length; index += 1) {
    const raw = argv[index];
    if (!raw.startsWith("-")) {
      continue;
    }

    const normalized = raw.replace(/^-+/, "").toLowerCase();
    const key = aliases[normalized];
    if (!key) {
      throw new Error(`Unknown argument: ${raw}`);
    }
    if (key === "skipValidation") {
      options.skipValidation = true;
      continue;
    }

    const next = argv[index + 1];
    if (next === undefined || next.startsWith("-")) {
      throw new Error(`Missing value for ${raw}`);
    }
    options[key] = next;
    index += 1;
  }

  return options;
}

async function main() {
  const options = parseArgs(process.argv.slice(2));
  const apiFactory = (overrides = {}) =>
    createApi(
      {
        cloudBase: "https://anty-api.com",
        localBase: options.localBase,
        skipLocalAuth: false,
      },
      {
        resolveApiToken: () => resolveApiToken(options),
        resolveLocalSessionToken: () => overrides.localSessionToken || null,
      }
    );

  const result = await recoverLocalSessionToken({
    apiFactory,
    options,
    writeLocalSessionToken,
  });

  process.stdout.write(`${safeJsonStringify(sanitizeOutput(result))}\n`);
}

main().catch((error) => {
  process.stderr.write(`${maskSensitiveText(error.message || String(error))}\n`);
  process.exit(1);
});
