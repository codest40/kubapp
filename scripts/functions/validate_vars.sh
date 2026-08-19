fail() {
  echo "❌ $1"
  exit 1
}

require_non_empty() {
  local name="$1"
  local value="$2"

  if [[ -z "$value" || "$value" == "null" ]]; then
    fail "Missing or empty value: $name"
  fi
}
