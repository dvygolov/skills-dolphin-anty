const { createApi } = require("./api");
const {
  resolveBookmarkIdValue,
  resolveFolderIdValue,
  resolveHomepageIdValue,
  resolveProfileIdValue,
  resolveProxyIdValue,
  resolveTeamUserIdValue,
} = require("./ids");
const { resolveApiToken, resolveLocalSessionToken } = require("./tokens");

function createContext(options) {
  const tokenResolvers = {
    resolveApiToken: () => resolveApiToken(options),
    resolveLocalSessionToken: () => resolveLocalSessionToken(options),
  };

  const api = createApi(options, tokenResolvers);

  return {
    api,
    options,
    resolveApiToken: tokenResolvers.resolveApiToken,
    resolveLocalSessionToken: tokenResolvers.resolveLocalSessionToken,
    resolveBookmarkIdValue: () => resolveBookmarkIdValue({ api, options }),
    resolveFolderIdValue: () => resolveFolderIdValue({ api, options }),
    resolveHomepageIdValue: () => resolveHomepageIdValue({ api, options }),
    resolveProfileIdValue: () => resolveProfileIdValue({ api, options }),
    resolveProxyIdValue: () => resolveProxyIdValue({ api, options }),
    resolveTeamUserIdValue: () => resolveTeamUserIdValue({ api, options }),
  };
}

module.exports = {
  createContext,
};
