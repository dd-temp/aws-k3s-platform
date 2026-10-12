output "instance_id" {
  value = aws_instance.app_server.id
}

output "s3_bucket_id" {
  value = aws_s3_bucket.data.id
}