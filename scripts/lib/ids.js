function selectCollection(response, keys) {
  if (response == null) {
    return [];
  }

  for (const key of keys) {
    const value = response?.[key];
    if (Array.isArray(value)) {
      return value;
    }
  }

  if (Array.isArray(response)) {
    return response;
  }

  return [];
}

async function resolveNamedIdValue({ directId, nameValue, listPath, collectionKeys, entityLabel, ctx }) {
  if (directId && String(directId).trim()) {
    return String(directId).trim();
  }
  if (!nameValue || !String(nameValue).trim()) {
    throw new Error(`Specify direct id or name for ${entityLabel}.`);
  }

  const response = await ctx.api.cloud("GET", listPath, {
    query: {
      query: nameValue,
      limit: 100,
      page: 1,
    },
  });

  const items = selectCollection(response, collectionKeys);
  if (!items.length) {
    throw new Error(`No ${entityLabel} found for name: ${nameValue}`);
  }

  const exact = items.find((item) => item?.name === nameValue);
  return String((exact || items[0]).id);
}

async function resolveProfileIdValue(ctx) {
  return resolveNamedIdValue({
    directId: ctx.options.profileId,
    nameValue: ctx.options.profileName,
    listPath: "/browser_profiles",
    collectionKeys: ["data", "items", "browser_profiles", "profiles", "result"],
    entityLabel: "profile",
    ctx,
  });
}

async function resolveProxyIdValue(ctx) {
  return resolveNamedIdValue({
    directId: ctx.options.proxyId,
    nameValue: ctx.options.proxyName,
    listPath: "/proxy",
    collectionKeys: ["data", "items", "proxies", "result"],
    entityLabel: "proxy",
    ctx,
  });
}

async function resolveFolderIdValue(ctx) {
  return resolveNamedIdValue({
    directId: ctx.options.folderId,
    nameValue: ctx.options.query,
    listPath: "/folders",
    collectionKeys: ["data", "items", "folders", "result"],
    entityLabel: "folder",
    ctx,
  });
}

async function resolveHomepageIdValue(ctx) {
  return resolveNamedIdValue({
    directId: ctx.options.homepageId,
    nameValue: ctx.options.query,
    listPath: "/homepages",
    collectionKeys: ["data", "items", "homepages", "result"],
    entityLabel: "homepage",
    ctx,
  });
}

async function resolveBookmarkIdValue(ctx) {
  return resolveNamedIdValue({
    directId: ctx.options.bookmarkId,
    nameValue: ctx.options.query,
    listPath: "/bookmarks",
    collectionKeys: ["data", "items", "bookmarks", "result"],
    entityLabel: "bookmark",
    ctx,
  });
}

async function resolveTeamUserIdValue(ctx) {
  return resolveNamedIdValue({
    directId: ctx.options.teamUserId,
    nameValue: ctx.options.query,
    listPath: "/team/users",
    collectionKeys: ["data", "items", "users", "result"],
    entityLabel: "team user",
    ctx,
  });
}

module.exports = {
  resolveBookmarkIdValue,
  resolveFolderIdValue,
  resolveHomepageIdValue,
  resolveProfileIdValue,
  resolveProxyIdValue,
  resolveTeamUserIdValue,
  selectCollection,
};
