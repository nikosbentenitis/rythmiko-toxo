# Setting up the OAuth worker

This Cloudflare Worker is the one piece of infrastructure that lets the static rhythm validator at https://bentenitis.com/rhythms accept "Sign in with GitHub" and submit PRs back to this repo. It exchanges a short-lived OAuth authorization code for an access token, so the GitHub OAuth App's client secret never lives in browser JS.

You'll do five things, in order. Expect ~10 minutes if `wrangler` and a Cloudflare-managed `bentenitis.com` zone are already set up; ~25 minutes if not.

---

## 1. Register the GitHub OAuth App

Go to https://github.com/settings/developers → **OAuth Apps** → **New OAuth App**, and fill the form:

| Field | Value |
|---|---|
| Application name | `Rythmiko Toxo` |
| Homepage URL | `https://bentenitis.com/rhythms` |
| Application description | `Edit rhythms at bentenitis.com/rhythms and submit pull requests to rythmiko-toxo.` (optional) |
| **Authorization callback URL** | `https://bentenitis.com/rhythms` |
| Enable Device Flow | unchecked |

Click **Register application**.

On the resulting page:

- Copy the **Client ID** — you'll paste it into the validator HTML in Stage 3 (it's safe to publish).
- Click **Generate a new client secret**, copy it — this stays in the Worker and never leaves Cloudflare.

> The callback URL is the *page that handles the redirect* after GitHub auth. The validator at `/rhythms` does the handling itself by reading `?code=…` from the URL on load. Add more callback URLs later if you stand up the validator on additional domains; GitHub allows multiple via the "+ Add another" link on the OAuth App settings page.

## 2. Make sure `wrangler` is installed and authed

```bash
which wrangler   # if missing:
npm install -g wrangler

wrangler login   # opens a browser, authorize the CLI
```

If `bentenitis.com` is **not** yet a zone in your Cloudflare account, add it first via the CF dashboard (Sites → Add a site → enter `bentenitis.com` → follow nameserver instructions). The Worker can't bind to `auth.bentenitis.com` until the zone is on Cloudflare.

## 3. Configure secrets

From `worker/` in this repo:

```bash
cd worker/

wrangler secret put GITHUB_CLIENT_ID
# paste the Client ID from step 1, press Enter

wrangler secret put GITHUB_CLIENT_SECRET
# paste the Client Secret from step 1, press Enter
```

These are stored encrypted by Cloudflare; they never appear in source or logs.

## 4. Deploy

```bash
wrangler deploy
```

The first deploy creates the worker under your account and binds it to `auth.bentenitis.com/*` per `wrangler.toml`. Cloudflare will provision the TLS cert automatically (usually within a minute or two).

Smoke-test:

```bash
curl -s https://auth.bentenitis.com/healthz
# expected: ok

curl -s -X POST https://auth.bentenitis.com/exchange \
    -H 'content-type: application/json' \
    -H 'origin: https://bentenitis.com' \
    -d '{"code":"definitely-not-a-real-code"}'
# expected: a GitHub error JSON about a bad code — proves the secret pair works
```

## 5. Hand the Client ID to the validator

In `~/git/web/bentenitis/rhythms/index.html` (and the source copy at `~/git/communications-agent/tools/web/rhythm-validator.html`), set the `GITHUB_CLIENT_ID` constant at the top of the in-page script. Push both repos. Done.

---

## Maintenance

- **Rotate the client secret**: regenerate on the GitHub OAuth App page → `wrangler secret put GITHUB_CLIENT_SECRET` again → redeploy. Old token sessions remain valid until they expire/are revoked; new sign-ins use the new secret.
- **Add a new validator origin**: append to `ALLOWED_ORIGINS` in `wrangler.toml`, `wrangler deploy`. No GitHub change required.
- **Logs / debugging**: `wrangler tail` streams live request logs.

## Why a worker, and not pure static?

GitHub's `/login/oauth/access_token` endpoint does not include the CORS headers a browser needs, so a static page can't POST to it directly. The Worker also keeps the client secret off the public web. If you ever want to ditch the Worker, your options are (a) GitHub Personal Access Tokens pasted by each contributor, or (b) GitHub's Device Flow with a thinner CORS-only proxy. Both are documented in the validator README — but the Worker approach is the one designed for production.
