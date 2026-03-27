const fs = require("fs");
const path = require("path");
const { maskSensitiveText } = require("./utils");

async function parseResponseBody(response, expectRaw) {
  if (expectRaw) {
    return response.text();
  }

  const text = await response.text();
  if (!text) {
    return null;
  }
  try {
    return JSON.parse(text);
  } catch {
    return text;
  }
}

async function request({ method, url, headers, body, raw = false }) {
  const init = {
    method,
    headers: headers ? { ...headers } : {},
  };

  if (body !== undefined && body !== null) {
    if (body instanceof FormData) {
      init.body = body;
    } else if (typeof body === "string") {
      init.body = body;
      if (!init.headers["Content-Type"]) {
        init.headers["Content-Type"] = "application/json";
      }
    } else {
      init.body = JSON.stringify(body);
      if (!init.headers["Content-Type"]) {
        init.headers["Content-Type"] = "application/json";
      }
    }
  }

  let response;
  try {
    response = await fetch(url, init);
  } catch (error) {
    throw new Error(maskSensitiveText(error.message));
  }

  const value = await parseResponseBody(response, raw);
  if (!response.ok) {
    const detailText = typeof value === "string" ? value : JSON.stringify(value);
    throw new Error(`HTTP ${response.status}: ${maskSensitiveText(detailText)}`);
  }
  return value;
}

async function multipartUpload({ url, fieldName = "file", filePath, headers }) {
  if (!fs.existsSync(filePath)) {
    throw new Error(`File not found: ${filePath}`);
  }

  const fileBuffer = fs.readFileSync(filePath);
  const form = new FormData();
  form.append(fieldName, new Blob([fileBuffer]), path.basename(filePath));

  return request({
    method: "POST",
    url,
    headers,
    body: form,
  });
}

module.exports = {
  multipartUpload,
  request,
};
