function getPlatform() {
  return process.platform;
}

function isWindows() {
  return getPlatform() === "win32";
}

function isMac() {
  return getPlatform() === "darwin";
}

function isLinux() {
  return getPlatform() === "linux";
}

module.exports = {
  getPlatform,
  isLinux,
  isMac,
  isWindows,
};
