output "efs_id" {
  value = aws_efs_file_system.this.id
}

output "efs_dns_name" {
  value = aws_efs_file_system.this.dns_name
}

output "efs_security_group_id" {
  value = aws_security_group.efs.id
}

output "efs_user_app_ap_id" {
  value = aws_efs_access_point.user_app.id
}

output "efs_admin_app_ap_id" {
  value = aws_efs_access_point.admin_app.id
}

output "efs_monitoring_app_ap_id" {
  value = aws_efs_access_point.monitoring_app.id
}
