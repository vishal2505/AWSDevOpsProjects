data "aws_ecr_repository" "blog_app_ecr_repo" {
  name = var.ecr_repo_name
}

resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name = "/ecs/blog-app-task"
  retention_in_days = 3
}

# Providing a reference to our default VPC
resource "aws_default_vpc" "default_vpc" {
}

# Providing a reference to our default subnets
resource "aws_default_subnet" "default_subnet_a" {
  availability_zone = "us-east-1a"
}

resource "aws_default_subnet" "default_subnet_b" {
  availability_zone = "us-east-1b"
}

resource "aws_default_subnet" "default_subnet_c" {
  availability_zone = "us-east-1c"
}

# ECS task Execution Role
resource "aws_iam_role" "ecsTaskExecutionRole" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# Policies for ECS Task Execution Role
resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy_1" {
  role       = aws_iam_role.ecsTaskExecutionRole.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy_2" {
  role       = aws_iam_role.ecsTaskExecutionRole.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

resource "aws_kms_key" "ecs_cluster_key" {
  description             = "ECS CLuster KMS Key"
  deletion_window_in_days = 7
}

resource "aws_cloudwatch_log_group" "ecs_cluster_group" {
  name = "blog_ecs_log_group"
}

resource "aws_ecs_cluster" "blog_ecs_cluster" {
  name = "blog_app_ecs_cluster"

  configuration {
    execute_command_configuration {
      kms_key_id = aws_kms_key.ecs_cluster_key.arn
      logging    = "OVERRIDE"

      log_configuration {
        cloud_watch_encryption_enabled = true
        cloud_watch_log_group_name     = aws_cloudwatch_log_group.ecs_cluster_group.name
      }
    }
  }
}

resource "aws_ecs_task_definition" "blog_task_def_blue" {
  family                   = "blog-app-blue"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
  task_role_arn            = aws_iam_role.ecsTaskExecutionRole.arn
  memory                   = 512
  cpu                      = 256
  container_definitions    = <<EOF
[
  {
    "name": "blog-app-blue",
    "image": "${data.aws_ecr_repository.blog_app_ecr_repo.repository_url}:blue",
    "memory": 512,
    "cpu": 256,
    "essential": true,
    "portMappings": [
      {
        "containerPort": 5000,
        "hostPort": 5000
      }
    ],
    "logConfiguration": {
                "logDriver": "awslogs",
                "options": {
                    "awslogs-create-group": "true",
                    "awslogs-group": "${aws_cloudwatch_log_group.ecs_log_group.name}",
                    "awslogs-region": "us-east-1",
                    "awslogs-stream-prefix": "awslogs-blogapp"
                }
            }
  }
]
EOF
}

resource "aws_ecs_service" "blog_service_blue" {
  name            = "blog-app-blue"
  cluster         = aws_ecs_cluster.blog_ecs_cluster.id
  task_definition = aws_ecs_task_definition.blog_task_def_blue.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_default_subnet.default_subnet_a.id, aws_default_subnet.default_subnet_b.id, aws_default_subnet.default_subnet_c.id]
    assign_public_ip = true                                               # Providing our containers with public IPs
    security_groups  = [aws_security_group.ecs_service_sg.id]             # Setting the security group
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.blog_app_lb_tg.arn             # Referencing our target group
    container_name   = aws_ecs_task_definition.blog_task_def_blue.family
    container_port   = 5000                                               # Specifying the container port
  }

}

resource "aws_security_group" "ecs_service_sg" {
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    # Only allowing traffic in from the load balancer security group
    security_groups = [aws_security_group.blog_app_lb_sg.id]
  }

  egress {
    from_port   = 0 # Allowing any incoming port
    to_port     = 0 # Allowing any outgoing port
    protocol    = "-1" # Allowing any outgoing protocol 
    cidr_blocks = ["0.0.0.0/0"] # Allowing traffic out to all IP addresses
  }
}

# Adding configurations for the Green Service -

resource "aws_ecs_task_definition" "blog_task_def_green" {
  family                   = "blog-app-green"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
  task_role_arn            = aws_iam_role.ecsTaskExecutionRole.arn
  memory                   = 512
  cpu                      = 256
  container_definitions    = <<EOF
[
  {
    "name": "blog-app-green",
    "image": "${data.aws_ecr_repository.blog_app_ecr_repo.repository_url}:green",
    "memory": 512,
    "cpu": 256,
    "essential": true,
    "portMappings": [
      {
        "containerPort": 5000,
        "hostPort": 5000
      }
    ],
    "logConfiguration": {
                "logDriver": "awslogs",
                "options": {
                    "awslogs-create-group": "true",
                    "awslogs-group": "${aws_cloudwatch_log_group.ecs_log_group.name}",
                    "awslogs-region": "us-east-1",
                    "awslogs-stream-prefix": "awslogs-blogapp"
                }
            }
  }
]
EOF
}

resource "aws_ecs_service" "blog_service_green" {
  name            = "blog-app-green"
  cluster         = aws_ecs_cluster.blog_ecs_cluster.id
  task_definition = aws_ecs_task_definition.blog_task_def_green.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_default_subnet.default_subnet_a.id, aws_default_subnet.default_subnet_b.id, aws_default_subnet.default_subnet_c.id]
    assign_public_ip = true                                               # Providing our containers with public IPs
    security_groups  = [aws_security_group.ecs_service_sg.id]             # Setting the security group
  }


   load_balancer {
    target_group_arn = aws_lb_target_group.blog_app_lb_tg_green.arn             # Referencing our target group
    container_name   = aws_ecs_task_definition.blog_task_def_green.family
    container_port   = 5000                                               # Specifying the container port
  }
}