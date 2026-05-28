#!/usr/bin/env bash
set -euo pipefail

FILE="gitops/secrets/github-repo-secret.yaml"

echo "🧪 Roundtrip test starting..."

cp "$FILE" /tmp/original.yaml

echo "🔐 Encrypting..."
sops -e -i "$FILE"

echo "🔓 Decrypting..."
sops -d "$FILE" > /tmp/decrypted.yaml

echo "📦 Validating YAML..."
kubectl apply --dry-run=client -f /tmp/decrypted.yaml

echo "♻ Restoring original file..."
mv /tmp/original.yaml "$FILE"

echo "🎉 ROUNDTRIP SUCCESS"
