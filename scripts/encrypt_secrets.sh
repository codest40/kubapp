#!/usr/bin/env bash
set -euo pipefail

ROOT="../iac"
STACKS=("infra" "k8s")

ENV="${1:-dev}"   # dev | prod | all

# =========================
# LOAD SETUP FUNCTIONS
# =========================
SETUP="./setup_sops.sh"
SETUP1="scripts/setup_sops.sh"
if [[ -f "$SETUP" ]]; then
  echo "Sourcing $SETUP"
  source "$SETUP"
elif [[ -f "$SETUP1" ]]; then
  echo "Sourcing $SETUP1"
  source "$SETUP1"
else
  echo "❌ setup_sops.sh not found"
  exit 1
fi

echo "Checking prerequisites..."

install_sops
install_age
ensure_age_key

AGE_PUBLIC_KEY=$(get_age_public_key)

if [[ -z "$AGE_PUBLIC_KEY" ]]; then
  echo "❌ Could not extract AGE public key"
  exit 1
fi

echo " Using AGE key: $AGE_PUBLIC_KEY"

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
      echo "❌ Invalid env: $ENV"
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

  echo "Encrypting: $file → $out"

  sops --encrypt \
    --age "$AGE_PUBLIC_KEY" \
    "$file" > "$out"
}

# =========================
# MAIN LOOP
# =========================
echo " Starting encryption for ENV=$ENV"

for env in $(get_envs); do
  echo ""
  echo "ENV: $env"

  for stack in "${STACKS[@]}"; do
    DIR="$ROOT/$stack/envs/$env"

    [[ -d "$DIR" ]] || continue

    echo "   → Stack: $stack"

    for tfvars in "$DIR"/*.tfvars; do
      [[ -f "$tfvars" ]] || continue
      encrypt_tfvars "$tfvars"
    done
  done
done

echo ""
echo "✅ Encryption complete"
