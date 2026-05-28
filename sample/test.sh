#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="./docker"

echo "======================================"
echo "🔍 DEEP DOCKER APP INSPECTOR"
echo "======================================"

for app in "$BASE_DIR"/*; do
  [[ -d "$app" ]] || continue

  echo ""
  echo "📦 APP: $(basename "$app")"
  echo "======================================"

  echo "📁 FULL TREE:"
  find "$app" -type f | sed "s|$app/||"
  echo ""

  echo "📄 FILE CONTENTS:"
  echo "--------------------------------------"

  while IFS= read -r file; do
    echo ""
    echo "➡️ $file"
    echo "--------------------------------------"

    # FIX: use correct path (NO double prefix)
    sed -n '1,200p' "$file"

    echo ""
    echo "--------------------------------------"
  done < <(find "$app" -type f)

  echo ""
  echo "======================================"
done
