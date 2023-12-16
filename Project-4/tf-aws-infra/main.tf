#define variables

# Create S3 buckets for uploading user content from API Gateway Endpoint
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

# Create an IAM role for Lambda
resource "aws_iam_role" "api_gateway_role" {
  name = "APIGatewayRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "apigateway.amazonaws.com"
      }
    }]
  })
}

# Create S3 policy for API Gateway role to put objects to S3 bucket and send logs to CloudWatch
data "aws_iam_policy_document" "policy" {
  statement {
    effect    = "Allow"
    actions   = ["s3:PutObject", "logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_s3_bucket.user_content_bucket.arn}/*"]
  }
}
resource "aws_iam_policy" "policy" {
  name        = "s3-put-policy"
  policy      = data.aws_iam_policy_document.policy.json
}

# Attach the AWSLambdaBasicExecutionRole policy to the IAM role
resource "aws_iam_role_policy_attachment" "apigateway_role_policy" {
  policy_arn = aws_iam_policy.policy.arn
  role       = aws_iam_role.api_gateway_role.name
}


# Creating API Gateway
resource "aws_api_gateway_rest_api" "FileUploderAPI" {
  name = "FileUploderAPI"
  description = "Uploads content to your S3 bucket"
  binary_media_types = ["image/jpg", "image/jpeg", "image/png", "application/pdf"]
}

# Creating the resource for uploading files - {bucket}/{filename}
resource "aws_api_gateway_resource" "upload_resource_bucket" {
  parent_id   = aws_api_gateway_rest_api.FileUploderAPI.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.FileUploderAPI.id
  path_part   = "{bucket}"
}

resource "aws_api_gateway_resource" "upload_resource" {
  parent_id   = aws_api_gateway_resource.upload_resource_bucket.id   //parent is resource - {bucket}
  rest_api_id = aws_api_gateway_rest_api.FileUploderAPI.id
  path_part   = "{filename}"
}

# Defining the PUT method for uploading files
resource "aws_api_gateway_method" "upload_method" {
  authorization = "AWS_IAM"
  http_method   = "PUT"
  resource_id   = aws_api_gateway_resource.upload_resource.id
  rest_api_id   = aws_api_gateway_rest_api.FileUploderAPI.id

  request_parameters = {

    "method.request.path.bucket" = true
    "method.request.path.filename"   = true
  }
}

# Creating the integration with S3 service (No Lambda function here)
resource "aws_api_gateway_integration" "s3_integration" {
  rest_api_id = aws_api_gateway_method.upload_method.rest_api_id
  resource_id = aws_api_gateway_method.upload_method.resource_id
  http_method = aws_api_gateway_method.upload_method.http_method
  type = "AWS"
  integration_http_method = "PUT"
  credentials             = "${aws_iam_role.api_gateway_role.arn}"
  #uri = "arn:aws:s3:::${aws_s3_bucket.user_content_bucket.arn}/{path}"
  uri = "arn:aws:apigateway:${var.aws_region}:s3:path/{bucket}/{filename}"
  passthrough_behavior = "WHEN_NO_MATCH"
  # Path parameter mappings
  request_parameters = {
    "integration.request.path.filename"   = "method.request.path.filename"
    "integration.request.path.bucket" = "method.request.path.bucket"
  }
}


# Method/integration response and CORS

resource "aws_api_gateway_integration_response" "integration_response" {
  rest_api_id = "${aws_api_gateway_rest_api.FileUploderAPI.id}"
  resource_id = "${aws_api_gateway_resource.upload_resource.id}"
  http_method = "${aws_api_gateway_method.upload_method.http_method}"

  status_code = "${aws_api_gateway_method_response.method_response_200.status_code}"

  response_templates = {
    "application/json" = "{\"message\": \"File uploaded to S3\"}"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'",
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,PUT'",
    "method.response.header.Content-Length" = "integration.response.header.Content-Length",
    "method.response.header.Content-Type" = "integration.response.header.Content-Type",
    "method.response.header.Timestamp" = "integration.response.header.Date"
  }
}

resource "aws_api_gateway_integration_response" "integration_response_400" {
  rest_api_id = "${aws_api_gateway_rest_api.FileUploderAPI.id}"
  resource_id = "${aws_api_gateway_resource.upload_resource.id}"
  http_method = "${aws_api_gateway_method.upload_method.http_method}"

  status_code = "${aws_api_gateway_method_response.method_response_400.status_code}"
  selection_pattern = "4\\d{2}"


}

resource "aws_api_gateway_integration_response" "integration_response_500" {
  rest_api_id = "${aws_api_gateway_rest_api.FileUploderAPI.id}"
  resource_id = "${aws_api_gateway_resource.upload_resource.id}"
  http_method = "${aws_api_gateway_method.upload_method.http_method}"

  status_code = "${aws_api_gateway_method_response.method_response_500.status_code}"
  selection_pattern = "5\\d{2}"

}

resource "aws_api_gateway_method_response" "method_response_200" {
  rest_api_id = aws_api_gateway_rest_api.FileUploderAPI.id
  resource_id = aws_api_gateway_resource.upload_resource.id
  http_method = aws_api_gateway_method.upload_method.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true,
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Content-Length" = true,
    "method.response.header.Content-Type" = true,
    "method.response.header.Timestamp" = true
  }

}

resource "aws_api_gateway_method_response" "method_response_400" {
  rest_api_id = aws_api_gateway_rest_api.FileUploderAPI.id
  resource_id = aws_api_gateway_resource.upload_resource.id
  http_method = aws_api_gateway_method.upload_method.http_method
  status_code = "400"

}

resource "aws_api_gateway_method_response" "method_response_500" {
  rest_api_id = aws_api_gateway_rest_api.FileUploderAPI.id
  resource_id = aws_api_gateway_resource.upload_resource.id
  http_method = aws_api_gateway_method.upload_method.http_method
  status_code = "500"

}

resource "aws_api_gateway_deployment" "uploader_deployment" {
  rest_api_id = aws_api_gateway_rest_api.FileUploderAPI.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.upload_resource.id,
      aws_api_gateway_method.upload_method.id,
      aws_api_gateway_integration.s3_integration.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.uploader_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.FileUploderAPI.id
  stage_name    = "prod"
}

# Enable Logging for the API Gateway
resource "aws_api_gateway_method_settings" "media_types" {
  rest_api_id = aws_api_gateway_rest_api.FileUploderAPI.id
  stage_name  = aws_api_gateway_stage.prod.stage_name
  method_path = "*/*"
  settings {
    logging_level      = "ERROR"
  }
}

# Creating S3 bucket and cloudFront Distribution for the web app - (front-end)

resource "aws_s3_bucket" "file_uploader_app_bucket" {
  bucket = var.webapp_bucket
  force_destroy = true

  tags = {
    Name = "File Uploader Service App Bucket"
  }
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
  comment             = "Some comment"
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