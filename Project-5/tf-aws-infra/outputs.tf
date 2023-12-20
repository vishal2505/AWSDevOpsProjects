output "User-S3-bucket" {
    value = aws_s3_bucket.user_content_bucket.id
}

output "web-app-bucket" {
    value = aws_s3_bucket.file_uploader_app_bucket.id
}

output "Web-app-cdn" {
    value = aws_cloudfront_distribution.s3_distribution.domain_name
}