locals {
  oidc_provider = replace(var.oidc_provider_url, "https://", "")
}

resource "aws_iam_policy" "efs_csi_policy" {
  name = "${var.cluster_name}-EFSCSIDriverPolicy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "elasticfilesystem:DescribeAccessPoints",
          "elasticfilesystem:DescribeFileSystems",
          "elasticfilesystem:DescribeMountTargets",
          "elasticfilesystem:CreateAccessPoint",
          "elasticfilesystem:DeleteAccessPoint",
          "elasticfilesystem:ClientMount",
          "elasticfilesystem:ClientWrite",
          "elasticfilesystem:ClientRootAccess"
        ]
        Resource = "*"
      }
    ]
  })
  tags = var.tags

}

resource "aws_iam_role" "efs_csi_role" {
  name = "${var.cluster_name}-efs-csi-driver-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringLike = {
            "${local.oidc_provider}:sub" = "system:serviceaccount:kube-system:efs-csi-*"
          }
        }
      }
    ]
  })
  tags = var.tags

}

resource "aws_iam_role_policy_attachment" "efs_csi_attach" {
  role       = aws_iam_role.efs_csi_role.name
  policy_arn = aws_iam_policy.efs_csi_policy.arn
}


