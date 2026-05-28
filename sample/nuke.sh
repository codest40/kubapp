#!/usr/bin/env bash
set -euo pipefail

ENV="${1:?ENV required (dev/staging/prod)}"
PROJECT="kubapp"
REGION="us-east-1"

PREFIX="${PROJECT}-${ENV}"

echo "========================================"
echo "CLEANUP STARTING"
echo "ENV: $ENV"
echo "PREFIX: $PREFIX"
echo "========================================"

############################################
# 1. DELETE CLOUDFORMATION (IF ANY)
############################################
echo ""
echo " Checking CloudFormation stacks..."

aws cloudformation list-stacks \
  --region "$REGION" \
  --query "StackSummaries[?contains(StackName, '${PREFIX}')].StackName" \
  --output text | while read -r stack; do

  if [[ -n "$stack" ]]; then
    echo "Deleting stack: $stack"
    aws cloudformation delete-stack \
      --stack-name "$stack" \
      --region "$REGION"
  fi
done

############################################
# 2. DELETE IAM ROLES (SAFE PREFIX MATCH)
############################################
echo ""
echo " Deleting IAM roles..."

for role in \
  "${PREFIX}-cluster-role" \
  "${PREFIX}-nodegroup-role" \
  "${PREFIX}-fargate-role" \
  "${PREFIX}-vpc-flow-logs-role"
do
  if aws iam get-role --role-name "$role" >/dev/null 2>&1; then
    echo "Deleting role: $role"

    aws iam detach-role-policy \
      --role-name "$role" \
      --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy \
      2>/dev/null || true

    aws iam delete-role --role-name "$role" || true
  fi
done

############################################
# 3. DELETE CLOUDWATCH LOG GROUPS
############################################
echo ""
echo "Deleting CloudWatch log groups..."

LOG_GROUPS=(
  "/aws/eks/${PREFIX}/cluster"
  "/kubapp/${ENV}/app-logs"
  "/kubapp/${ENV}/audit-logs"
  "/aws/vpc/${PREFIX}-flowlogs"
)

for lg in "${LOG_GROUPS[@]}"; do
  if aws logs describe-log-groups \
    --log-group-name-prefix "$lg" \
    --region "$REGION" \
    | grep -q logGroupName; then

    echo "Deleting log group: $lg"
    aws logs delete-log-group \
      --log-group-name "$lg" \
      --region "$REGION" || true
  fi
done

############################################
# 4. DELETE EFS FILE SYSTEM (CRITICAL FIX)
############################################
echo ""
echo " Checking EFS..."

EFS_ID=$(aws efs describe-file-systems \
  --region "$REGION" \
  --query "FileSystems[?Name=='${PREFIX}-efs'].FileSystemId" \
  --output text)

if [[ -n "$EFS_ID" && "$EFS_ID" != "None" ]]; then
  echo "Deleting EFS: $EFS_ID"

  aws efs delete-file-system \
    --file-system-id "$EFS_ID" \
    --region "$REGION" || true
fi

############################################
# 5. SUMMARY
############################################
echo ""
echo "========================================"
echo "✅ CLEANUP DONE"
echo "========================================"

