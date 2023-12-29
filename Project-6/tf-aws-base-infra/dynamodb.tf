resource "aws_dynamodb_table" "blog_posts" {
  name           = var.blog_table
  billing_mode   = var.billing_mode
  read_capacity  = var.table_rcu
  write_capacity = var.table_wcu
  hash_key       = "post_id"
  range_key      = "author"

  attribute {
    name = "post_id"
    type = "S"
  }
  attribute {
    name = "title"
    type = "S"
  }
  attribute {
    name = "content"
    type = "S"
  }
  attribute {
    name = "author"
    type = "S"
  }
  attribute {
    name = "timestamp"
    type = "S"
  }

  local_secondary_index {
    name               = "TitleIndex"
    range_key          = "title"
    projection_type    = "KEYS_ONLY"
  }
  local_secondary_index {
    name               = "ContentIndex"
    range_key          = "content"
    projection_type    = "KEYS_ONLY"
  }
  local_secondary_index {
    name               = "TimestampIndex"
    range_key          = "timestamp"
    projection_type    = "KEYS_ONLY"
  }
}

resource "aws_dynamodb_table" "comments" {
  name           = var.comments_table
  billing_mode   = var.billing_mode
  read_capacity  = var.table_rcu
  write_capacity = var.table_wcu
  hash_key       = "comment_id"
  range_key      = "post_id"
  attribute {
    name = "comment_id"
    type = "S"
  }
  attribute {
    name = "post_id"
    type = "S"
  }
  attribute {
    name = "author"
    type = "S"
  }
  attribute {
    name = "content"
    type = "S"
  }
  attribute {
    name = "timestamp"
    type = "S"
  }
  local_secondary_index {
    name               = "AuthorIndex"
    range_key          = "author"
    projection_type    = "KEYS_ONLY"
  }
  local_secondary_index {
    name               = "ContentIndex"
    range_key          = "content"
    projection_type    = "KEYS_ONLY"
  }
  local_secondary_index {
    name               = "TimestampIndex"
    range_key          = "timestamp"
    projection_type    = "KEYS_ONLY"
  }
}