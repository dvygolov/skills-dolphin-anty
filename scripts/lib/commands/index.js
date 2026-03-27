const browserProfiles = require("./browser-profiles");
const cookiesLocalStorage = require("./cookies-local-storage");
const extensions = require("./extensions");
const folders = require("./folders");
const homepagesBookmarks = require("./homepages-bookmarks");
const localBrowser = require("./local-browser");
const profileStatuses = require("./profile-statuses");
const proxies = require("./proxies");
const raw = require("./raw");
const teamUsers = require("./team-users");

const handlers = {
  ...browserProfiles,
  ...cookiesLocalStorage,
  ...extensions,
  ...folders,
  ...homepagesBookmarks,
  ...localBrowser,
  ...profileStatuses,
  ...proxies,
  ...raw,
  ...teamUsers,
};

async function dispatchCommand(ctx) {
  const handler = handlers[ctx.options.command];
  if (!handler) {
    throw new Error(`Unsupported command: ${ctx.options.command}`);
  }
  return handler(ctx);
}

module.exports = {
  dispatchCommand,
  handlers,
};
