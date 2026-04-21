# Load balancers (MOST COMMON)
aws elbv2 describe-load-balancers

# Target groups
aws elbv2 describe-target-groups

# ENIs (EKS leaves these behind temporarily)
aws ec2 describe-network-interfaces --filters Name=vpc-id,Values=VPC_ID

# Security groups
aws ec2 describe-security-groups --filters Name=vpc-id,Values=VPC_ID

# EFS mount targets
aws efs describe-mount-targets --file-system-id FS_ID

# VPC endpoints
aws ec2 describe-vpc-endpoints --filters Name=vpc-id,Values=VPC_ID

