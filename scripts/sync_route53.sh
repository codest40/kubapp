#!/bin/bash
set -euo pipefail

# -------------------------------
# CONFIG
# -------------------------------
SYNC_MODE="${SYNC_MODE:-apply}"
DOMAIN="${DOMAIN:-rundailytest.online}"
ENV="${ENV:-dev}"
ING_FILE="${INGRESS_FILE:-gitops/ingress/$ENV/values.yaml}"
MON_FILE="${MON_FILE:-gitops/ingress/$ENV/monitoring.yaml}"
ARGO_FILE="${ARGO_FILE:-gitops/ingress/$ENV/argocd.yaml}"
AWS_REGION="${AWS_REGION:-$(aws configure get region)}"
CERT_ARN="${CERT_ARN:-}"

echo "===================================="
echo "Route53 Auto-Provision + Sync"
echo "SYNC_MODE: $SYNC_MODE"
echo "DOMAIN: $DOMAIN"
echo "ENV: $ENV"
echo "AWS_REGION: $AWS_REGION"
echo "===================================="

# SERVICES FROM GITOPS
APP_SERVICES=$(yq e '.services[].name' "$ING_FILE" 2>/dev/null || true)
MON_SERVICES=$(yq e '.services[].name' "$MON_FILE" 2>/dev/null || true)
ARGO_SERVICES=$(yq e '.services[].name' "$ARGO_FILE" 2>/dev/null || true)

ALL_SERVICES=$(printf "%s\n%s\n%s\n" \
  "$APP_SERVICES" \
  "$MON_SERVICES" \
  "$ARGO_SERVICES" \
  | grep -v '^$' \
  | sort -u)

mapfile -t SERVICES <<< "$ALL_SERVICES"

echo "DEBUG SERVICES:"
declare -p SERVICES
# ============================================================
# DESTROY MODE
# ============================================================
if [[ "$SYNC_MODE" == "destroy" ]]; then
  echo "===================================="
  echo "DESTROY MODE (FAST PATH)"
  echo "===================================="

  ZONE_ID=$(aws route53 list-hosted-zones-by-name \
    --dns-name "$DOMAIN" \
    --query "HostedZones[?Name=='${DOMAIN}.'].Id" \
    --output text 2>/dev/null | sed 's|/hostedzone/||')

  if [[ -z "$ZONE_ID" || "$ZONE_ID" == "None" ]]; then
    echo "❌ Hosted zone not found"
    exit 1
  fi

  EXISTING=$(aws route53 list-resource-record-sets \
    --hosted-zone-id "$ZONE_ID")

  for svc in "${SERVICES[@]}"; do
    FQDN="${svc}.${DOMAIN}."

    echo "🗑 Removing: $FQDN"

    RECORD=$(echo "$EXISTING" | jq -c \
      --arg fqdn "$FQDN" \
      '.ResourceRecordSets[]
      | select(.Name == $fqdn)
      | select(.Type == "CNAME")')

    if [[ -n "$RECORD" ]]; then
      aws route53 change-resource-record-sets \
        --hosted-zone-id "$ZONE_ID" \
        --change-batch "{
          \"Changes\": [{
            \"Action\": \"DELETE\",
            \"ResourceRecordSet\": $RECORD
          }]
        }"

      echo "✅ Deleted: $FQDN"
    else
      echo "⚠ Not found: $FQDN"
    fi
  done

  echo "===================================="
  echo "DESTROY COMPLETE"
  echo "===================================="
  exit 0
fi

# ============================================================
# APPLY MODE (FULL VALIDATION PATH)
# ============================================================

# -------------------------------
# PRECHECKS
# -------------------------------
if [[ -z "$AWS_REGION" ]]; then
  echo "❌ AWS region not set"
  exit 1
fi

if [[ -z "$CERT_ARN" ]]; then
  echo "❌ CERT_ARN not provided"
  exit 1
fi

for each in "$ING_FILE" "$MON_FILE" "$ARGO_FILE"; do
  if [[ ! -f "$each" ]]; then
    echo "❌ Ingress File not found: $each"
    exit 1
  fi
done

# -------------------------------
# CERT VALIDATION
# -------------------------------
echo "Validating ACM certificate..."

CERT_STATUS=$(aws acm describe-certificate \
  --region "$AWS_REGION" \
  --certificate-arn "$CERT_ARN" \
  --query "Certificate.Status" \
  --output text 2>/dev/null || true)

if [[ "$CERT_STATUS" != "ISSUED" ]]; then
  echo "❌ Certificate not valid"
  exit 1
fi

echo "✅ Certificate OK"

# -------------------------------
# GET ALB
# -------------------------------
echo "Fetching ALB from ingress..."

ALB=""

for i in {1..15}; do
  ALB_ARN=$(aws elbv2 describe-load-balancers \
    --region "$AWS_REGION" \
    --query "LoadBalancers[?contains(LoadBalancerName, 'kubapp')].LoadBalancerArn | [0]" \
    --output text)

  [[ -n "$ALB_ARN" && "$ALB_ARN" != "None" ]] || {
    echo "❌ No ALB found"
    exit 1
  }

  ALB=$(aws elbv2 describe-load-balancers \
    --region "$AWS_REGION" \
    --load-balancer-arns "$ALB_ARN" \
    --query "LoadBalancers[0].DNSName" \
    --output text)

  if [[ -n "$ALB" ]]; then
    echo "✅ ALB ready: $ALB"
    break
  fi

  echo "⏳ Waiting for ALB ($i/15)"
  sleep 10
