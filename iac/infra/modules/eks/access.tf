
resource "aws_eks_access_entry" "admin_access" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = var.access_iam_arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "access_admin_policy" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = var.access_iam_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}

