#define variables
locals {
  layer_zip_path    = "lambda_layer.zip"
  layer_name        = "lambda_requirements_layer"
  requirements_path = "${path.module}/../dependencies/requirements.txt"
  lambda_src_dir    = "${path.module}/../src/"
  lambda_function_zip_path = "${path.module}/lambda/lambda_function.zip"
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

# Create S3 policy for Lambda functiion role to get and put objects to S3 bucket
data "aws_iam_policy_document" "policy" {
  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket", "s3:GetObject", "s3:PutObject", "s3:CopyObject", "s3:HeadObject",
                    "logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents", "cloudwatch:PutMetricData"]
    resources = ["*"]
  }
}
resource "aws_iam_policy" "policy" {
  name        = "lambda-policy"
  policy      = data.aws_iam_policy_document.policy.json
}

# Attach the AWSLambdaBasicExecutionRole policy to the IAM role
resource "aws_iam_role_policy_attachment" "lambda_role_policy" {
  policy_arn = aws_iam_policy.policy.arn
  role       = aws_iam_role.lambda_role.name
}

# Create the Lambda function using data resource
data "archive_file" "lambda" {
  source_dir  = local.lambda_src_dir
  output_path = local.lambda_function_zip_path
  type        = "zip"
}
resource "aws_lambda_function" "image_processing_lambda" {
  filename      = local.lambda_function_zip_path 
  function_name = var.lambda_function_name
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = var.lambda_runtime
  timeout       = 10
  memory_size   = 128
  source_code_hash = data.archive_file.lambda.output_base64sha256
  # Use the Lambda Layer
  layers = ["arn:aws:lambda:us-east-1:770693421928:layer:Klayers-p38-Pillow:10"]

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

