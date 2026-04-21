############################################
# OUTPUTS
############################################

output "eks_cluster_role_arn" {
  description = "IAM role ARN for EKS control plane"
  value       = aws_iam_role.eks_cluster.arn
}

output "node_group_role_arn" {
  description = "IAM role ARN for EC2 node group"
  value       = aws_iam_role.node_group.arn
}

output "fargate_role_arn" {
  description = "IAM role ARN for Fargate pods"
  value       = aws_iam_role.fargate.arn
}
