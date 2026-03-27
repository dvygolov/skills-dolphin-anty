#!/usr/bin/env node
const { createContext } = require("./lib/context");
const { dispatchCommand } = require("./lib/commands");
const { buildHelpText } = require("./lib/help");
const { getLocalSessionTokenFilePath, getTokenFilePath } = require("./lib/paths");
const { maskSensitiveText, safeJsonStringify, sanitizeOutput } = require("./lib/utils");

function parseArgs(argv) {
  const options = {
    automation: 1,
    cloudBase: "https://anty-api.com",
    headless: false,
    ids: [],
    limit: 50,
    localBase: "http://127.0.0.1:3001/v1.0",
    localSessionTokenFile: getLocalSessionTokenFilePath(),
    method: "GET",
    page: 1,
    set: [],
    skipLocalAuth: false,
    tokenFile: getTokenFilePath(),
  };

  const aliases = {
    automation: "automation",
    bookmarkid: "bookmarkId",
    "bookmark-id": "bookmarkId",
    changeproviderproxy: "changeProviderProxy",
    "change-provider-proxy": "changeProviderProxy",
    command: "command",
    cloudbase: "cloudBase",
    "cloud-base": "cloudBase",
    filepath: "filePath",
    "file-path": "filePath",
    folderid: "folderId",
    "folder-id": "folderId",
    headless: "headless",
    homepageid: "homepageId",
    "homepage-id": "homepageId",
    ids: "ids",
    json: "json",
    limit: "limit",
    localbase: "localBase",
    "local-base": "localBase",
    localsessiontoken: "localSessionToken",
    "local-session-token": "localSessionToken",
    localsessiontokenfile: "localSessionTokenFile",
    "local-session-token-file": "localSessionTokenFile",
    method: "method",
    order: "order",
    page: "page",
    path: "path",
    port: "port",
    profileid: "profileId",
    "profile-id": "profileId",
    profilename: "profileName",
    "profile-name": "profileName",
    profilestatusid: "profileStatusId",
    "profile-status-id": "profileStatusId",
    proxychangeipurl: "proxyChangeIpUrl",
    "proxy-change-ip-url": "proxyChangeIpUrl",
    proxyhost: "proxyHost",
    "proxy-host": "proxyHost",
    proxyid: "proxyId",
    "proxy-id": "proxyId",
    proxylogin: "proxyLogin",
    "proxy-login": "proxyLogin",
    proxyname: "proxyName",
    "proxy-name": "proxyName",
    proxypassword: "proxyPassword",
    "proxy-password": "proxyPassword",
    proxyport: "proxyPort",
    "proxy-port": "proxyPort",
    proxytype: "proxyType",
    "proxy-type": "proxyType",
    query: "query",
    set: "set",
    skiplocalauth: "skipLocalAuth",
    "skip-local-auth": "skipLocalAuth",
    sortby: "sortBy",
    "sort-by": "sortBy",
    token: "token",
    tokenfile: "tokenFile",
    "token-file": "tokenFile",
    teamuserid: "teamUserId",
    "team-user-id": "teamUserId",
    url: "url",
  };

  const booleanKeys = new Set(["changeProviderProxy", "headless", "skipLocalAuth"]);

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

    if (booleanKeys.has(key)) {
      options[key] = true;
      continue;
    }

    const next = argv[index + 1];
    if (next === undefined || next.startsWith("-")) {
      throw new Error(`Missing value for ${raw}`);
    }

    if (key === "ids") {
      options.ids.push(...next.split(",").map((value) => value.trim()).filter(Boolean));
    } else if (key === "set") {
      options.set.push(next);
    } else {
      options[key] = next;
    }

    index += 1;
  }

  for (const numericKey of ["automation", "limit", "page", "port", "proxyPort"]) {
    if (options[numericKey] !== undefined) {
      const parsed = Number.parseInt(options[numericKey], 10);
      if (!Number.isNaN(parsed)) {
        options[numericKey] = parsed;
      }
    }
  }

  if (options.method) {
    options.method = String(options.method).toUpperCase();
  }

  return options;
}

async function main() {
  const options = parseArgs(process.argv.slice(2));
  if (!options.command || options.command === "help") {
    process.stdout.write(`${buildHelpText()}\n`);
    return;
  }

  const ctx = createContext(options);
  const result = await dispatchCommand(ctx);
  process.stdout.write(`${safeJsonStringify(sanitizeOutput(result))}\n`);
}

main().catch((error) => {
  let message = error?.message || String(error);
  if (/invalid session token/i.test(message)) {
    message = `${message}\nHint: run ./scripts/get-local-session-token.js or provide --local-session-token '<token>' for protected local endpoints.`;
  }
  process.stderr.write(`${maskSensitiveText(message)}\n`);
  process.exit(1);
});
