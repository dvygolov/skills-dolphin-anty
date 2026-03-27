const { buildPayloadFromInput, ensureObjectPayload } = require("../utils");

module.exports = {
  "list-homepages": async (ctx) =>
    ctx.api.cloud("GET", "/homepages", {
      query: {
        limit: ctx.options.limit,
        query: ctx.options.query,
      },
    }),

  "create-homepages": async (ctx) => {
    const payload = buildPayloadFromInput(ctx.options);
    ensureObjectPayload(payload, "Provide homepage payload via --json and/or --set key=value.");
    const create = await ctx.api.cloud("POST", "/homepages", { body: payload });
    return { create, sent: payload };
  },

  "update-homepage": async (ctx) => {
    if (!ctx.options.homepageId) {
      throw new Error("Specify --homepage-id for update-homepage.");
    }
    const payload = buildPayloadFromInput(ctx.options);
    ensureObjectPayload(payload, "Provide homepage update payload via --json and/or --set key=value.");
    const update = await ctx.api.cloud("PATCH", `/homepages/${ctx.options.homepageId}`, { body: payload });
    return { homepage_id: ctx.options.homepageId, update, sent: payload };
  },

  "delete-homepages": async (ctx) => {
    const payload = buildPayloadFromInput(ctx.options);
    ensureObjectPayload(payload, "Provide homepage delete payload via --json and/or --set key=value.");
    const del = await ctx.api.cloud("DELETE", "/homepages", { body: payload });
    return { delete: del, sent: payload };
  },

  "list-bookmarks": async (ctx) =>
    ctx.api.cloud("GET", "/bookmarks", {
      query: {
        limit: ctx.options.limit,
        query: ctx.options.query,
      },
    }),

  "create-bookmark": async (ctx) => {
    const payload = buildPayloadFromInput(ctx.options);
    ensureObjectPayload(payload, "Provide bookmark payload via --json and/or --set key=value.");
    const create = await ctx.api.cloud("POST", "/bookmarks", { body: payload });
    return { create, sent: payload };
  },

  "update-bookmark": async (ctx) => {
    if (!ctx.options.bookmarkId) {
      throw new Error("Specify --bookmark-id for update-bookmark.");
    }
    const payload = buildPayloadFromInput(ctx.options);
    ensureObjectPayload(payload, "Provide bookmark update payload via --json and/or --set key=value.");
    const update = await ctx.api.cloud("PATCH", `/bookmarks/${ctx.options.bookmarkId}`, { body: payload });
    return { bookmark_id: ctx.options.bookmarkId, update, sent: payload };
  },

  "delete-bookmarks": async (ctx) => {
    const payload = buildPayloadFromInput(ctx.options);
    ensureObjectPayload(payload, "Provide bookmark delete payload via --json and/or --set key=value.");
    const del = await ctx.api.cloud("DELETE", "/bookmarks", { body: payload });
    return { delete: del, sent: payload };
  },
};
