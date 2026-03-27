const fs = require("fs");
const path = require("path");
const { getSessionStorageDir } = require("./paths");
const { maskToken } = require("./utils");

function getSessionTokenCandidates(sessionStorageDir) {
  const targetDir = sessionStorageDir || getSessionStorageDir();
  if (!targetDir || !fs.existsSync(targetDir)) {
    throw new Error(`Session Storage directory not found: ${targetDir}`);
  }

  const entries = fs
    .readdirSync(targetDir, { withFileTypes: true })
    .filter((entry) => entry.isFile() && [".log", ".ldb"].includes(path.extname(entry.name).toLowerCase()))
    .map((entry) => {
      const fullPath = path.join(targetDir, entry.name);
      const stat = fs.statSync(fullPath);
      return {
        fullPath,
        name: entry.name,
        mtimeMs: stat.mtimeMs,
      };
    })
    .sort((a, b) => b.mtimeMs - a.mtimeMs || b.name.localeCompare(a.name));

  const all = [];

  for (const file of entries) {
    const raw = fs.readFileSync(file.fullPath).toString("latin1");
    const regex = /map-(\d+)-sessionToken([\s\S]*?)map-\1-intercom-test/g;
    for (const match of raw.matchAll(regex)) {
      const token = (match[2] || "").replace(/\0/g, "").replace(/[^A-Za-z0-9\-_]/g, "");
      if (token.length < 100) {
        continue;
      }
      all.push({
        mapId: Number.parseInt(match[1], 10),
        token,
        file: file.fullPath,
      });
    }
  }

  if (!all.length) {
    throw new Error("No LocalSessionToken candidates found in Session Storage.");
  }

  const seen = new Set();
  return all
    .sort((a, b) => b.mapId - a.mapId)
    .filter((item) => {
      if (seen.has(item.token)) {
        return false;
      }
      seen.add(item.token);
      return true;
    });
}

async function testLocalSessionTokenCandidate({ api }) {
  try {
    await api.local("POST", "/check/proxy", {
      body: {
        type: "http",
        host: "127.0.0.1",
        port: 1,
      },
      noAuth: true,
    });

    return {
      valid: true,
      status: 200,
      details: null,
    };
  } catch (error) {
    const message = String(error.message || "");
    const invalid = /HTTP 401:|invalid session token/i.test(message);
    return {
      valid: !invalid,
      status: invalid ? 401 : null,
      details: message,
    };
  }
}

async function recoverLocalSessionToken({ apiFactory, options, writeLocalSessionToken }) {
  const candidates = getSessionTokenCandidates(options.sessionStorageDir);
  const validationMode = options.skipValidation ? "skipped" : "protected-endpoint";

  if (!options.skipValidation) {
    await apiFactory({ localSessionToken: null }).ensureLocalAuth();
  }

  for (const candidate of candidates) {
    let validation = { valid: true, status: null };

    if (!options.skipValidation) {
      const candidateApi = apiFactory({ localSessionToken: candidate.token });
      validation = await testLocalSessionTokenCandidate({
        api: candidateApi,
      });
    }

    if (validation.valid) {
      const outputFile = writeLocalSessionToken(candidate.token, options.outputFile);
      return {
        success: true,
        output_file: outputFile,
        masked_token: maskToken(candidate.token),
        token_length: candidate.token.length,
        map_id: candidate.mapId,
        source_file: candidate.file,
        validation_mode: validationMode,
        validation_code: validation.status,
      };
    }
  }

  throw new Error("Failed to recover a valid LocalSessionToken from Session Storage.");
}

module.exports = {
  getSessionTokenCandidates,
  recoverLocalSessionToken,
};
