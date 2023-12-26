variable "aws_region" {
    description = "The region where the infrastructure should be deployed to"
    type = string
}

variable "aws_account_id" {
    description = "AWS Account ID"
    type = string
}

variable "blog_table" {
    description = "DynamoDB Blog Posts Table Name"
    type = string
}

variable "comments_table" {
    description = "DynamoDB Comments Table Name"
    type = string
}

variable "billing_mode" {
    description = "DynamoDB Table Billing Mode"
    type = string
}

variable "table_rcu" {
    description = "DynamoDB Table Read Capacity Units"
    type = number
}

variable "table_wcu" {
    description = "DynamoDB Table Write Capacity Units"
    type = number
}