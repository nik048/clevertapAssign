resource "aws_efs_file_system" "wp-uploads" {
  creation_token = "wp-uploads"

  tags = {
    Name = "WP-Upload-NFS"
  }
}

resource "aws_efs_access_point" "wp_uploads_access_point" {
  file_system_id = aws_efs_file_system.wp-uploads.id
  root_directory {
    path = "/wp-uploads"
  
    creation_info {
        owner_gid   = 0
        owner_uid   = 0
        permissions = "755"
    }
  }
}

resource "aws_efs_mount_target" "mount_targets" {
  file_system_id  = aws_efs_file_system.wp-uploads.id
  subnet_id       = var.subnet_id
  security_groups = [aws_security_group.allow_efs_inbound.id]
}

resource "aws_security_group" "allow_efs_inbound" {
  name   = "allow-efs"
  vpc_id = var.vpc_id

  ingress {
    from_port        = 2049
    to_port          = 2049
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}

