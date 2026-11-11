#!/usr/bin/env python3
"""Exports Castlei feedback reports and screenshots from Firestore.

  gcloud auth login            # once; the account needs access to the project
  python3 tool/export_feedback.py [--project castlei] [--out feedback-export]

Each new report becomes <out>/<id>/report.txt (+ diagnostics.txt, 0.jpg, 1.jpg,
2.jpg). Already exported reports are skipped. Uses only the standard library
and `gcloud auth print-access-token`; set GCLOUD_TOKEN to skip gcloud.
Output holds user emails and diagnostics: it is gitignored, keep it private.
"""
import argparse, base64, datetime, json, os, shutil, subprocess, sys
import urllib.error, urllib.parse, urllib.request


def token():
    t = os.environ.get("GCLOUD_TOKEN")
    if t:
        return t
    gcloud = shutil.which("gcloud") or os.path.expanduser("~/google-cloud-sdk/bin/gcloud")
    try:
        return subprocess.check_output([gcloud, "auth", "print-access-token"], text=True).strip()
    except (OSError, subprocess.CalledProcessError) as e:
        sys.exit(f"Could not get a token from gcloud ({e}). Run: gcloud auth login")


def get(url, tok, project):
    req = urllib.request.Request(url, headers={
        "Authorization": f"Bearer {tok}",
        "X-Goog-User-Project": project,
    })
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            return json.load(r)
    except urllib.error.HTTPError as e:
        if e.code == 404:
            return None
        sys.exit(f"Firestore error {e.code}: {e.read().decode()[:300]}")


def val(v):
    for k in ("stringValue", "integerValue", "booleanValue", "doubleValue"):
        if k in v:
            return int(v[k]) if k == "integerValue" else v[k]
    return None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--project", default="castlei")
    ap.add_argument("--out", default="feedback-export")
    a = ap.parse_args()
    tok = token()
    base = f"https://firestore.googleapis.com/v1/projects/{a.project}/databases/(default)/documents"
    os.makedirs(a.out, exist_ok=True)
    new = skipped = 0
    page = ""
    while True:
        q = "pageSize=100" + (f"&pageToken={urllib.parse.quote(page)}" if page else "")
        res = get(f"{base}/feedback?{q}", tok, a.project) or {}
        for d in res.get("documents", []):
            rid = d["name"].rsplit("/", 1)[1]
            folder = os.path.join(a.out, rid)
            if os.path.exists(os.path.join(folder, "report.txt")):
                skipped += 1
                continue
            f = {k: val(v) for k, v in d.get("fields", {}).items()}
            os.makedirs(folder, exist_ok=True)
            when = datetime.datetime.fromtimestamp((f.get("created") or 0) / 1000, datetime.timezone.utc)
            n = int(f.get("images") or 0)
            saved = 0
            for i in range(n):
                c = get(f"{base}/feedback/{urllib.parse.quote(rid)}/chunks/{i}", tok, a.project)
                b = c and c.get("fields", {}).get("data", {}).get("bytesValue")
                if b:
                    with open(os.path.join(folder, f"{i}.jpg"), "wb") as fh:
                        fh.write(base64.b64decode(b))
                    saved += 1
            if f.get("diagnostics"):
                with open(os.path.join(folder, "diagnostics.txt"), "w") as fh:
                    fh.write(f["diagnostics"])
            with open(os.path.join(folder, "report.txt"), "w") as fh:
                fh.write(
                    f"type: {f.get('type')}\nwhen: {when.isoformat()}\n"
                    f"app: {f.get('app')} (build {f.get('build')})\nos: {f.get('os')}\n"
                    f"locale: {f.get('locale')}\nuid: {f.get('uid')}\n"
                    f"reply-to: {f.get('email') or '-'}\n"
                    f"screenshots: {saved}/{n}\n\n{f.get('message')}\n"
                )
            print(f"{rid}  {f.get('type'):<11} {saved}/{n} img  {(f.get('message') or '')[:60]!r}")
            new += 1
        page = res.get("nextPageToken", "")
        if not page:
            break
    print(f"\n{new} new, {skipped} already exported -> {a.out}/")


if __name__ == "__main__":
    main()
