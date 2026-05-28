#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# ENI + Classic ELB decision engine (strict chain)
# ============================================================
# FLOW:
# 1. list ENIs
# 2. classify attachment source
# 3. NAT/EFS/subnet => skip
# 4. ELB => validate orphan/cluster-bound
# 5. confirm + delete
# ============================================================

ENV="${ENV:?ENV required}"
REGION="${AWS_REGION:?AWS_REGION required}"
VPC_ID="${VPC_ID:?VPC_ID required}"
CLUSTER_NAME="${CLUSTER_NAME:?CLUSTER_NAME required}"
DRY_RUN="${DRY_RUN:-true}"

log(){ echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

awsq(){ aws "$@" 2>/dev/null || true; }

run(){
  if [[ "$DRY_RUN" == "true" ]]; then
    log "DRY_RUN: $*"
  else
    eval "$@" || true
  fi
}

[[ "$ENV" == "prod" ]] && { log "BLOCKED PROD"; exit 1; }

# ============================================================
# STEP 1: LIST ENIs (VERIFIED)
# ============================================================

log "STEP 1: LIST ENIs"
log "VPC=$VPC_ID REGION=$REGION CLUSTER=$CLUSTER_NAME"

enis=$(awsq ec2 describe-network-interfaces \
  --region "$REGION" \
  --filters Name=vpc-id,Values="$VPC_ID" \
  --query "NetworkInterfaces[].NetworkInterfaceId" \
  --output text)

log "RAW ENI OUTPUT=${enis:-EMPTY}"

if [[ -z "$enis" ]]; then
  log "NO ENIs FOUND - CHECK VPC/REGION/ACCOUNT"
  exit 0
fi

log "ENIs FOUND:"
for eni in $enis; do
  log "FOUND ENI: $eni"
done

# ============================================================
# STEP 2: PROCESS ENIs
# ============================================================

for eni in $enis; do

  log "---- ENI START: $eni ----"

  desc=$(awsq ec2 describe-network-interfaces \
    --region "$REGION" \
    --network-interface-ids "$eni" \
    --query "NetworkInterfaces[0].Description" \
    --output text)

  requester=$(awsq ec2 describe-network-interfaces \
    --region "$REGION" \
    --network-interface-ids "$eni" \
    --query "NetworkInterfaces[0].RequesterId" \
    --output text)

  log "DESC=$desc"
  log "REQUESTER=$requester"

  if [[ "$desc" == *"NAT Gateway"* ]]; then
    log "SKIP NAT"
    continue
  fi

  if [[ "$desc" == *"efs"* || "$desc" == *"EFS"* ]]; then
    log "SKIP EFS"
    continue
  fi

  if [[ "$requester" == "amazon-vpc" ]]; then
    log "SKIP CORE VPC"
    continue
  fi

  if [[ "$desc" == *"ELB"* ]]; then

    lb_name=$(echo "$desc" | grep -oE 'k8s-[a-zA-Z0-9-]+' || true)

    log "ELB CANDIDATE=$lb_name"

    if [[ -n "$lb_name" ]]; then

      state=$(awsq elb describe-load-balancers \
        --region "$REGION" \
        --load-balancer-names "$lb_name" \
        --query "LoadBalancerDescriptions[0].Instances" \
        --output text)

      log "ELB STATE=$state"

      if [[ "$state" == "None" || "$state" == "" ]]; then
        log "ORPHAN ELB CONFIRMED"

        run aws elb delete-load-balancer \
          --region "$REGION" \
          --load-balancer-name "$lb_name"

        run aws ec2 delete-network-interface \
          --region "$REGION" \
          --network-interface-id "$eni"

      else
        log "ELB ACTIVE -> SKIP"
      fi
    fi

    continue
  fi

  if [[ "$desc" == *"aws-K8S-i-"* ]]; then
  log "K8S ENI DETECTED"

    status=$(awsq ec2 describe-network-interfaces \
      --region "$REGION" \
      --network-interface-ids "$eni" \
      --query "NetworkInterfaces[0].Status" \
      --output text | tr -d '\n')

    attachment_state=$(awsq ec2 describe-network-interfaces \
      --region "$REGION" \
      --network-interface-ids "$eni" \
      --query "NetworkInterfaces[0].Attachment.Status" \
      --output text | tr -d '\n')

    requester=$(awsq ec2 describe-network-interfaces \
      --region "$REGION" \
      --network-interface-ids "$eni" \
      --query "NetworkInterfaces[0].RequesterId" \
      --output text | tr -d '\n')

    if [[ "$status" == "available" ]]; then
      log "ENI IS AVAILABLE → SAFE TO DELETE"

      run aws ec2 delete-network-interface \
        --region "$REGION" \
        --network-interface-id "$eni"
    else
      log "ENI STILL ATTACHED → SKIP"
    fi
  fi
done

log "ENGINE COMPLETE"
