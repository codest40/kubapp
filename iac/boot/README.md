### ------------------------------------------------------------
# FOUNDATION LAYER (boot/)
### ------------------------------------------------------------

# Purpose:
Our aim is to separate state entirely from the rest of infra provision so we can easily manage them.
It Initializes Terraform remote state backend before any infra.

# Components:
# - S3 bucket → state storage
# - DynamoDB → state locking
# - provider configuration
# - Terraform version pinning

# Key files:

# boot/
# ├── s3.tf
# ├── dynamodb.tf
# ├── provider.tf
# ├── terraform.tfstate
# ├── terraform.tfvars


# Execution flow:

# terraform init
# terraform apply

# Guarantees:

# - Remote state storage enabled
# - State locking enabled
# - Multi-user safety
# - No local state dependency

