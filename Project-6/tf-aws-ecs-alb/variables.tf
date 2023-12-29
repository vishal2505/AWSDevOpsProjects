variable "aws_region" {
    description = "The region where the infrastructure should be deployed to"
    type = string
}

variable "aws_account_id" {
    description = "AWS Account ID"
    type = string
}

variable "ecr_repo_name" {
    description = "ECR Repository name which will consist of docker images"
    type = string
}