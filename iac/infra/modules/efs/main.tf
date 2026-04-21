resource "aws_security_group" "efs" {
  name        = "efs-sg"
  description = "Allow NFS access to EFS"
  vpc_id      = var.vpc_id

  ingress {
    description = "NFS"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

resource "aws_efs_file_system" "this" {
  creation_token = "kubapp-efs"

  encrypted = true

  tags = merge(var.tags, {
    Name = "kubapp-efs"
  })
}

resource "aws_efs_mount_target" "this" {
  for_each = {
    for idx, subnet in var.subnet_ids : idx => subnet
  }

  file_system_id  = aws_efs_file_system.this.id
  subnet_id       = each.value
  security_groups = [aws_security_group.efs.id]
}
