const { request } = require("../http");
const {
  buildPayloadFromInput,
  ensureObjectPayload,
  resolveAutomationPort,
} = require("../utils");

async function startProfileInternal(ctx, profileId) {
  const query = {
    automation: ctx.options.automation,
  };
  if (ctx.options.headless) {
    query.headless = 1;
  }
  return ctx.api.local("GET", `/browser_profiles/${profileId}/start`, { query });
}

async function setProfileProxyInternal(ctx, profileId, proxyId) {
  const attempts = [
    { proxy: { id: proxyId } },
    { proxy_id: proxyId },
  ];
  const errors = [];

  for (const payload of attempts) {
    try {
      const update = await ctx.api.cloud("PATCH", `/browser_profiles/${profileId}`, { body: payload });
      return { update, sent: payload };
    } catch (error) {
      errors.push(error.message);
    }
  }

  throw new Error(`Failed to assign proxy to profile. Attempts: ${errors.join(" | ")}`);
}

module.exports = {
  "list-profiles": async (ctx) =>
    ctx.api.cloud("GET", "/browser_profiles", {
      query: {
        page: ctx.options.page,
        limit: ctx.options.limit,
        query: ctx.options.query,
        sortBy: ctx.options.sortBy,
        order: ctx.options.order,
        ids: ctx.options.ids?.length ? ctx.options.ids.join(",") : null,
      },
    }),

  "create-profile": async (ctx) => {
    const payload = buildPayloadFromInput(ctx.options);
    ensureObjectPayload(payload, "Provide profile data via --json and/or --set key=value.");
    const create = await ctx.api.cloud("POST", "/browser_profiles", { body: payload });
    return { create, sent: payload };
  },

  "get-profile": async (ctx) => {
    const profileId = await ctx.resolveProfileIdValue();
    return ctx.api.cloud("GET", `/browser_profiles/${profileId}`);
  },

  "delete-profile": async (ctx) => {
    const profileId = await ctx.resolveProfileIdValue();
    const del = await ctx.api.cloud("DELETE", `/browser_profiles/${profileId}`);
    return { profile_id: profileId, delete: del };
  },

  "bulk-delete-profiles": async (ctx) => {
    const payload = buildPayloadFromInput(ctx.options);
    ensureObjectPayload(payload, "Provide bulk delete payload via --json and/or --set key=value.");
    const del = await ctx.api.cloud("DELETE", "/browser_profiles", { body: payload });
    return { delete: del, sent: payload };
  },

  "bulk-create-profiles": async (ctx) => {
    const payload = buildPayloadFromInput(ctx.options);
    ensureObjectPayload(payload, "Provide bulk create payload via --json and/or --set key=value.");
    const create = await ctx.api.cloud("POST", "/browser_profiles/mass", { body: payload });
    return { create, sent: payload };
  },

  "transfer-profiles": async (ctx) => {
    const payload = buildPayloadFromInput(ctx.options);
    ensureObjectPayload(payload, "Provide transfer payload via --json and/or --set key=value.");
    const transfer = await ctx.api.cloud("POST", "/browser_profiles/transfer", { body: payload });
    return { transfer, sent: payload };
  },

  "share-profile-access": async (ctx) => {
    const profileId = await ctx.resolveProfileIdValue();
    const payload = buildPayloadFromInput(ctx.options);
    ensureObjectPayload(payload, "Provide access payload via --json and/or --set key=value.");
    const access = await ctx.api.cloud("PATCH", `/browser_profiles/${profileId}/access`, { body: payload });
    return { profile_id: profileId, access, sent: payload };
  },

  "share-profiles-access": async (ctx) => {
    const payload = buildPayloadFromInput(ctx.options);
    ensureObjectPayload(payload, "Provide multi-profile access payload via --json and/or --set key=value.");
    const access = await ctx.api.cloud("POST", "/browser_profiles/access", { body: payload });
    return { access, sent: payload };
  },

  "update-profile": async (ctx) => {
    const profileId = await ctx.resolveProfileIdValue();
    const payload = buildPayloadFromInput(ctx.options);
    ensureObjectPayload(payload, "Provide update data via --json and/or --set key=value.");
    const update = await ctx.api.cloud("PATCH", `/browser_profiles/${profileId}`, { body: payload });
    return { profile_id: profileId, update, sent: payload };
  },

  "start-profile": async (ctx) => {
    const profileId = await ctx.resolveProfileIdValue();
    const start = await startProfileInternal(ctx, profileId);
    return {
      profile_id: profileId,
      start,
      port: resolveAutomationPort(start),
    };
  },

  "stop-profile": async (ctx) => {
    const profileId = await ctx.resolveProfileIdValue();
    const stop = await ctx.api.local("GET", `/browser_profiles/${profileId}/stop`);
    return {
      profile_id: profileId,
      stop,
    };
  },

  "assign-proxy-to-profile": async (ctx) => {
    const profileId = await ctx.resolveProfileIdValue();
    const proxyId = await ctx.resolveProxyIdValue();
    const assign = await setProfileProxyInternal(ctx, profileId, proxyId);
    return {
      profile_id: profileId,
      proxy_id: proxyId,
      assign: assign.update,
      sent: assign.sent,
    };
  },

  "change-profile-proxy-ip": async (ctx) => {
    const profileId = await ctx.resolveProfileIdValue();
    const change = await ctx.api.local("GET", `/browser_profiles/${profileId}/change_proxy_ip`);
    return {
      profile_id: profileId,
      change,
    };
  },

  "open-url": async (ctx) => {
    if (!ctx.options.url) {
      throw new Error("Specify --url for open-url.");
    }

    const profileId = await ctx.resolveProfileIdValue();
    let effectivePort = ctx.options.port;
    let started = null;

    if (!effectivePort) {
      started = await startProfileInternal(ctx, profileId);
      effectivePort = resolveAutomationPort(started);
    }
    if (!effectivePort) {
      throw new Error("Unable to resolve automation/debugging port. Pass --port explicitly.");
    }

    const endpoint = `http://127.0.0.1:${effectivePort}/json/new?${encodeURIComponent(ctx.options.url)}`;

    let opened = null;
    let lastError = null;
    for (const method of ["PUT", "POST", "GET"]) {
      try {
        const value = await request({
          method,
          url: endpoint,
          raw: true,
        });
        try {
          opened = { method, value: JSON.parse(value) };
        } catch {
          opened = { method, value };
        }
        break;
      } catch (error) {
        lastError = error;
      }
    }

    if (!opened) {
      throw new Error(`Failed to open URL on debug endpoint. Last error: ${lastError?.message || "unknown error"}`);
    }

    return {
      profile_id: profileId,
      debugging_port: effectivePort,
      started,
      opened,
    };
  },
};
