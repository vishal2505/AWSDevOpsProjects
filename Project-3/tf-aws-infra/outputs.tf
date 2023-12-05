output "Source-S3-bucket" {
    value = aws_s3_bucket.user_content_bucket.id
}

output "File-Uploader-App-bucket" {
    value = aws_s3_bucket.file_uploader_app_bucket.id
}

output "fileuploader-api-endpoint" {
    value = aws_api_gateway_rest_api.FileUploderService.id
}

output "fileuploader-app-url" {
    value = aws_cloudfront_distribution.s3_distribution.domain_name
}