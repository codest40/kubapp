#!/usr/bin/env bash
set -euo pipefail

APP_DIR="gitops/infra/apps"

echo "Validating ArgoCD Applications..."

############################################
# HELPERS
############################################
fail() {
  echo "❌ $1"
  exit 1
}

check_file() {
  [[ -f "$1" ]] || fail "❌ Missing file: $1"
}

check_dir() {
  [[ -d "$1" ]] || fail "❌ Missing directory: $1"
}

############################################
# VALIDATE APP DIR
############################################
check_dir "$APP_DIR"

############################################
# COLLECT FILES SAFELY
############################################
mapfile -t FILES < <(
  find "$APP_DIR" \( -name "*.yml" -o -name "*.yaml" \)
)

if [[ ${#FILES[@]} -eq 0 ]]; then
  fail "❌ No ArgoCD apps found in $APP_DIR"
fi

############################################
# VALIDATION LOOP
############################################
for file in "${FILES[@]}"; do
  echo "Checking $file"

  # YAML validation
  yq e '.' "$file" >/dev/null || fail "Invalid YAML: $file"

  KIND=$(yq e '.kind' "$file")
  NAME=$(yq e '.metadata.name' "$file")

  # -----------------------------
  # Extract source path safely
  # -----------------------------
  if [[ "$KIND" == "ApplicationSet" ]]; then
    SOURCE_PATH=$(yq e '.spec.template.spec.source.path' "$file")
  else
    SOURCE_PATH=$(yq e '.spec.source.path' "$file")
  fi

  # -----------------------------
  # Validations
  # -----------------------------
  if [[ -z "$NAME" || "$NAME" == "null" ]]; then
    fail "Missing app name in $file"
  fi

  if [[ -z "$SOURCE_PATH" || "$SOURCE_PATH" == "null" ]]; then
    fail "Missing source path in $file"
  fi

  echo "✔ $NAME -> $SOURCE_PATH"

done

echo "✅ All ArgoCD applications valid"
