terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.25.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}


# Create S3 buckets - src and tgt
resource "aws_s3_bucket" "image_bucket_src" {
  bucket = var.src_s3_bucket
  force_destroy = true
}

resource "aws_s3_bucket_ownership_controls" "image_bucket_src" {
  bucket = aws_s3_bucket.image_bucket_src.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "image_bucket_src" {
  depends_on = [aws_s3_bucket_ownership_controls.image_bucket_src]

  bucket = aws_s3_bucket.image_bucket_src.id
  acl    = "private"
}

resource "aws_s3_bucket" "image_bucket_tgt" {
  bucket = var.tgt_s3_bucket
  force_destroy = true
}

resource "aws_s3_bucket_ownership_controls" "image_bucket_tgt" {
  bucket = aws_s3_bucket.image_bucket_tgt.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "image_bucket_tgt" {
  depends_on = [aws_s3_bucket_ownership_controls.image_bucket_tgt]

  bucket = aws_s3_bucket.image_bucket_tgt.id
  acl    = "private"
}

# Create an IAM role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "LambdaRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# Attach the AWSLambdaBasicExecutionRole policy to the IAM role
resource "aws_iam_role_policy_attachment" "lambda_role_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_role.name
}

# Create the Lambda function
data "archive_file" "lambda" {
  source_dir  = "${path.module}/../src/"
  output_path = "${path.module}/lambda/lambda_function.zip"
  type        = "zip"
}

resource "aws_lambda_function" "image_processing_lambda" {
  filename      = "${path.module}/lambda/lambda_function.zip"  
  function_name = "ImageProcessingLambda"  # Replace with your desired function name
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.8"
  timeout       = 10
  memory_size   = 128
  source_code_hash = data.archive_file.lambda.output_base64sha256

  environment {
    variables = {
      SRC_BUCKET = var.src_s3_bucket,
      TGT_BUCKET = var.tgt_s3_bucket
    }
  }

}

#Grant the source S3 bucket the permission to trigger our Lambda function
resource "aws_lambda_permission" "allow_image_processing_bucket" {
   statement_id = "AllowExecutionFromS3Bucket"
   action = "lambda:InvokeFunction"
   function_name = "${aws_lambda_function.image_processing_lambda.arn}"
   principal = "s3.amazonaws.com"
   source_arn = "${aws_s3_bucket.image_bucket_src.arn}"
}

# We will use s3:ObjectCreated:* so we can get a notification when a file is added to our S3 bucket.
resource "aws_s3_bucket_notification" "bucket_image_processing_notification" {
   bucket = "${aws_s3_bucket.image_bucket_src.id}"
   lambda_function {
       lambda_function_arn = "${aws_lambda_function.image_processing_lambda.arn}"
       events = ["s3:ObjectCreated:*"]
   }
   depends_on = [ aws_lambda_permission.allow_image_processing_bucket ]
}

#SNS Topic
resource "aws_sns_topic" "app_notification" {
  name = var.sns_topic_name
}

#SNS Subscription
resource "aws_sns_topic_subscription" "app_notification_recipient" {
  topic_arn = aws_sns_topic.app_notification.arn
  protocol  = "email"
  endpoint  = var.alarm_receipient
}

