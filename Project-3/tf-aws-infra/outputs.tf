output "Source-S3-bucket" {
    value = "${aws_s3_bucket.user_content_bucket.id}"
}