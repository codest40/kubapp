# envs/dev/backend-k8s.hcl
bucket         = "kubapp-tf-state"
key            = "dev/k8s/terraform.tfstate"
region         = "us-east-1"
dynamodb_table = "kubapp-tf-db"
#use_lockfile  = true
encrypt        = true
