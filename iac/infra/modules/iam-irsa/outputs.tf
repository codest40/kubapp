############################################
# OUTPUTS
############################################

output "lb_controller_role_arn" {
  description = "IAM role ARN for AWS Load Balancer Controller"
  value       = aws_iam_role.lb_controller.arn
}

output "fluentbit_role_arn" {
  description = "IAM role ARN for Fluntbitr"
  value       = aws_iam_role.fluentbit.arn
}

output "efs_role_arn" {
  value = aws_iam_role.efs_csi_role.arn
}

output "external_dns_role_arn" {
  value = aws_iam_role.external_dns.arn
}
