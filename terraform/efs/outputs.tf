output "efs_id" {
  value = "${aws_efs_file_system.wp-uploads.id}"
}

output "efs_access_point" {
  value = "${aws_efs_access_point.wp_uploads_access_point.id}"
}