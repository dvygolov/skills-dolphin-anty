const { buildPayloadFromInput, ensureObjectPayload } = require("../utils");

module.exports = {
  "list-folders": async (ctx) =>
    ctx.api.cloud("GET", "/folders", {
      query: {
        query: ctx.options.query,
      },
    }),

  "create-folder": async (ctx) => {
    const payload = buildPayloadFromInput(ctx.options);
    ensureObjectPayload(payload, "Provide folder data via --json and/or --set key=value.");
    const create = await ctx.api.cloud("POST", "/folders", { body: payload });
    return { create, sent: payload };
  },

  "get-folder": async (ctx) => {
    const folderId = await ctx.resolveFolderIdValue();
    return ctx.api.cloud("GET", `/folders/${folderId}`);
  },

  "update-folder": async (ctx) => {
    const folderId = await ctx.resolveFolderIdValue();
    const payload = buildPayloadFromInput(ctx.options);
    ensureObjectPayload(payload, "Provide folder update data via --json and/or --set key=value.");
    const update = await ctx.api.cloud("PATCH", `/folders/${folderId}`, { body: payload });
    return { folder_id: folderId, update, sent: payload };
  },

  "delete-folder": async (ctx) => {
    const folderId = await ctx.resolveFolderIdValue();
    const del = await ctx.api.cloud("DELETE", `/folders/${folderId}`);
    return { folder_id: folderId, delete: del };
  },

  "reorder-folders": async (ctx) => {
    const payload = buildPayloadFromInput(ctx.options);
    ensureObjectPayload(payload, "Provide folders order payload via --json and/or --set key=value.");
    const reorder = await ctx.api.cloud("PUT", "/folders/order", { body: payload });
    return { reorder, sent: payload };
  },

  "attach-profiles-to-folder": async (ctx) => {
    const payload = buildPayloadFromInput(ctx.options);
    ensureObjectPayload(payload, "Provide attach payload via --json and/or --set key=value.");
    const attach = await ctx.api.cloud("POST", "/folders/mass/attach-profiles", { body: payload });
    return { attach, sent: payload };
  },

  "detach-profiles-from-folders": async (ctx) => {
    const payload = buildPayloadFromInput(ctx.options);
    ensureObjectPayload(payload, "Provide detach payload via --json and/or --set key=value.");
    const detach = await ctx.api.cloud("DELETE", "/folders/mass/detach-profiles", { body: payload });
    return { detach, sent: payload };
  },

  "list-folder-profile-ids": async (ctx) => {
    const folderId = await ctx.resolveFolderIdValue();
    return ctx.api.cloud("GET", `/folders/${folderId}/profile-ids`);
  },
};
