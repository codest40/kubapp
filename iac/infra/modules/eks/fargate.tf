resource "aws_eks_fargate_profile" "workloads" {
  for_each = toset(var.fargate_workloads)

  cluster_name           = aws_eks_cluster.this.name
  fargate_profile_name   = "${var.cluster_name}-${each.value}"
  pod_execution_role_arn = var.fargate_role_arn

  subnet_ids = var.private_subnet_ids

  selector {
    namespace = each.value
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-${each.value}-fargate"
  })
}

resource "aws_security_group" "fargate_pods" {
  name   = "${var.cluster_name}-fargate-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"

    security_groups = [
      var.sg_ids["ec2_app"]
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}
