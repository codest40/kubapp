validate_and_echo_manifest() {
  local FILE="$1"

  [[ ! -f "$FILE" ]] && {
    echo "❌ Manifest not found: $FILE"
    return 1
  }

  echo "Checking: $FILE"
  echo "----------------------"

  while IFS= read -r key; do

    value=$(jq -r --arg k "$key" '.[$k] // empty' "$FILE")

    # print always
    if [[ -z "$value" || "$value" == "null" ]]; then
      echo "❌ $key = <EMPTY>"
      return 1
    else
      echo "✔ $key = $value"
    fi

  done < <(jq -r 'keys[]' "$FILE")

  echo "----------------------"
  echo "✅ Manifest valid"
}
