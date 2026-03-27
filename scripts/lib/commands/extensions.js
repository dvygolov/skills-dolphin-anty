const { multipartUpload } = require("../http");
const { buildPayloadFromInput, ensureObjectPayload } = require("../utils");
const { joinEndpoint } = require("../api");

module.exports = {
  "list-extensions": async (ctx) =>
    ctx.api.cloud("GET", "/extensions", {
      query: {
        limit: ctx.options.limit,
        query: ctx.options.query,
      },
    }),

  "create-extension": async (ctx) => {
    const payload = buildPayloadFromInput(ctx.options);
    ensureObjectPayload(payload, "Provide extension create payload via --json and/or --set key=value.");
    const create = await ctx.api.cloud("POST", "/extensions", { body: payload });
    return { create, sent: payload };
  },

  "delete-extensions": async (ctx) => {
    const payload = buildPayloadFromInput(ctx.options);
    ensureObjectPayload(payload, "Provide extension delete payload via --json and/or --set key=value.");
    const del = await ctx.api.cloud("DELETE", "/extensions", { body: payload });
    return { delete: del, sent: payload };
  },

  "upload-extension-zip": async (ctx) => {
    if (!ctx.options.filePath) {
      throw new Error("Specify --file-path for upload-extension-zip.");
    }
    const upload = await multipartUpload({
      url: joinEndpoint(ctx.options.cloudBase, "/extensions/upload-zipped"),
      headers: {
        Authorization: `Bearer ${ctx.resolveApiToken()}`,
        Accept: "application/json",
      },
      filePath: ctx.options.filePath,
    });
    return { upload, file: ctx.options.filePath };
  },
};
