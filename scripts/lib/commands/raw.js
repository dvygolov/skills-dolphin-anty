const { parseJsonObject } = require("../utils");

module.exports = {
  "raw-cloud": async (ctx) => {
    if (!ctx.options.path) {
      throw new Error("Specify --path for raw-cloud.");
    }
    const body = ctx.options.json ? parseJsonObject(ctx.options.json) : undefined;
    return ctx.api.cloud(ctx.options.method, ctx.options.path, { body });
  },

  "raw-local": async (ctx) => {
    if (!ctx.options.path) {
      throw new Error("Specify --path for raw-local.");
    }
    const body = ctx.options.json ? parseJsonObject(ctx.options.json) : undefined;
    return ctx.api.local(ctx.options.method, ctx.options.path, { body });
  },
};
