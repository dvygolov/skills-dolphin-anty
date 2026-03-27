module.exports = {
  "local-auth": async (ctx) => ctx.api.ensureLocalAuth(),
  "list-running-profiles": async (ctx) => ctx.api.local("GET", "/browser_profiles/running"),
};
