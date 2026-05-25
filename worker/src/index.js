// rhythmiko-auth — Cloudflare Worker.
//
// One job: exchange a GitHub OAuth authorization code for an access token,
// from the browser, without exposing the GitHub OAuth App's client_secret.
//
// Endpoints
// ─────────
//   POST /exchange       body: { code, redirect_uri? }
//                        ->  { access_token, token_type, scope } | { error, ... }
//
//   GET  /healthz        ->  "ok"  (handy for uptime checks)
//
// Env vars (set via `wrangler secret put`):
//   GITHUB_CLIENT_ID      — public OAuth App client ID
//   GITHUB_CLIENT_SECRET  — never sent to the browser
//
// CORS
// ────
// Only the validator's own deployments need to call this. The allowlist is
// expressible as an env var (`ALLOWED_ORIGINS` = comma-separated) so adding
// a new domain doesn't require a code change.

const DEFAULT_ALLOWED = [
  "https://bentenitis.com",
  "https://www.bentenitis.com",
  "http://localhost:8000",
  "http://127.0.0.1:8000",
];

function buildAllowed(env) {
  const raw = (env.ALLOWED_ORIGINS || "").trim();
  if (!raw) return new Set(DEFAULT_ALLOWED);
  return new Set(raw.split(",").map(s => s.trim()).filter(Boolean));
}

function corsHeaders(origin, allowed) {
  const isAllowed = origin && allowed.has(origin);
  return {
    "Access-Control-Allow-Origin": isAllowed ? origin : "null",
    "Access-Control-Allow-Methods": "POST, GET, OPTIONS",
    "Access-Control-Allow-Headers": "content-type, accept",
    "Access-Control-Max-Age": "86400",
    "Vary": "Origin",
  };
}

async function handleExchange(req, env, headers) {
  let body;
  try {
    body = await req.json();
  } catch (_) {
    return json({ error: "bad_request", message: "expected JSON body" }, 400, headers);
  }
  const { code, redirect_uri } = body || {};
  if (!code || typeof code !== "string") {
    return json({ error: "bad_request", message: "missing code" }, 400, headers);
  }
  if (!env.GITHUB_CLIENT_ID || !env.GITHUB_CLIENT_SECRET) {
    return json({ error: "server_misconfigured", message: "client id/secret not set" }, 500, headers);
  }
  const payload = {
    client_id: env.GITHUB_CLIENT_ID,
    client_secret: env.GITHUB_CLIENT_SECRET,
    code,
  };
  if (redirect_uri) payload.redirect_uri = redirect_uri;

  let upstream;
  try {
    upstream = await fetch("https://github.com/login/oauth/access_token", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "User-Agent": "rhythmiko-auth-worker",
      },
      body: JSON.stringify(payload),
    });
  } catch (err) {
    return json({ error: "upstream_unreachable", message: String(err) }, 502, headers);
  }
  let data;
  try {
    data = await upstream.json();
  } catch (_) {
    const text = await upstream.text().catch(() => "");
    return json({ error: "upstream_bad_response", body: text.slice(0, 200) }, 502, headers);
  }
  // GitHub returns 200 even on application errors, with { error, error_description } in the body.
  // Propagate as-is; the client decides what to do.
  return json(data, upstream.ok ? 200 : upstream.status, headers);
}

function json(obj, status, headers) {
  return new Response(JSON.stringify(obj), {
    status,
    headers: { ...headers, "Content-Type": "application/json" },
  });
}

export default {
  async fetch(req, env) {
    const allowed = buildAllowed(env);
    const origin = req.headers.get("origin") || "";
    const headers = corsHeaders(origin, allowed);
    if (req.method === "OPTIONS") {
      return new Response(null, { status: 204, headers });
    }
    const { pathname } = new URL(req.url);
    if (pathname === "/healthz") {
      return new Response("ok", { status: 200, headers: { ...headers, "Content-Type": "text/plain" } });
    }
    if (pathname === "/exchange" && req.method === "POST") {
      return handleExchange(req, env, headers);
    }
    return json({ error: "not_found", path: pathname }, 404, headers);
  },
};
