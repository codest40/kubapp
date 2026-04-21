# envs/dev/backend-infra.hcl
bucket         = "kubapp-tf-state"
key            = "dev/infra/terraform.tfstate"
region         = "us-east-1"
#use_lockfile = true
dynamodb_table = "kubapp-tf-db"
encrypt        = true
