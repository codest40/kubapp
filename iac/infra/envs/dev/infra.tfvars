
CERT_ARN       = "arn:aws:acm:us-east-1:198200019771:certificate/a98757d4-69b3-4a6b-a01e-407622169dcc"
main_domain    = "rundailytest.online"
region         = "us-east-1"
cluster_name   = "kubapp"
admin_arn      = "arn:aws:iam::198200019771:user/admin-codest"
access_iam_arn = "arn:aws:iam::198200019771:role/GitHubTerraformRole-dev"
account_id     = "532918215760"
env            = "dev"

log_groups = {
  app_logs = {
    retention = 1
  },
  audit_logs = {
    retention = 3
  },
  cluster_logs = {
    retention = 1
  },
  vpc_logs = {
    retention = 1
  }
}
