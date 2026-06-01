#!/bin/bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd)/runtime.sh"

EVIDENCE_DIR="${EVIDENCE_DIR}"
OUTPUT_FILE="${EVIDENCE_DIR}/metrics.prom"

> "$OUTPUT_FILE"

log_info "metrics engine starting"

emit() {
    echo "$1" >> "$OUTPUT_FILE"
}

status_to_value() {
    case "$1" in
        pass|completed|success)
            echo 1
            ;;
        *)
            echo 0
            ;;
    esac
}

# ============================================================
# PLATFORM METADATA
# ============================================================

emit "kubapp_last_scan_timestamp $(date +%s)"
emit "kubapp_scan_success 1"

platform_health_total=0
platform_health_count=0

# ============================================================
# PROCESS EVIDENCE FILES
# ============================================================

for file in "${EVIDENCE_DIR}"/*.json; do
    [[ ! -f "$file" ]] && continue

    module=$(jq -r '.module // "unknown"' "$file" | tr '[:upper:]' '[:lower:]')

    status=$(jq -r '.status // "unknown"' "$file")
    status_value=$(status_to_value "$status")

    total_checked=$(jq -r '.summary.total_checked // 0' "$file")

    findings_total=$(jq -r '.findings // [] | length' "$file")

    critical=$(jq -r '.summary.critical // 0' "$file")
    warnings=$(jq -r '.summary.warnings // 0' "$file")
    errors=$(jq -r '.summary.errors // 0' "$file")

    # ========================================================
    # MODULE STATUS
    # ========================================================

    emit "kubapp_module_status{module=\"${module}\"} ${status_value}"

    emit "kubapp_total_checked{module=\"${module}\"} ${total_checked}"

    emit "kubapp_findings_total{module=\"${module}\"} ${findings_total}"

    emit "kubapp_critical_total{module=\"${module}\"} ${critical}"
    emit "kubapp_warning_total{module=\"${module}\"} ${warnings}"
    emit "kubapp_error_total{module=\"${module}\"} ${errors}"

    # ========================================================
    # FINDING TYPES
    # ========================================================

    jq -r '
        .findings // []
        | group_by(.type)
        | map({
            type: .[0].type,
            count: length
          })
        | .[]
        | "kubapp_finding_type_total{type=\"" +
          (.type|tostring) +
          "\"} " +
          (.count|tostring)
    ' "$file" >> "$OUTPUT_FILE"

    # ========================================================
    # MODULE HEALTH SCORE
    # ========================================================

    case "$module" in

        drift)
            score=100
            ;;

        architecture)
            score=$(jq -r '.summary.architecture_score // 100' "$file")
            ;;

        security)
            score=$((100 - critical*10 - warnings*2))
            ;;

        validation)
            score=$((100 - warnings))
            ;;

        discovery)
            score=100
            ;;

        *)
            score=100
            ;;
    esac

    (( score < 0 )) && score=0
    (( score > 100 )) && score=100

    emit "kubapp_module_score{module=\"${module}\"} ${score}"

    # ========================================================
    # PLATFORM HEALTH INPUTS
    # ========================================================

    case "$module" in
        discovery)
            ;;
        *)
            platform_health_total=$((platform_health_total + score))
            platform_health_count=$((platform_health_count + 1))
            ;;
    esac

done

# ============================================================
# INVENTORY METRICS
# ============================================================

inventory_file="${EVIDENCE_DIR}/inventory.json"

if [[ -f "$inventory_file" ]]; then

  emit "kubapp_total_files $(jq -r '.statistics.all_files_count // 0' "$inventory_file")"

  emit "kubapp_total_workflows $(jq -r '.statistics.workflow_count // 0' "$inventory_file")"

  emit "kubapp_total_shell_scripts $(jq -r '.statistics.shell_script_count // 0' "$inventory_file")"

  emit "kubapp_total_terraform_roots $(jq -r '.statistics.terraform_root_count // 0' "$inventory_file")"

  emit "kubapp_total_terraform_modules $(jq -r '.statistics.terraform_module_count // 0' "$inventory_file")"

  emit "kubapp_total_dockerfiles $(jq -r '.statistics.dockerfile_count // 0' "$inventory_file")"

  emit "kubapp_total_k8s_manifests $(jq -r '.statistics.k8s_manifest_count // 0' "$inventory_file")"

fi

# ============================================================
# PLATFORM HEALTH
# ============================================================

if (( platform_health_count > 0 )); then
    platform_health=$((platform_health_total / platform_health_count))
else
    platform_health=100
fi

emit "kubapp_platform_health ${platform_health}"

log_info "metrics written to ${OUTPUT_FILE}"
