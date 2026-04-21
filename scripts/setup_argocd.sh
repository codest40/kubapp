#!/bin/bash
set -euo pipefail

echo "Setting up ArgoCD GitHub App integration..."

# Required env vars
: "${APP_ID:?Missing APP_ID}"
: "${PRIVATE_KEY_FILE:?Missing PRIVATE_KEY_FILE}"
: "${INSTALLATION_ID:?Missing INSTALLATION_ID}"
: "${REPO_URL:?Missing REPO_URL}"

echo "📦 Generating GitHub App installation token..."

TOKEN=$(curl -s -X POST \
  -H "Authorization: Bearer $(openssl base64 -A -in "$PRIVATE_KEY_FILE")" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/app/installations/$INSTALLATION_ID/access_tokens" \
  | jq -r .token)

if [[ -z "$TOKEN" || "$TOKEN" == "null" ]]; then
  echo "❌ Failed to generate GitHub App token"
  exit 1
fi

echo "✅ Token generated"

echo "Registering repo in ArgoCD..."

argocd repo add "$REPO_URL" \
  --username x-access-token \
  --password "$TOKEN"

echo "GitHub App successfully linked to ArgoCD"
