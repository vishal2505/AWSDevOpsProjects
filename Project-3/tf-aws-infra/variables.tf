variable "aws_region" {
    description = "The region where the infrastructure should be deployed to"
    type = string
}

variable "aws_account_id" {
    description = "AWS Account ID"
    type = string
}

variable "user_bucket" {
    description = " S3 bucket where files will be uploded"
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

variable "webapp_bucket" {
    description = "Bucket for hosting html, css and js for the app"
    type = string
}