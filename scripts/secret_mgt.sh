#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-}"
ENV="${2:-dev}"

if ! ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null)"; then
  echo "[ERROR] ❌ Not inside a git repository"
  exit 1
fi

S3_BUCKET="test-backup-bucket"
S3_PREFIX="paragon-secrets/$ENV"

if [[ "$MODE" != "backup" && "$MODE" != "recover" && "$MODE" != "delete" ]]; then
  echo "Usage: $0 {backup|recover|delete} [env]"
  exit 1
fi

echo "=================================================="
echo "[INFO] MODE: $MODE"
echo "[INFO] ENV: $ENV"
echo "[INFO] ROOT: $ROOT_DIR"
echo "=================================================="

############################################
# BACKUP MODE
############################################
backup_mode() {
  TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
  WORKDIR="/tmp/paragon-backup-$TIMESTAMP/paragon"
  ARCHIVE="/tmp/paragon-backup-$TIMESTAMP.tar.gz"

  mkdir -p "$WORKDIR"
  MANIFEST="$WORKDIR/manifest.txt"
  > "$MANIFEST"

  echo "[INFO] BACKUP STARTED"

  add_file() {
    local f="$1"
    local rel="${f#$ROOT_DIR/}"

    cp --parents "$f" "$WORKDIR"
    echo "$rel" >> "$MANIFEST"
  }

  echo "[INFO] Collecting .bak files..."
  while IFS= read -r f; do
    add_file "$f"
  done < <(find "$ROOT_DIR" -type f -name "*.bak")

  echo "[INFO] Collecting tfvars..."
  while IFS= read -r f; do
    add_file "$f"
  done < <(find "$ROOT_DIR/iac" -path "*/envs/*" -type f -name "*.tfvars")

  echo "[INFO] Uploading backup..."

  tar -czf "$ARCHIVE" -C "$WORKDIR" .

  aws s3 cp \
    "$ARCHIVE" \
    "s3://$S3_BUCKET/$S3_PREFIX/latest.tar.gz"

  echo "[INFO] BACKUP COMPLETE"
}

############################################
# DELETE MODE (SAFE)
############################################
delete_mode() {
  echo "[INFO] DELETE MODE"

  # only tfvars encrypted outputs
  find "$ROOT_DIR/iac" -type f -name "*.enc" -print -delete

  # docker secrets only
  find "$ROOT_DIR/docker" -type f -name "secrets.yml" -print -delete

  # gitops secrets only (not all yaml blindly)
  find "$ROOT_DIR/gitops/secrets" -type f -name "*.yml" -print -delete
  find "$ROOT_DIR/gitops/secrets" -type f -name "*.yaml" -print -delete
}

############################################
# RECOVER MODE
############################################
recover_mode() {
  echo "[INFO] RECOVER MODE..."

  TMP="/tmp/paragon-restore"
  rm -rf "$TMP"
  mkdir -p "$TMP"

  S3_FILE="s3://$S3_BUCKET/$S3_PREFIX/latest.tar.gz"

  ########################################
  # helper: try S3 download once (lazy)
  ########################################
  fetch_s3() {
    if [[ ! -f "$TMP/latest.tar.gz" ]]; then
      echo "[INFO] Downloading from S3..."
      aws s3 cp "$S3_FILE" "$TMP/latest.tar.gz" || return 1
      tar -xzf "$TMP/latest.tar.gz" -C "$TMP"
    fi
  }

  ########################################
  # 1. GITOPS RECOVERY
  ########################################
  echo "[INFO] Recovering gitops..."

  if compgen -G "$ROOT_DIR/gitops/secrets/*.bak" > /dev/null; then
    echo "[INFO] Local gitops backup found"
    for f in "$ROOT_DIR"/gitops/secrets/*.bak; do
      dest="${f%.bak}"
      cp -f "$f" "$dest"
      echo "[RESTORED LOCAL GITOPS] $dest"
    done
  else
    echo "[INFO] No local gitops backup → S3 fallback"
    fetch_s3
    for f in "$TMP"/paragon/gitops/secrets/*.bak; do
      [[ -f "$f" ]] || continue
      rel="${f#$TMP/paragon/}"
      dest="$ROOT_DIR/${rel%.bak}"
      mkdir -p "$(dirname "$dest")"
      cp -f "$f" "$dest"
      echo "[RESTORED S3 GITOPS] $dest"
    done
  fi

  ########################################
  # 2. DOCKER RECOVERY
  ########################################
  echo "[INFO] Recovering docker..."

  if find "$ROOT_DIR/docker" -name "*.bak" | grep -q .; then
    echo "[INFO] Local docker backup found"

    find "$ROOT_DIR/docker" -type f -name "*.bak" | while read -r f; do
      dest="${f%.bak}"
      cp -f "$f" "$dest"
      echo "[RESTORED LOCAL DOCKER] $dest"
    done
  else
    echo "[INFO] No local docker backup → S3 fallback"
    fetch_s3
    find "$TMP/paragon/docker" -type f -name "*.bak" | while read -r f; do
      rel="${f#$TMP/paragon/}"
      dest="$ROOT_DIR/${rel%.bak}"
      mkdir -p "$(dirname "$dest")"
      cp -f "$f" "$dest"
      echo "[RESTORED S3 DOCKER] $dest"
    done
  fi

  ########################################
  # 3. IAC RECOVERY
  ########################################
  echo "[INFO] Recovering iac..."

  if find "$ROOT_DIR/iac" -type f -name "*.tfvars" | grep -q .; then
    echo "[INFO] Local tfvars found"

    find "$ROOT_DIR/iac" -path "*/envs/*" -type f -name "*.tfvars" | while read -r f; do
      echo "[PRESENT LOCAL TFVARS] $f"
    done
  else
    echo "[INFO] No local tfvars → S3 fallback"
    fetch_s3
    find "$TMP/paragon/iac" -type f -name "*.tfvars" | while read -r f; do
      rel="${f#$TMP/paragon/}"
      dest="$ROOT_DIR/$rel"
      mkdir -p "$(dirname "$dest")"
      cp -f "$f" "$dest"
      echo "[RESTORED S3 TF] $dest"
    done
  fi

  echo "[INFO] RECOVERY COMPLETE"
}

############################################
# ROUTER
############################################
case "$MODE" in
  backup) backup_mode ;;
  delete) delete_mode ;;
  recover) recover_mode ;;
esac

echo "=================================================="
echo "[INFO] DONE"
echo "=================================================="

