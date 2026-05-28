#!/usr/bin/env bash
set -euo pipefail

GITOPS_DIR="gitops/secrets"

echo "🔐 Encrypting Kubernetes secrets in: $GITOPS_DIR"

for file in "$GITOPS_DIR"/*.yaml; do
  [[ -f "$file" ]] || continue

  echo "➡ Encrypting: $file"

  # IMPORTANT: let sops use .sops.yaml (DO NOT pass --age manually)
  sops -e -i "$file"

  echo "✅ Encrypted in-place: $file"
done

echo "🎉 Encryption complete"
