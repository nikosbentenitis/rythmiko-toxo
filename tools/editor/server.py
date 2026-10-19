#!/usr/bin/env python3
"""Local rhythm editor (Nikos, 19 Oct 2026): "create a local page that allows
me to edit the rhythm that I select (no need to github sync) and when I press
save, it creates the new music notation and can play the new rhythm".

Standard library plus PyYAML. Serves static/index.html and a small JSON API
on port 8817, all interfaces (ZeroTier http://10.222.154.11:8817/, home Wi-Fi),
and keeps `tailscale serve` :9303 mapped to it for the Macs
(https://hermes.taild1dd5.ts.net:9303/). Path-aware: a leading /rhythms is
stripped, so the hub origin can proxy it at /rhythms/; the page uses only
relative URLs.

Data (RHYTHM_EDITOR_DATA, default ~/.local/share/rhythm-editor):
  rhythms/<slug>.yaml            the files the editor edits (not in git)
  rhythms/.history/<slug>/<stamp>.yaml         the version before each save
  rhythms/.history/<slug>/<stamp>.undone.yaml  the version a revert replaced
  render/<slug>/...              LilyPond PDF + PNG pages of the saved version
At start, every rhythms/*.yaml of the repo (RHYTHM_EDITOR_SEED) that the data
folder lacks is copied in; an existing file is never overwritten.

API (JSON):
  GET  api/list                       rhythms with display, meter, variations, edited flag
  GET  api/rhythm?slug=               yaml, sha, history, analysis
  POST api/preview {slug, yaml}       analysis (diagnostics + notation + sound), nothing written
  POST api/save    {slug, yaml, base} back up the file, write it, start LilyPond
  POST api/revert  {slug}             put back the version before the last save
  GET  api/render?slug=               LilyPond state for the saved version
"""
import hashlib
import json
import os
import shutil
import subprocess
import sys
import threading
import time
from datetime import datetime
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, quote, urlparse

# The supervisor's PATH may lack Homebrew, where lilypond and poppler live.
os.environ["PATH"] = os.pathsep.join(["/opt/homebrew/bin", "/usr/local/bin", os.environ.get("PATH", "")])

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[1]
sys.path.insert(0, str(HERE))
import rhythm_model as model  # noqa: E402

PORT = int(os.environ.get("RHYTHM_EDITOR_PORT", "8817"))
TS_PORT = int(os.environ.get("RHYTHM_EDITOR_TS_PORT", "9303"))   # 0 = do not manage tailscale serve
BIND = os.environ.get("RHYTHM_EDITOR_BIND", "0.0.0.0")
DATA = Path(os.environ.get("RHYTHM_EDITOR_DATA", "~/.local/share/rhythm-editor")).expanduser()
SEED = Path(os.environ.get("RHYTHM_EDITOR_SEED", str(REPO / "rhythms"))).expanduser()
PREFIX = "/rhythms"
TS = "/Applications/Tailscale.app/Contents/MacOS/Tailscale"
STYLES = ("teacher", "full")

RHYTHMS = DATA / "rhythms"
HISTORY = RHYTHMS / ".history"
RENDER = DATA / "render"
STATIC = HERE / "static"
SAMPLES = HERE / "samples"
TYPES = {".html": "text/html; charset=utf-8", ".js": "text/javascript; charset=utf-8",
         ".css": "text/css; charset=utf-8", ".json": "application/json", ".mp3": "audio/mpeg",
         ".pdf": "application/pdf", ".png": "image/png", ".svg": "image/svg+xml", ".ly": "text/plain; charset=utf-8"}

file_lock = threading.Lock()


def log(msg):
    print(f"{datetime.now():%Y-%m-%d %H:%M:%S} {msg}", flush=True)


