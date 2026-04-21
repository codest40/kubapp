#!/bin/bash

set -e

echo "Cleaning EKS CloudWatch log groups..."

# ---------------------------
# Detect environment
# ---------------------------
ENV=${1:-dev}

echo "Detected environment: $ENV"

PROJECT="kubapp"

# ---------------------------
# Build env-aware log groups
# ---------------------------
EKS_LOG_GROUP="/aws/eks/${PROJECT}-${ENV}/cluster"
VPC_LOG_GROUP="/aws/vpc/${PROJECT}-${ENV}-flowlogs"

# ---------------------------
# Delete safely
# ---------------------------
delete_log_group () {
  local log_group=$1

  if [ "$ENV" = "prod" ]; then
    echo "⚠️ Refusing to delete prod logs without explicit confirmation"
    read -p "Type 'yes' to continue: " confirm
    if [ "$confirm" != "yes" ]; then
      exit 1
    fi
  fi

  if aws logs describe-log-groups --log-group-name-prefix "$log_group" \
    | grep -q "$log_group"; then

    echo "Deleting $log_group ..."
    aws logs delete-log-group --log-group-name "$log_group"
    echo "Deleted $log_group"
  else
    echo "Skipping $log_group (not found)"
  fi
}

delete_log_group "$EKS_LOG_GROUP"
delete_log_group "$VPC_LOG_GROUP"

echo "✅ Cleanup done for env: $ENV"
