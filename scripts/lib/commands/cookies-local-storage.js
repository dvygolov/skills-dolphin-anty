const { buildPayloadFromInput, ensureObjectPayload } = require("../utils");

module.exports = {
  "export-local-storage": async (ctx) => {
    const profileId = await ctx.resolveProfileIdValue();
    const payload = buildPayloadFromInput(ctx.options);
    ensureObjectPayload(payload, "Provide export-local-storage payload via --json with at least transfer and plan.");
    if (!Object.prototype.hasOwnProperty.call(payload, "transfer") || !Object.prototype.hasOwnProperty.call(payload, "plan")) {
      throw new Error("export-local-storage requires transfer and plan in --json.");
    }
    return ctx.api.local("POST", `/local-storage/export/${profileId}`, { body: payload });
  },

  "export-local-storage-mass": async (ctx) => ctx.api.local("GET", "/local-storage/export"),

  "import-local-storage": async (ctx) => {
    const payload = buildPayloadFromInput(ctx.options);
    ensureObjectPayload(payload, "Provide local storage import payload via --json and/or --set key=value.");
    const imported = await ctx.api.local("POST", "/local-storage/import", { body: payload });
    return { import: imported, sent: payload };
  },

  "import-cookies": async (ctx) => {
    const payload = buildPayloadFromInput(ctx.options);
    ensureObjectPayload(payload, "Provide cookies import payload via --json and/or --set key=value.");
    const imported = await ctx.api.local("POST", "/cookies/import", { body: payload });
    return { import: imported, sent: payload };
  },

  "export-cookies": async (ctx) => {
    const payload = buildPayloadFromInput(ctx.options);
    ensureObjectPayload(payload, "Provide cookies export payload via --json and/or --set key=value.");
    const exported = await ctx.api.local("POST", "/export-cookies", { body: payload });
    return { export: exported, sent: payload };
  },

  "run-cookie-robot": async (ctx) => {
    const profileId = await ctx.resolveProfileIdValue();
    const payload = buildPayloadFromInput(ctx.options);
    ensureObjectPayload(payload, "Provide cookie robot payload via --json and/or --set key=value.");
    const robot = await ctx.api.local("POST", `/import/cookies/${profileId}/robot`, { body: payload });
    return { profile_id: profileId, robot, sent: payload };
  },

  "stop-cookie-robot": async (ctx) => {
    const profileId = await ctx.resolveProfileIdValue();
    const stop = await ctx.api.local("GET", `/import/cookies/${profileId}/robot-stop`);
    return { profile_id: profileId, stop };
  },
};
