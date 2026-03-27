const fs = require("fs");
const path = require("path");
const { getLocalSessionTokenFilePath, getTokenFilePath, ensureDir } = require("./paths");
const { parseTokenFromText } = require("./utils");

function resolveApiToken(options = {}) {
  if (options.token && String(options.token).trim()) {
    return String(options.token).trim();
  }
  if (process.env.DOLPHIN_ANTY_TOKEN && String(process.env.DOLPHIN_ANTY_TOKEN).trim()) {
    return String(process.env.DOLPHIN_ANTY_TOKEN).trim();
  }

  const tokenFile = options.tokenFile || getTokenFilePath();
  if (!fs.existsSync(tokenFile)) {
    throw new Error(`Token file not found: ${tokenFile}`);
  }
  return parseTokenFromText(fs.readFileSync(tokenFile, "utf8"));
}

function resolveLocalSessionToken(options = {}) {
  if (options.localSessionToken && String(options.localSessionToken).trim()) {
    return String(options.localSessionToken).trim();
  }
  if (process.env.DOLPHIN_ANTY_LOCAL_SESSION_TOKEN && String(process.env.DOLPHIN_ANTY_LOCAL_SESSION_TOKEN).trim()) {
    return String(process.env.DOLPHIN_ANTY_LOCAL_SESSION_TOKEN).trim();
  }

  const tokenFile = options.localSessionTokenFile || getLocalSessionTokenFilePath();
  if (!fs.existsSync(tokenFile)) {
    return null;
  }

  try {
    return parseTokenFromText(fs.readFileSync(tokenFile, "utf8"));
  } catch {
    return null;
  }
}

function writeLocalSessionToken(token, outputFile) {
  const target = outputFile || getLocalSessionTokenFilePath();
  ensureDir(path.dirname(target));
  fs.writeFileSync(target, token, "utf8");
  return target;
}

module.exports = {
  resolveApiToken,
  resolveLocalSessionToken,
  writeLocalSessionToken,
};
