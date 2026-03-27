const fs = require("fs");
const os = require("os");
const path = require("path");
const { isLinux, isMac, isWindows } = require("./platform");

function getSkillRoot() {
  return path.resolve(__dirname, "..", "..");
}

function getRuntimeDir() {
  return path.join(getSkillRoot(), ".runtime");
}

function getTokenFilePath() {
  return path.join(getSkillRoot(), "dolphin-anty-api-token.txt");
}

function getLocalSessionTokenFilePath() {
  return path.join(getRuntimeDir(), "local-session-token.txt");
}

function getBundledSpecPath() {
  return path.join(getSkillRoot(), "references", "dolphinanty-public-api.json");
}

function ensureDir(dirPath) {
  fs.mkdirSync(dirPath, { recursive: true });
  return dirPath;
}

function findExistingPath(candidates) {
  for (const candidate of candidates) {
    if (candidate && fs.existsSync(candidate)) {
      return candidate;
    }
  }
  return candidates[0] || null;
}

function getDolphinUserDataDir() {
  if (process.env.DOLPHIN_ANTY_USER_DATA_DIR) {
    return process.env.DOLPHIN_ANTY_USER_DATA_DIR;
  }

  const home = os.homedir();
  const appData = process.env.APPDATA;
  const configHome = process.env.XDG_CONFIG_HOME || path.join(home, ".config");
  const localShare = process.env.XDG_DATA_HOME || path.join(home, ".local", "share");

  const candidates = [];
  if (isWindows() && appData) {
    candidates.push(path.join(appData, "dolphin_anty"));
  }
  if (isMac()) {
    candidates.push(path.join(home, "Library", "Application Support", "dolphin_anty"));
    candidates.push(path.join(home, "Library", "Application Support", "Dolphin Anty"));
  }
  if (isLinux()) {
    candidates.push(path.join(configHome, "dolphin_anty"));
    candidates.push(path.join(configHome, "Dolphin Anty"));
    candidates.push(path.join(localShare, "dolphin_anty"));
  }

  return findExistingPath(candidates);
}

function getSessionStorageDir() {
  if (process.env.DOLPHIN_ANTY_SESSION_STORAGE_DIR) {
    return process.env.DOLPHIN_ANTY_SESSION_STORAGE_DIR;
  }
  const userDataDir = getDolphinUserDataDir();
  return userDataDir ? path.join(userDataDir, "Session Storage") : null;
}

function getOcliRuntimeDir() {
  return path.join(getRuntimeDir(), "ocli");
}

function getOcliWorkspaceDir() {
  return path.join(getOcliRuntimeDir(), "workspace");
}

function getOcliConfigDir() {
  return path.join(getOcliWorkspaceDir(), ".ocli");
}

function getOcliToolsDir() {
  return path.join(getOcliRuntimeDir(), "tools");
}

function getOcliSpecsDir() {
  return path.join(getOcliConfigDir(), "specs");
}

module.exports = {
  ensureDir,
  getBundledSpecPath,
  getDolphinUserDataDir,
  getLocalSessionTokenFilePath,
  getOcliConfigDir,
  getOcliRuntimeDir,
  getOcliSpecsDir,
  getOcliToolsDir,
  getOcliWorkspaceDir,
  getRuntimeDir,
  getSessionStorageDir,
  getSkillRoot,
  getTokenFilePath,
};
