#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../iac" && pwd)"
STACKS=("infra" "k8s" "manifests")

ENV="${1:-dev}"

echo
echo "=================================================="
echo "[INFO] SECRETS ENCRYPTION STARTED"
echo "[INFO] ENVIRONMENT: $ENV"
echo "[INFO] ROOT: $ROOT"
echo "=================================================="
echo

# =========================
# LOAD SETUP FUNCTIONS
# =========================
echo "--------------------------------------------------"
echo "[INFO] LOADING SOPS SETUP"
echo "--------------------------------------------------"

SETUP="./setup_sops.sh"
SETUP1="scripts/setup_sops.sh"

if [[ -f "$SETUP" ]]; then
  echo "[INFO] Sourcing $SETUP"
  source "$SETUP"
elif [[ -f "$SETUP1" ]]; then
  echo "[INFO] Sourcing $SETUP1"
  source "$SETUP1"
else
  echo "[ERROR] ❌ setup_sops.sh not found"
  exit 1
fi

echo

# =========================
# PREREQUISITES
# =========================
echo "--------------------------------------------------"
echo "[INFO] CHECKING PREREQUISITES"
echo "--------------------------------------------------"

install_sops
install_age
ensure_age_key

AGE_PUBLIC_KEY=$(get_age_public_key)

if [[ -z "$AGE_PUBLIC_KEY" ]]; then
  echo "[ERROR] ❌ Could not extract AGE public key"
  exit 1
fi

echo "[INFO] Using AGE key: $AGE_PUBLIC_KEY"
echo

# =========================
# ENV SELECTION
# =========================
get_envs() {
  case "$ENV" in
    dev)
      echo "dev"
      ;;
    prod)
      echo "prod"
      ;;
    all)
      echo "dev prod"
      ;;
    *)
      echo "[ERROR] ❌ Invalid env: $ENV"
      exit 1
      ;;
  esac
}

# =========================
# ENCRYPT FUNCTION
# =========================
encrypt_tfvars() {
  local file="$1"
  local out="${file}.enc"

  echo "[INFO] Encrypting: $file -> $out"

  sops --encrypt \
    --age "$AGE_PUBLIC_KEY" \
    "$file" > "$out"
}

# =========================
# MAIN LOOP
# =========================
echo "--------------------------------------------------"
echo "[INFO] TERRAFORM SECRETS ENCRYPTION"
echo "--------------------------------------------------"
echo "[INFO] Starting encryption for ENV=$ENV"
echo

for env in $(get_envs); do
  echo "[INFO] ENV: $env"

  for stack in "${STACKS[@]}"; do
    DIR="$ROOT/$stack/envs/$env"

    if [[ -d "$DIR" ]]; then
      echo "[INFO] Directory found: $DIR"
    else
      echo "[WARN] ⚠️ Directory not found: $DIR"
      continue
    fi

    echo "[INFO] Processing stack: $stack"

    for tfvars in "$DIR"/*.tfvars; do
      [[ -f "$tfvars" ]] || continue
      encrypt_tfvars "$tfvars"
    done
  done

  echo
done

# =========================
# GITOPS SOPS ENCRYPTION
# =========================
echo "--------------------------------------------------"
echo "[INFO] GITOPS SECRETS ENCRYPTION"
echo "--------------------------------------------------"

GITOPS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../gitops/secrets" && pwd)"
BACKUP_DIR="$GITOPS_DIR/.backup"

echo "[INFO] Target directory: $GITOPS_DIR"

mkdir -p "$BACKUP_DIR"

[[ -d "$GITOPS_DIR" ]] || {
  echo "[ERROR] ❌ Directory not found: $GITOPS_DIR"
  exit 1
}

shopt -s nullglob

found_files=false
valid_files=false

for file in "$GITOPS_DIR"/*.yaml "$GITOPS_DIR"/*.yml; do
  [[ -f "$file" ]] || continue
  found_files=true

  echo "[INFO] Processing: $file"

  # -------------------------
  # Detect already encrypted
  # -------------------------
  if grep -q '^sops:' "$file"; then
    echo "[WARN] ⚠️ Already encrypted, skipping: $file"
    valid_files=true
    continue
  fi

  # -------------------------
  # Backup original
  # -------------------------
  backup_file="$BACKUP_DIR/$(basename "$file").bak"
  cp -f "$file" "$backup_file"
  echo "[INFO] Backup created: $backup_file"

  # -------------------------
  # Encrypt in-place
  # -------------------------
  if sops -e -i "$file"; then
    echo "[INFO] ✅ Encrypted: $file"
    valid_files=true
  else
    echo "[ERROR] ❌ Failed: $file"
    echo "[ERROR] Restoring backup..."
    cp -f "$backup_file" "$file"
    exit 1
  fi

done

# -------------------------
# Final validation
# -------------------------
echo
echo "--------------------------------------------------"
echo "[INFO] FINAL VALIDATION"
echo "--------------------------------------------------"

if [[ "$found_files" = false ]]; then
  echo "[ERROR] ❌ No YAML files found"
  exit 1
fi

if [[ "$valid_files" = false ]]; then
  echo "[ERROR] ❌ No valid encrypted files exist"
  exit 1
fi

# =========================
# DOCKER APP SECRETS ENCRYPTION
# =========================
echo "--------------------------------------------------"
echo "[INFO] DOCKER SECRETS ENCRYPTION"
echo "--------------------------------------------------"

DOCKER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../docker" && pwd)"
echo "[INFO] Target directory: $DOCKER_DIR"

[[ -d "$DOCKER_DIR" ]] || {
  echo "[ERROR] ❌ Directory not found: $DOCKER_DIR"
  exit 1
}

shopt -s nullglob

found_docker_files=false
valid_docker_files=false

while IFS= read -r -d '' file; do
  [[ -f "$file" ]] || continue
  found_docker_files=true

  echo "[INFO] Processing: $file"

  # Backup
  backup_1="${file}.bak"

  cp -f "$file" "$backup_1"
  echo "[INFO] Backup updated: $backup_1"

  echo "[INFO] Backup created: $backup_1"

  # Skip already encrypted
  if grep -q '^sops:' "$file"; then
    echo "[WARN] ⚠️ Already encrypted: $file"
    valid_docker_files=true
    continue
  fi

  if sops -e -i "$file"; then
    echo "[INPLACE] Encrypted: $file"
    valid_docker_files=true
  else
    echo "[ERROR] ❌ Failed: $file"
    echo "[ERROR] Restoring backup..."
    cp -f "$backup_file" "$file"
    exit 1
  fi

done < <(
  find "$DOCKER_DIR" -type f \( \
    -name "secrets.yml" -o \
    -name "secrets.yaml" -o \
    -name "secret.yml" -o \
    -name "secret.yaml" \
  \) -print0
)

if [[ "$found_docker_files" = false ]]; then
  echo "[WARN] ⚠️ No docker secret files found"
fi

echo
echo "=================================================="
echo "[INFO] ✅ ENCRYPTION COMPLETE"
echo "=================================================="
echo
