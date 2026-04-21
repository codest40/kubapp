#!/usr/bin/env bash
set -euo pipefail

ENV="${1:-dev}"

echo "=============================="
echo "SYSTEM VALIDATION STARTED"
echo "ENV: $ENV"
echo "=============================="

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

############################################
# HELPERS
############################################
fail() {
  echo "❌ $1"
  exit 1
}

check_file() {
  [[ -f "$1" ]] || fail "Missing file: $1"
}

check_dir() {
  [[ -d "$1" ]] || fail "Missing directory: $1"
}

############################################
# 0. GITIGNORE CHECK
############################################
echo "Checking .gitignore..."

check_file ".gitignore"

if [[ ! -s ".gitignore" ]]; then
  fail ".gitignore exists but is empty"
fi

echo "✅ .gitignore OK"

############################################
# 1. REQUIRED TOOLS
############################################
echo "Checking required tools..."

TOOLS=(terraform sops age yq jq git)

for tool in "${TOOLS[@]}"; do
  command -v "$tool" >/dev/null 2>&1 || fail "Missing tool: $tool"
done

echo "✅ Tools OK"

############################################
# 2. PROJECT STRUCTURE
############################################
echo "Validating structure..."

check_dir "$ROOT_DIR/iac"
check_dir "$ROOT_DIR/iac/infra"
check_dir "$ROOT_DIR/iac/k8s"
check_dir "$ROOT_DIR/gitops"
check_dir "$ROOT_DIR/scripts"

for stack in infra k8s; do
  for env in dev prod; do
    check_dir "$ROOT_DIR/iac/$stack/envs/$env"
    check_file "$ROOT_DIR/iac/$stack/envs/$env/backend.hcl"
  done
done

echo "✅ Structure OK"

############################################
# 3. TERRAFORM FILE VALIDATION (NO INIT)
############################################
echo "Validating Terraform files..."

for stack in infra k8s; do
  DIR="iac/$stack"

  check_dir "$DIR"

  if ! find "$DIR" -maxdepth 1 -name "*.tf" | grep -q .; then
    fail "No Terraform files found in $DIR"
  fi

  terraform fmt -check "$DIR"  \
    || fail "Terraform format/syntax issue in $DIR"
done

echo "✅ Terraform files OK"

############################################
# 4. SECRETS FILE PRESENCE (NO DECRYPT)
############################################
echo "Checking secrets files..."

for stack in infra k8s; do
  BASE="iac/$stack/envs/$ENV"

  check_file "$BASE/${stack}.tfvars"

  if [[ -f "$BASE/${stack}.enc.json" ]]; then
    :
  else
    echo "Warning: Missing encrypted file for $stack/$ENV"
  fi
done

echo "✅ Secrets presence OK"

############################################
# 5. YAML VALIDATION
############################################
echo "Validating YAML..."

mapfile -t yamls < <(find . -type f \( -name "*.yml" -o -name "*.yaml" \))

#helm template gitops/ingress/chart > /tmp/rendered.yaml
#yq e '.' /tmp/rendered.yaml >/dev/null

for file in "${yamls[@]}"; do
  if [[ "$file" == *"templates/"* ]]; then
    echo "Skipping Helm template: $file"
    continue
  fi
  yq e '.' "$file" >/dev/null || fail "Invalid YAML: $file"
done

echo "✅ YAML OK"

############################################
# 6. BASIC GITOPS STRUCTURE CHECK
############################################
echo "Checking GitOps structure..."

check_dir "gitops/infra"
check_dir "gitops/apps"

echo "✅ GitOps structure OK"

############################################
# 7. SCRIPT VALIDATION
############################################
echo "Validating shell scripts..."

if command -v shellcheck >/dev/null 2>&1; then
  find scripts -type f -name "*.sh" -exec shellcheck {} \; \
    || fail "Shellcheck failed"
else
  echo "Skipping shellcheck"
fi

echo "✅ Scripts OK"

############################################
# 8. SANITY CHECKS
############################################
echo "Running sanity checks..."

if find . -type d -name ".terraform" | grep -q .; then
  echo "Warning: .terraform directories detected"
fi

if grep -r "aws_secret_access_key" . --exclude-dir=.git >/dev/null 2>&1; then
  echo "Warning: Possible secret detected in repo"
fi

echo "✅ Sanity checks OK"

############################################
# DONE
############################################
echo "=============================="
echo "✅ ALL VALIDATIONS PASSED"
echo "=============================="
