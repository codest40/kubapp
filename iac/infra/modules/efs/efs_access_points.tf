
resource "aws_efs_access_point" "user_app" {
  file_system_id = aws_efs_file_system.this.id

  posix_user {
    uid = 1000
    gid = 1000
  }

  root_directory {
    path = "/user-app"

    creation_info {
      owner_uid   = 1000
      owner_gid   = 1000
      permissions = "750"
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "user-app-ap-${var.name_prefix}"
  })
}

resource "aws_efs_access_point" "admin_app" {
  file_system_id = aws_efs_file_system.this.id

  posix_user {
    uid = 1001
    gid = 1001
  }

  root_directory {
    path = "/admin-app"

    creation_info {
      owner_uid   = 1001
      owner_gid   = 1001
      permissions = "750"
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "admin-app-ap-${var.name_prefix}"
  })
}


resource "aws_efs_access_point" "monitoring_app" {
  file_system_id = aws_efs_file_system.this.id

  posix_user {
    uid = 1002
    gid = 1002
  }

  root_directory {
    path = "/monitoring_app"

    creation_info {
      owner_uid   = 1002
      owner_gid   = 1002
      permissions = "750"
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "monitoring-app-ap-${var.name_prefix}"
  })
}
