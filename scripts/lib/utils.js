const fs = require("fs");

function safeJsonStringify(value) {
  if (typeof value === "string") {
    return value;
  }
  return JSON.stringify(value, null, 2);
}

function sanitizeOutput(value, keyName = "") {
  const sensitiveKeys = new Set([
    "access_token",
    "api_token",
    "content",
    "email",
    "localsessiontoken",
    "login",
    "password",
    "proxypassword",
    "refresh_token",
    "token",
    "transfertoemail",
    "x-anty-session-token",
  ]);

  if (Array.isArray(value)) {
    return value.map((item) => sanitizeOutput(item));
  }

  if (value && typeof value === "object") {
    const output = {};
    for (const [key, nestedValue] of Object.entries(value)) {
      output[key] = sanitizeOutput(nestedValue, key);
    }
    return output;
  }

  if (typeof value === "string" && sensitiveKeys.has(String(keyName).toLowerCase())) {
    return "***";
  }

  if (typeof value === "string") {
    return value.replace(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}/gi, "[redacted-email]");
  }

  return value;
}

function maskSensitiveText(text) {
  if (!text || typeof text !== "string") {
    return text;
  }

  let output = text;
  output = output.replace(/Bearer\s+[A-Za-z0-9\-_.=+/]+/gi, "Bearer ***");
  output = output.replace(/(X-Anty-Session-Token\s*[:=]\s*['"])[^'"]+(['"])/gi, "$1***$2");
  output = output.replace(/"(token|api_token|access_token|refresh_token)"\s*:\s*"[^"]+"/gi, '"$1":"***"');
  output = output.replace(/\b[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}\b/g, "***jwt***");

  const max = 1200;
  if (output.length > max) {
    output = `${output.slice(0, max)}... [truncated]`;
  }

  return output;
}

function parseTokenFromText(text) {
  const trimmed = String(text || "").trim();
  if (!trimmed) {
    throw new Error("Token text is empty.");
  }

  if (trimmed.startsWith("{")) {
    try {
      const json = JSON.parse(trimmed);
      for (const key of ["token", "api_token", "apiKey", "key"]) {
        const candidate = json?.[key];
        if (candidate && String(candidate).trim()) {
          return String(candidate).trim();
        }
      }
    } catch {
    }
  }

  for (const line of trimmed.split(/\r?\n/)) {
    const candidate = line.trim();
    if (!candidate || candidate.startsWith("#")) {
      continue;
    }

    const matched = candidate.match(/^\s*(token|api_token|apiKey|key)\s*[:=]\s*(.+)$/);
    if (matched) {
      return matched[2].trim().replace(/^['"]|['"]$/g, "");
    }

    return candidate.replace(/^['"]|['"]$/g, "");
  }

  throw new Error("Failed to parse token from text.");
}

function convertScalarValue(inputValue) {
  if (inputValue === "null") {
    return null;
  }
  if (/^(true|false)$/i.test(inputValue)) {
    return /^true$/i.test(inputValue);
  }
  if (/^-?\d+$/.test(inputValue)) {
    const asNumber = Number.parseInt(inputValue, 10);
    if (Number.isSafeInteger(asNumber)) {
      return asNumber;
    }
  }
  if (/^-?\d+\.\d+$/.test(inputValue)) {
    const asNumber = Number.parseFloat(inputValue);
    if (!Number.isNaN(asNumber)) {
      return asNumber;
    }
  }
  return inputValue;
}

function addSetPairsToObject(map, pairs) {
  if (!pairs || !pairs.length) {
    return map;
  }

  for (const entry of pairs) {
    if (!entry || !String(entry).trim()) {
      continue;
    }
    const index = entry.indexOf("=");
    if (index < 1) {
      throw new Error(`Invalid --set value "${entry}". Use key=value.`);
    }
    const key = entry.slice(0, index).trim();
    const valueRaw = entry.slice(index + 1);
    map[key] = convertScalarValue(valueRaw);
  }
  return map;
}

function parseJsonObject(text) {
  if (!text || !String(text).trim()) {
    return {};
  }
  const parsed = JSON.parse(text);
  if (!parsed || Array.isArray(parsed) || typeof parsed !== "object") {
    throw new Error("JSON payload must be an object.");
  }
  return parsed;
}

function buildPayloadFromInput(options) {
  const payload = parseJsonObject(options.json);
  addSetPairsToObject(payload, options.set);
  return payload;
}

function addProxyFieldsToPayload(payload, options) {
  if (options.proxyName) payload.name = options.proxyName;
  if (options.proxyType) payload.type = options.proxyType;
  if (options.proxyHost) payload.host = options.proxyHost;
  if (options.proxyPort > 0) payload.port = options.proxyPort;
  if (options.proxyLogin) payload.login = options.proxyLogin;
  if (options.proxyPassword) payload.password = options.proxyPassword;
  if (options.proxyChangeIpUrl) payload.change_ip_url = options.proxyChangeIpUrl;
  return payload;
}

function addQueryString(url, queryParams) {
  if (!queryParams) {
    return url;
  }
  const pairs = [];
  for (const [key, value] of Object.entries(queryParams)) {
    if (value === undefined || value === null || value === "") {
      continue;
    }
    pairs.push(`${encodeURIComponent(String(key))}=${encodeURIComponent(String(value))}`);
  }
  if (!pairs.length) {
    return url;
  }
  return `${url}${url.includes("?") ? "&" : "?"}${pairs.join("&")}`;
}

function ensureObjectPayload(payload, message) {
  if (!payload || !Object.keys(payload).length) {
    throw new Error(message);
  }
}

function resolveAutomationPort(startResponse) {
  if (!startResponse || typeof startResponse !== "object") {
    return null;
  }
  if (startResponse.automation?.port) {
    return Number(startResponse.automation.port);
  }
  for (const key of ["automation_port", "remote_debugging_port", "port"]) {
    if (startResponse[key]) {
      const port = Number(startResponse[key]);
      if (Number.isInteger(port) && port > 0) {
        return port;
      }
    }
  }
  for (const key of ["data", "result"]) {
    if (startResponse[key]) {
      const nested = resolveAutomationPort(startResponse[key]);
      if (nested) {
        return nested;
      }
    }
  }
  return null;
}

function maskToken(tokenValue) {
  if (!tokenValue) {
    return null;
  }
  if (tokenValue.length <= 8) {
    return "*".repeat(tokenValue.length);
  }
  return `${tokenValue.slice(0, 4)}***${tokenValue.slice(-4)}`;
}

function readTextIfExists(filePath) {
  if (!filePath || !fs.existsSync(filePath)) {
    return null;
  }
  return fs.readFileSync(filePath, "utf8");
}

module.exports = {
  addProxyFieldsToPayload,
  addQueryString,
  addSetPairsToObject,
  buildPayloadFromInput,
  convertScalarValue,
  ensureObjectPayload,
  maskSensitiveText,
  maskToken,
  parseJsonObject,
  parseTokenFromText,
  readTextIfExists,
  resolveAutomationPort,
  sanitizeOutput,
  safeJsonStringify,
};
