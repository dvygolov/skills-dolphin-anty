const { addProxyFieldsToPayload, buildPayloadFromInput, ensureObjectPayload } = require("../utils");

module.exports = {
  "list-proxies": async (ctx) =>
    ctx.api.cloud("GET", "/proxy", {
      query: {
        page: ctx.options.page,
        limit: ctx.options.limit,
        query: ctx.options.query,
        sortBy: ctx.options.sortBy,
        order: ctx.options.order,
        ids: ctx.options.ids?.length ? ctx.options.ids.join(",") : null,
      },
    }),

  "get-proxy": async (ctx) => {
    const proxyId = await ctx.resolveProxyIdValue();
    return ctx.api.cloud("GET", `/proxy/${proxyId}`);
  },

  "create-proxy": async (ctx) => {
    const payload = buildPayloadFromInput(ctx.options);
    addProxyFieldsToPayload(payload, ctx.options);
    ensureObjectPayload(payload, "Provide proxy data via --json, --set key=value, or typed proxy args.");
    const create = await ctx.api.cloud("POST", "/proxy", { body: payload });
    return { create, sent: payload };
  },

  "update-proxy": async (ctx) => {
    const proxyId = await ctx.resolveProxyIdValue();
    const payload = buildPayloadFromInput(ctx.options);
    addProxyFieldsToPayload(payload, ctx.options);
    ensureObjectPayload(payload, "Provide proxy update data via --json, --set key=value, or typed proxy args.");
    const update = await ctx.api.cloud("PATCH", `/proxy/${proxyId}`, { body: payload });
    return { proxy_id: proxyId, update, sent: payload };
  },

  "delete-proxy": async (ctx) => {
    const proxyId = await ctx.resolveProxyIdValue();
    const del = await ctx.api.cloud("DELETE", `/proxy/${proxyId}`);
    return { proxy_id: proxyId, delete: del };
  },

  "check-proxy": async (ctx) => {
    let resolvedProxyId = null;
    const payload = buildPayloadFromInput(ctx.options);
    addProxyFieldsToPayload(payload, ctx.options);

    const missingRequired = () =>
      !payload.type || !payload.host || !Object.prototype.hasOwnProperty.call(payload, "port");

    if (missingRequired() && (ctx.options.proxyId || ctx.options.proxyName)) {
      resolvedProxyId = await ctx.resolveProxyIdValue();
      const proxyResponse = await ctx.api.cloud("GET", `/proxy/${resolvedProxyId}`);
      const proxyData = proxyResponse?.data || proxyResponse;
      payload.type ||= proxyData.type;
      payload.host ||= proxyData.host;
      if (!Object.prototype.hasOwnProperty.call(payload, "port") && proxyData.port !== undefined) {
        payload.port = proxyData.port;
      }
      payload.login ||= proxyData.login;
      payload.password ||= proxyData.password;
      payload.name ||= proxyData.name;
      payload.changeIpUrl ||= proxyData.changeIpUrl || proxyData.change_ip_url;
    }

    if (missingRequired()) {
      throw new Error("check-proxy requires type/host/port. Pass typed proxy args, --json, or --proxy-id/--proxy-name.");
    }

    const hasLogin = Object.prototype.hasOwnProperty.call(payload, "login");
    const hasPassword = Object.prototype.hasOwnProperty.call(payload, "password");
    if (hasLogin !== hasPassword) {
      throw new Error("Proxy auth requires both login and password for check-proxy.");
    }

    if (ctx.options.changeProviderProxy) {
      payload.changeProviderProxy = true;
      if (resolvedProxyId) {
        payload.id = Number.parseInt(resolvedProxyId, 10);
      }
    }

    const check = await ctx.api.local("POST", "/check/proxy", { body: payload });
    return { proxy_id: resolvedProxyId, check, sent: payload };
  },

  "change-proxy-ip": async (ctx) => {
    const proxyId = await ctx.resolveProxyIdValue();
    const change = await ctx.api.local("GET", `/proxy/${proxyId}/change_proxy_ip`);
    return { proxy_id: proxyId, change };
  },
};
