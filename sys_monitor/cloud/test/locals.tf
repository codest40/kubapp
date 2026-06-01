data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  arn        = data.aws_caller_identity.current.arn

  raw_user = element(split("/", local.arn), length(split("/", local.arn)) - 1)

  project_name = "proj-${local.raw_user}-${local.account_id}"
}
