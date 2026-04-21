
resource "aws_cloudwatch_log_group" "logs" {
  for_each = var.log_groups

  name              = each.value.name
  retention_in_days = each.value.retention
  tags              = var.tags

}

