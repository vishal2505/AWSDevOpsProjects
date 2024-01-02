resource "aws_iam_role" "codebuild_role" {
  name = "codebuild-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# Policies for ECR full access
resource "aws_iam_role_policy_attachment" "codebuild_ecr_policy" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}

# Additional policies for CloudWatch Logs, etc.
resource "aws_iam_role_policy_attachment" "codebuild_logs_policy" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}


resource "aws_codebuild_project" "codebuild_project" {
  name          = var.codebuild_project_name
  description   = "Builds Blog Flask application Docker image"
  service_role  = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  cache {
    type     = "LOCAL"
    modes    = ["LOCAL_DOCKER_LAYER_CACHE"]
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:5.0"  # Choose a suitable image
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"  # Use CodeBuild's credentials for pulling images

    # Environment variables (replace with your values)
    environment_variable {
      name  = "ECR_REPOSITORY"
      value = aws_ecr_repository.blog_app_ecr_repo.repository_url
    }
    environment_variable {
      name  = "AWS_REGION"
      value = var.aws_region
    }
  }

  source {
    type            = "GITHUB"  
    location        = var.github_repo
    git_clone_depth = 1
  }

  lifecycle {
    ignore_changes = [
      source_version,
    ]
  }  
}

resource "aws_codebuild_source_credential" "github_credentials" {
  auth_type   = "PERSONAL_ACCESS_TOKEN"
  server_type = "GITHUB"
  token       = var.github_oauth_token
}

resource "aws_codebuild_webhook" "github_webhook" {
  project_name = aws_codebuild_project.codebuild_project.name

  filter_group {
    filter {
      type = "EVENT"
      pattern = "PULL_REQUEST_MERGED"
    }
  }
}
