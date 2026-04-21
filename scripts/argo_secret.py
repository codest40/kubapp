import os
import yaml
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent
FILE = BASE_DIR / "gitops/argocd/github-repo-secret.yaml"

private_key = os.getenv("PRIVATE_KEY")
app_id = os.getenv("APP_ID")
repo_url = os.getenv("REPO_URL")

if not private_key:
    raise Exception("PRIVATE_KEY is missing")

secret = {
    "apiVersion": "v1",
    "kind": "Secret",
    "metadata": {
        "name": "github-app-repo",
        "namespace": "argocd",
        "labels": {
            "argocd.argoproj.io/secret-type": "repo-creds"
        }
    },
    "type": "Opaque",
    "stringData": {
        "url": repo_url,
        "githubAppID": app_id,
        "githubAppPrivateKey": private_key
    }
}

FILE.parent.mkdir(parents=True, exist_ok=True)

with open(FILE, "w") as f:
    yaml.dump(secret, f, sort_keys=False)

print(f"[OK] Secret written to {FILE}")

