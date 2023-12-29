output "blogs_posts_table" {
    value = aws_dynamodb_table.blog_posts.name
}

output "comments_table" {
    value = aws_dynamodb_table.comments.name
}