def sha(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()[:16]


def valid_slug(slug: str) -> bool:
    return bool(slug) and slug.replace("_", "").replace("-", "").isalnum() and slug.isascii()


def seed():
    RHYTHMS.mkdir(parents=True, exist_ok=True)
    HISTORY.mkdir(parents=True, exist_ok=True)
    RENDER.mkdir(parents=True, exist_ok=True)
    added = []
    if SEED.is_dir():
        for p in sorted(SEED.glob("*.yaml")):
            dst = RHYTHMS / p.name
            if not dst.exists():
                shutil.copy2(p, dst)
                added.append(p.stem)
    if added:
        log(f"seeded {len(added)} rhythm(s) from {SEED}: {', '.join(added)}")


def history_of(slug: str):
    d = HISTORY / slug
    if not d.is_dir():
        return []
    out = []
    for p in sorted(d.glob("*.yaml"), reverse=True):
        undone = p.name.endswith(".undone.yaml")
        stamp = p.name.split(".")[0]
        out.append({"file": p.name, "stamp": stamp, "undone": undone,
                    "when": datetime.strptime(stamp, "%Y%m%d-%H%M%S-%f").strftime("%d %b %H:%M:%S")})
    return out


def stamp() -> str:
    return datetime.now().strftime("%Y%m%d-%H%M%S-%f")


def list_rhythms():
    out = []
    for p in sorted(RHYTHMS.glob("*.yaml")):
        text = p.read_text(encoding="utf-8")
        res = model.analyze(text, p.stem)
        r = res["rhythm"] or {}
        seedp = SEED / p.name
        edited = (not seedp.exists()) or seedp.read_text(encoding="utf-8") != text
        out.append({"slug": p.stem, "display": r.get("display", p.stem), "meter": r.get("meter", ""),
                    "variations": [v["id"] for v in r.get("variations", [])],
                    "errors": model.has_errors(res), "edited": edited,
                    "history": len([h for h in history_of(p.stem) if not h["undone"]])})
    return out


# ---- LilyPond: one worker per rhythm, latest saved version wins ---------
renders = {}          # slug -> state dict
render_lock = threading.Lock()


def _state_file(slug):
    return RENDER / slug / "state.json"


def render_state(slug: str) -> dict:
    with render_lock:
        st = renders.get(slug)
        if st is None:
            try:
                st = json.loads(_state_file(slug).read_text())
            except Exception:
                st = {"state": "none"}
            renders[slug] = st
        return dict(st)


def _set_state(slug, **kw):
    with render_lock:
        st = renders.setdefault(slug, {"state": "none"})
        st.update(kw)
        if st["state"] in ("done", "error"):
            (RENDER / slug).mkdir(parents=True, exist_ok=True)
            _state_file(slug).write_text(json.dumps({k: v for k, v in st.items() if k not in ("worker", "pending")}))
        return dict(st)


def _pages(pdf: Path, outdir: Path, style: str):
    info = subprocess.run(["pdfinfo", str(pdf)], capture_output=True, text=True).stdout
    pages = int(next((l for l in info.splitlines() if l.startswith("Pages:")), "Pages: 1").split()[1])
    first = 1
    if pages > 1:
        p1 = subprocess.run(["pdftotext", "-f", "1", "-l", "1", str(pdf), "-"], capture_output=True, text=True).stdout
        if "Table of Contents" in p1:
            first = 2
    subprocess.run(["pdftoppm", "-r", "130", "-f", str(first), "-l", str(pages), "-png", str(pdf),
                    str(outdir / f"{style}-page")], check=True, capture_output=True)
    return sorted(p.name for p in outdir.glob(f"{style}-page-*.png"))


def run_render(slug: str):
    """Render the CURRENT file; loop while saves keep arriving."""
    while True:
        path = RHYTHMS / f"{slug}.yaml"
        text = path.read_text(encoding="utf-8")
        version = sha(text)
        _set_state(slug, state="running", version=version, started=time.time(), pending=False)
        t0 = time.time()
        outdir = RENDER / slug / version
        shutil.rmtree(outdir, ignore_errors=True)
        outdir.mkdir(parents=True)
        snap = outdir / f"{slug}.yaml"
        snap.write_text(text, encoding="utf-8")
        result, err = {}, None
        if not shutil.which("lilypond"):
            err = "LilyPond is not installed on this Mac (brew install lilypond)."
        else:
            for style in STYLES:
                sdir = outdir / style
                r = subprocess.run([sys.executable, str(HERE / "render_ly.py"), "--yaml", str(snap), "--slug", slug,
                                    "--out", str(sdir), "--style", style],
                                   capture_output=True, text=True, timeout=240, cwd=str(HERE))
                pdf = sdir / f"{slug}.pdf"
                if r.returncode != 0 or not pdf.exists():
                    tail = (r.stderr or r.stdout).strip().splitlines()[-6:]
                    err = "LilyPond failed: " + " | ".join(tail)
                    break
                shutil.move(str(pdf), outdir / f"{slug}-{style}.pdf")
                if (sdir / f"{slug}.ly").exists():
                    shutil.move(str(sdir / f"{slug}.ly"), outdir / f"{slug}-{style}.ly")
                shutil.rmtree(sdir, ignore_errors=True)
                try:
                    pages = _pages(outdir / f"{slug}-{style}.pdf", outdir, style)
                except Exception as e:
                    pages = []
                    log(f"{slug}: pdftoppm failed: {e!r}")
                result[style] = {"pdf": f"render/{slug}/{version}/{slug}-{style}.pdf",
                                 "pages": [f"render/{slug}/{version}/{n}" for n in pages]}
        secs = round(time.time() - t0, 2)
        if err:
            _set_state(slug, state="error", version=version, error=err, finished=time.time(), seconds=secs, styles={})
            log(f"{slug}: render {version} failed in {secs}s: {err}")
        else:
            _set_state(slug, state="done", version=version, error=None, finished=time.time(), seconds=secs, styles=result)
            log(f"{slug}: rendered {version} in {secs}s")
            for old in (RENDER / slug).iterdir():   # keep only the newest render
                if old.is_dir() and old.name != version:
                    shutil.rmtree(old, ignore_errors=True)
        with render_lock:   # start_render() sets `pending` under the same lock
            if not renders[slug].get("pending") and sha(path.read_text(encoding="utf-8")) == version:
                renders[slug]["worker"] = False
                return


def start_render(slug: str):
    with render_lock:
        st = renders.setdefault(slug, {"state": "none"})
        if st.get("worker"):
            st["pending"] = True
            return
        st["worker"] = True
    threading.Thread(target=_render_guard, args=(slug,), daemon=True).start()


def _render_guard(slug):
    try:
        run_render(slug)
    except Exception as e:
        log(f"{slug}: render crashed: {e!r}")
        with render_lock:
            renders[slug]["worker"] = False
        _set_state(slug, state="error", error=f"render crashed: {e}", finished=time.time())


def render_info(slug: str) -> dict:
    """State for the saved file; starts a render when none matches it."""
    text = (RHYTHMS / f"{slug}.yaml").read_text(encoding="utf-8")
    st = render_state(slug)
    st.pop("worker", None)
    current = sha(text)
    st["current"] = st.get("version") == current
    if not st["current"] and st.get("state") != "running":
        start_render(slug)
        st = {"state": "running", "version": current, "current": True, "styles": {}}
    return st


# ---- save / revert ------------------------------------------------------
def save(slug: str, text: str, base: str | None):
    path = RHYTHMS / f"{slug}.yaml"
    res = model.analyze(text, slug)
    bad = model.structural_errors(res)
    if bad:
        return 422, {"ok": False, "error": "Not saved: " + bad[0]["message"], "analysis": res}
    if not text.endswith("\n"):
        text += "\n"
    with file_lock:
        old = path.read_text(encoding="utf-8") if path.exists() else None
        if old is not None and base and sha(old) != base:
            return 409, {"ok": False, "error": "This rhythm was saved from another device since you opened it. Reload to see that version.",
                         "conflict": True}
        if old == text:
            return 200, {"ok": True, "unchanged": True, "sha": sha(text), "history": history_of(slug), "analysis": res}
        if old is not None:
            (HISTORY / slug).mkdir(parents=True, exist_ok=True)
            (HISTORY / slug / f"{stamp()}.yaml").write_text(old, encoding="utf-8")
        tmp = path.with_suffix(".yaml.tmp")
        tmp.write_text(text, encoding="utf-8")
        os.replace(tmp, path)
    log(f"{slug}: saved {sha(text)} ({len(text)} bytes)")
    start_render(slug)
    return 200, {"ok": True, "sha": sha(text), "history": history_of(slug), "analysis": res}


def revert(slug: str):
    path = RHYTHMS / f"{slug}.yaml"
    with file_lock:
        backups = [h for h in history_of(slug) if not h["undone"]]
        if not backups:
            return 404, {"ok": False, "error": "No earlier version to go back to."}
        prev = HISTORY / slug / backups[0]["file"]
        cur = path.read_text(encoding="utf-8")
        (HISTORY / slug / f"{stamp()}.undone.yaml").write_text(cur, encoding="utf-8")
        text = prev.read_text(encoding="utf-8")
        tmp = path.with_suffix(".yaml.tmp")
        tmp.write_text(text, encoding="utf-8")
        os.replace(tmp, path)
        prev.unlink()
    log(f"{slug}: reverted to {backups[0]['stamp']}")
    start_render(slug)
    return 200, {"ok": True, "yaml": text, "sha": sha(text), "restored": backups[0]["when"],
                 "history": history_of(slug), "analysis": model.analyze(text, slug)}


# ---- HTTP ---------------------------------------------------------------
class H(BaseHTTPRequestHandler):
    server_version = "rhythm-editor/1"

    def log_message(self, fmt, *a):
        pass

    def _send(self, code, body, ctype="application/json", extra=None):
        data = body if isinstance(body, bytes) else json.dumps(body, ensure_ascii=False).encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(data)))
        self.send_header("Cache-Control", "no-store")
        for k, v in (extra or {}).items():
            self.send_header(k, v)
        self.end_headers()
        if self.command != "HEAD":
            self.wfile.write(data)

    def _file(self, base: Path, rel: str):
        p = (base / rel).resolve()
        if not str(p).startswith(str(base.resolve()) + os.sep) or not p.is_file():
            return self._send(404, {"error": "not found"})
        self._send(200, p.read_bytes(), TYPES.get(p.suffix, "application/octet-stream"))

    def _path(self):
        u = urlparse(self.path)
        path = u.path
        if path == PREFIX:
            return None, u
        if path.startswith(PREFIX + "/"):
            path = path[len(PREFIX):]
        return path, u

    def _slug(self, q):
        slug = (q.get("slug") or [""])[0]
        if not valid_slug(slug) or not (RHYTHMS / f"{slug}.yaml").exists():
            return None
        return slug

    def do_HEAD(self):
        self.do_GET()

    def do_GET(self):
        path, u = self._path()
        if path is None:
            return self._send(301, b"", "text/plain", {"Location": PREFIX + "/"})
        q = parse_qs(u.query)
        try:
            if path in ("/", "/index.html"):
                return self._file(STATIC, "index.html")
            if path.startswith("/static/"):
                return self._file(STATIC, path[len("/static/"):])
            if path.startswith("/samples/"):
                return self._file(SAMPLES, path[len("/samples/"):])
            if path.startswith("/render/"):
                return self._file(RENDER, path[len("/render/"):])
            if path == "/api/health":
                return self._send(200, {"ok": True, "data": str(DATA), "rhythms": len(list(RHYTHMS.glob("*.yaml"))),
                                        "lilypond": bool(shutil.which("lilypond"))})
            if path == "/api/list":
                return self._send(200, {"rhythms": list_rhythms(), "data": str(DATA)})
            if path == "/api/rhythm":
                slug = self._slug(q)
                if not slug:
                    return self._send(404, {"error": "unknown rhythm"})
                text = (RHYTHMS / f"{slug}.yaml").read_text(encoding="utf-8")
                seedp = SEED / f"{slug}.yaml"
                return self._send(200, {"slug": slug, "yaml": text, "sha": sha(text), "history": history_of(slug),
                                        "path": str(RHYTHMS / f"{slug}.yaml"),
                                        "edited": (not seedp.exists()) or seedp.read_text(encoding="utf-8") != text,
                                        "analysis": model.analyze(text, slug)})
            if path == "/api/render":
                slug = self._slug(q)
                if not slug:
                    return self._send(404, {"error": "unknown rhythm"})
                return self._send(200, render_info(slug))
            return self._send(404, {"error": "not found"})
        except Exception as e:
            log(f"GET {u.path} failed: {e!r}")
            return self._send(500, {"error": str(e)})

    def do_POST(self):
        path, u = self._path()
        try:
            n = int(self.headers.get("Content-Length") or 0)
            if n > 2_000_000:
                return self._send(413, {"error": "too large"})
            body = json.loads(self.rfile.read(n) or b"{}")
            slug = str(body.get("slug") or "")
            if not valid_slug(slug):
                return self._send(400, {"error": "bad slug"})
            if path == "/api/preview":
                return self._send(200, model.analyze(str(body.get("yaml") or ""), slug))
            if not (RHYTHMS / f"{slug}.yaml").exists():
                return self._send(404, {"error": "unknown rhythm"})
            if path == "/api/save":
                code, out = save(slug, str(body.get("yaml") or ""), body.get("base"))
                return self._send(code, out)
            if path == "/api/revert":
                code, out = revert(slug)
                return self._send(code, out)
            return self._send(404, {"error": "not found"})
        except Exception as e:
            log(f"POST {u.path} failed: {e!r}")
            return self._send(500, {"error": str(e)})


def ensure_tailscale_serve():
    """As training-page: command-center's serve-tailscale.sh starts with `serve reset`, so re-add ours."""
    while True:
        try:
            st = subprocess.run([TS, "serve", "status", "--json"], capture_output=True, text=True, timeout=20).stdout
            if f":{TS_PORT}" not in st:
                subprocess.run([TS, "serve", "--bg", f"--https={TS_PORT}", f"http://127.0.0.1:{PORT}"],
                               capture_output=True, text=True, timeout=30)
                log(f"tailscale serve :{TS_PORT} -> 127.0.0.1:{PORT} (re)added")
        except Exception as e:
            log(f"tailscale serve check failed: {e!r}")
        time.sleep(600)


def main():
    seed()
    if TS_PORT and Path(TS).exists():
        threading.Thread(target=ensure_tailscale_serve, daemon=True).start()
    srv = ThreadingHTTPServer((BIND, PORT), H)
    log(f"rhythm editor on {BIND}:{PORT}; data {DATA}; seed {SEED}; lilypond {shutil.which('lilypond')}")
    srv.serve_forever()


if __name__ == "__main__":
    main()
