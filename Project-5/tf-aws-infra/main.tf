#define variables

# Create S3 buckets for uploading image files
resource "aws_s3_bucket" "user_content_bucket" {
  bucket = var.user_bucket
  force_destroy = true
}

resource "aws_s3_bucket_ownership_controls" "user_content_bucket" {
  bucket = aws_s3_bucket.user_content_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "user_content_bucket" {
  depends_on = [aws_s3_bucket_ownership_controls.user_content_bucket]

  bucket = aws_s3_bucket.user_content_bucket.id
  acl    = "private"
}

# Enabling CORS for the S3 bucket
resource "aws_s3_bucket_cors_configuration" "user_content_bucket_cors" {
  bucket = aws_s3_bucket.user_content_bucket.id
  depends_on = [aws_cloudfront_distribution.s3_distribution]

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST", "DELETE"]
    allowed_origins = ["https://${aws_cloudfront_distribution.s3_distribution.domain_name}"]
    expose_headers  = []
  }
}

# Creating S3 bucket and cloudFront Distribution for the web app - (front-end)

resource "aws_s3_bucket" "file_uploader_app_bucket" {
  bucket = var.webapp_bucket
  force_destroy = true
}

resource "aws_s3_bucket_ownership_controls" "file_uploader_app_bucket_owner" {
  bucket = aws_s3_bucket.file_uploader_app_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "file_uploader_app_bucket_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.file_uploader_app_bucket_owner]
  bucket = aws_s3_bucket.file_uploader_app_bucket.id
  acl    = "private"
}

locals {
  s3_origin_id = "FileUploaderS3Origin"
}

resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "fileuploader-oac"
  description                       = "File Uploader Policy"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}
resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name              = aws_s3_bucket.file_uploader_app_bucket.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
    origin_id                = local.s3_origin_id
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Distribution for AWS S3 Image app"
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  price_class = "PriceClass_200"

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  tags = {
    Environment = "production"
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

# Bucket policy for Cloudfront to access

data "aws_iam_policy_document" "allow_access_from_cloudfront" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions = [
      "s3:GetObject",
      "s3:ListBucket",
    ]

    resources = [
      aws_s3_bucket.file_uploader_app_bucket.arn,
      "${aws_s3_bucket.file_uploader_app_bucket.arn}/*",
    ]
    condition {
      test = "StringEquals"
      variable = "AWS:SourceArn"
      values = ["arn:aws:cloudfront::${var.aws_account_id}:distribution/${aws_cloudfront_distribution.s3_distribution.id}"]
                
    }
  }
}
resource "aws_s3_bucket_policy" "allow_access_from_cloudfront" {
  bucket = aws_s3_bucket.file_uploader_app_bucket.id
  policy = data.aws_iam_policy_document.allow_access_from_cloudfront.json
}