done

if [[ -z "$ALB" ]]; then
  echo "❌ ALB never became ready"
  exit 1
fi

# -------------------------------
# VERIFY ALB
# -------------------------------
ALB_ARN=$(aws elbv2 describe-load-balancers \
  --region "$AWS_REGION" \
  --query "LoadBalancers[?DNSName=='$ALB'].LoadBalancerArn | [0]" \
  --output text)

ALB_ZONE_ID=$(aws elbv2 describe-load-balancers \
  --region "$AWS_REGION" \
  --load-balancer-arns "$ALB_ARN" \
  --query "LoadBalancers[0].CanonicalHostedZoneId" \
  --output text)

echo "✅ ALB verified"

# -------------------------------
# HOSTED ZONE
# -------------------------------
ZONE_ID=$(aws route53 list-hosted-zones-by-name \
  --dns-name "$DOMAIN" \
  --query "HostedZones[?Name=='${DOMAIN}.'].Id" \
  --output text 2>/dev/null | sed 's|/hostedzone/||')

ZONE_EXISTS=false

if [[ -z "$ZONE_ID" || "$ZONE_ID" == "None" ]]; then
  CREATE_OUTPUT=$(aws route53 create-hosted-zone \
    --name "$DOMAIN" \
    --caller-reference "$(date +%s)-kubapp")

  ZONE_ID=$(echo "$CREATE_OUTPUT" | jq -r '.HostedZone.Id' | sed 's|/hostedzone/||')

  echo "✅ Hosted zone created"
else
  ZONE_EXISTS=true
  echo "✅ Existing zone"
fi

# -------------------------------
# ROOT DOMAIN
# -------------------------------
echo "Updating root domain..."

aws route53 change-resource-record-sets \
  --hosted-zone-id "$ZONE_ID" \
  --change-batch "{
    \"Changes\": [{
      \"Action\": \"UPSERT\",
      \"ResourceRecordSet\": {
        \"Name\": \"$DOMAIN\",
        \"Type\": \"A\",
        \"AliasTarget\": {
          \"HostedZoneId\": \"$ALB_ZONE_ID\",
          \"DNSName\": \"$ALB\",
          \"EvaluateTargetHealth\": false
        }
      }
    }]
  }"

# -------------------------------
# SUBDOMAINS
# -------------------------------
echo "Updating subdomains (auto-reconcile mode)..."

for svc in "${SERVICES[@]}"; do
  FQDN="$svc.$DOMAIN"
  FQDN_DOT="${FQDN}."

  echo "------------------------------------"
  echo "Processing: $FQDN"

  EXISTING=$(aws route53 list-resource-record-sets \
    --hosted-zone-id "$ZONE_ID" \
    --query "ResourceRecordSets[?Name=='$FQDN_DOT']" \
    --output json)

  EXISTING_TYPE=$(echo "$EXISTING" | jq -r '.[0].Type // empty')

  NEEDS_DELETE=false

  # -------------------------------
  # CASE 1: No record exists
  # -------------------------------
  if [[ -z "$EXISTING_TYPE" ]]; then
    echo "STATE: NO_RECORD"

  # -------------------------------
  # CASE 2: Same type exists
  # -------------------------------
  elif [[ "$EXISTING_TYPE" == "CNAME" ]]; then
    echo "STATE: EXISTS_CNAME"

  # -------------------------------
  # CASE 3: Conflict detected
  # -------------------------------
  else
    echo "STATE: CONFLICT type=$EXISTING_TYPE"
    echo "ACTION: DELETE_REQUIRED"
    NEEDS_DELETE=true
  fi

  # -------------------------------
  # DELETE PHASE (SAFE + VERIFIED)
  # -------------------------------
  if [[ "$NEEDS_DELETE" == true ]]; then

    DELETE_PAYLOAD=$(echo "$EXISTING" | jq '.[0]')

    DELETE_CHANGE_ID=$(aws route53 change-resource-record-sets \
      --hosted-zone-id "$ZONE_ID" \
      --change-batch "{
        \"Changes\": [{
          \"Action\": \"DELETE\",
          \"ResourceRecordSet\": $DELETE_PAYLOAD
        }]
      }" \
      --query "ChangeInfo.Id" \
      --output text)

    echo "DELETE_SUBMITTED id=$DELETE_CHANGE_ID"

    aws route53 wait resource-record-sets-changed \
      --id "$DELETE_CHANGE_ID"

    echo "DELETE_CONFIRMED"
  fi

  # -------------------------------
  # UPSERT PHASE (ALWAYS SAFE NOW)
  # -------------------------------
  UPSERT_CHANGE_ID=$(aws route53 change-resource-record-sets \
    --hosted-zone-id "$ZONE_ID" \
    --change-batch "{
      \"Changes\": [{
        \"Action\": \"UPSERT\",
        \"ResourceRecordSet\": {
          \"Name\": \"$FQDN\",
          \"Type\": \"CNAME\",
          \"TTL\": 60,
          \"ResourceRecords\": [{\"Value\": \"$ALB\"}]
        }
      }]
    }" \
    --query "ChangeInfo.Id" \
    --output text)

  echo "UPSERT_SUBMITTED id=$UPSERT_CHANGE_ID"
  echo "→ $FQDN reconciled"

done

echo "===================================="
echo "DNS SYNC COMPLETE"
echo "===================================="
