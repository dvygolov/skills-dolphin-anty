const { buildPayloadFromInput, ensureObjectPayload } = require("../utils");

module.exports = {
  "list-team-users": async (ctx) =>
    ctx.api.cloud("GET", "/team/users", {
      query: {
        limit: ctx.options.limit,
        query: ctx.options.query,
      },
    }),

  "create-team-user": async (ctx) => {
    const payload = buildPayloadFromInput(ctx.options);
    ensureObjectPayload(payload, "Provide team user payload via --json and/or --set key=value.");
    const create = await ctx.api.cloud("POST", "/team/users", { body: payload });
    return { create, sent: payload };
  },

  "update-team-user": async (ctx) => {
    const teamUserId = await ctx.resolveTeamUserIdValue();
    const payload = buildPayloadFromInput(ctx.options);
    ensureObjectPayload(payload, "Provide team user update payload via --json and/or --set key=value.");
    const update = await ctx.api.cloud("PATCH", `/team/users/${teamUserId}`, { body: payload });
    return { team_user_id: teamUserId, update, sent: payload };
  },

  "delete-team-user": async (ctx) => {
    const teamUserId = await ctx.resolveTeamUserIdValue();
    const del = await ctx.api.cloud("DELETE", `/team/users/${teamUserId}`);
    return { team_user_id: teamUserId, delete: del };
  },
};
