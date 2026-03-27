const { request } = require("./http");
const { addQueryString } = require("./utils");

function createApi(options, resolveTokens) {
  async function cloud(method, pathPart, { query, body } = {}) {
    const token = resolveTokens.resolveApiToken();
    const url = addQueryString(joinEndpoint(options.cloudBase, pathPart), query);
    return request({
      method,
      url,
      headers: {
        Authorization: `Bearer ${token}`,
        Accept: "application/json",
      },
      body,
    });
  }

  async function ensureLocalAuth() {
    if (options.skipLocalAuth) {
      return { skipped: true };
    }
    return request({
      method: "POST",
      url: joinEndpoint(options.localBase, "/auth/login-with-token"),
      body: {
        token: resolveTokens.resolveApiToken(),
      },
    });
  }

  async function local(method, pathPart, { query, body, noAuth = false, raw = false } = {}) {
    if (!noAuth) {
      await ensureLocalAuth();
    }

    const url = addQueryString(joinEndpoint(options.localBase, pathPart), query);
    const headers = {};
    const localSessionToken = resolveTokens.resolveLocalSessionToken();
    if (localSessionToken) {
      headers["X-Anty-Session-Token"] = localSessionToken;
    }

    return request({
      method,
      url,
      headers,
      body,
      raw,
    });
  }

  return {
    cloud,
    ensureLocalAuth,
    local,
  };
}

function joinEndpoint(base, pathPart) {
  const normalizedBase = String(base).replace(/\/+$/, "");
  const normalizedPath = String(pathPart).startsWith("/") ? String(pathPart) : `/${pathPart}`;
  return `${normalizedBase}${normalizedPath}`;
}

module.exports = {
  createApi,
  joinEndpoint,
};
