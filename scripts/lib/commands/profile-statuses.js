const { buildPayloadFromInput, ensureObjectPayload } = require("../utils");

module.exports = {
  "list-profile-statuses": async (ctx) =>
    ctx.api.cloud("GET", "/browser_profiles/statuses", {
      query: {
        limit: ctx.options.limit,
        query: ctx.options.query,
      },
    }),

  "get-profile-status": async (ctx) => {
    if (!ctx.options.profileStatusId) {
      throw new Error("Specify --profile-status-id for get-profile-status.");
    }
    return ctx.api.cloud("GET", `/browser_profiles/statuses/${ctx.options.profileStatusId}`);
  },

  "create-profile-status": async (ctx) => {
    const payload = buildPayloadFromInput(ctx.options);
    ensureObjectPayload(payload, "Provide profile status data via --json and/or --set key=value.");
    const create = await ctx.api.cloud("POST", "/browser_profiles/statuses", { body: payload });
    return { create, sent: payload };
  },

  "update-profile-status": async (ctx) => {
    if (!ctx.options.profileStatusId) {
      throw new Error("Specify --profile-status-id for update-profile-status.");
    }
    const payload = buildPayloadFromInput(ctx.options);
    ensureObjectPayload(payload, "Provide profile status update data via --json and/or --set key=value.");
    const update = await ctx.api.cloud("PATCH", `/browser_profiles/statuses/${ctx.options.profileStatusId}`, { body: payload });
    return { profile_status_id: ctx.options.profileStatusId, update, sent: payload };
  },

  "delete-profile-status": async (ctx) => {
    if (!ctx.options.profileStatusId) {
      throw new Error("Specify --profile-status-id for delete-profile-status.");
    }
    const del = await ctx.api.cloud("DELETE", `/browser_profiles/statuses/${ctx.options.profileStatusId}`);
    return { profile_status_id: ctx.options.profileStatusId, delete: del };
  },

  "bulk-delete-profile-statuses": async (ctx) => {
    const payload = buildPayloadFromInput(ctx.options);
    ensureObjectPayload(payload, "Provide bulk delete profile statuses payload via --json and/or --set key=value.");
    const del = await ctx.api.cloud("DELETE", "/browser_profiles/statuses", { body: payload });
    return { delete: del, sent: payload };
  },

  "bulk-change-profile-statuses": async (ctx) => {
    const payload = buildPayloadFromInput(ctx.options);
    ensureObjectPayload(payload, "Provide bulk change profile statuses payload via --json and/or --set key=value.");
    const change = await ctx.api.cloud("PUT", "/browser_profiles/statuses/bulk", { body: payload });
    return { change, sent: payload };
  },
};
