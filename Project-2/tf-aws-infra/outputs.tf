output "Source-S3-bucket" {
    value = "${aws_s3_bucket.image_bucket_src.id}"
}
output "Destination-S3-bucket" {
    value = "${aws_s3_bucket.image_bucket_tgt.id}"
}