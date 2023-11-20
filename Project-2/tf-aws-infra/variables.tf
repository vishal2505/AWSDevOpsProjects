variable "aws_region" {
    description = "The region where the infrastructure should be deployed to"
    type = string
}

variable "aws_account_id" {
    description = "AWS Account ID"
    type = string
}

variable "src_s3_bucket" {
    description = "Source S3 bucket where files will be uploded"
    type = string
}

variable "tgt_s3_bucket" {
    description = "Target S3 bucket where processed files will be stored"
    type = string
}

variable "lambda_function_name" {
    description = "Lambda Function Name"
    type = string
}

variable "lambda_runtime" {
    description = "Lambda runtime"
    type = string
}

variable "sns_topic_name" {
    description = "SNS Topic Name"
    type = string
}

variable "alarm_receipient" {
    description = "Email Id for the Alarm receipient"
    type = string
}