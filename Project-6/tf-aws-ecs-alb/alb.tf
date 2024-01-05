resource "aws_alb" "blog_app_lb" {
  name               = "blog-app-lb"
  load_balancer_type = "application"
  subnets = [
    aws_default_subnet.default_subnet_a.id,
    aws_default_subnet.default_subnet_b.id,
    aws_default_subnet.default_subnet_c.id
  ]
  # Referencing the security group
  security_groups = [aws_security_group.blog_app_lb_sg.id]
}

# Creating a security group for the load balancer:
resource "aws_security_group" "blog_app_lb_sg" {
  ingress {
    from_port   = 80 # Allowing traffic in from port 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allowing traffic in from all sources
  }

  egress {
    from_port   = 0 # Allowing any incoming port
    to_port     = 0 # Allowing any outgoing port
    protocol    = "-1" # Allowing any outgoing protocol 
    cidr_blocks = ["0.0.0.0/0"] # Allowing traffic out to all IP addresses
  }
}

resource "aws_lb_target_group" "blog_app_lb_tg" {
  name        = "blog-app-lb-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_default_vpc.default_vpc.id # Referencing the default VPC
  health_check {
    matcher = "200,301,302"
    path = "/"
  }
}

resource "aws_lb_target_group" "blog_app_lb_tg_green" {
  name        = "blog-app-lb-tg-green"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_default_vpc.default_vpc.id # Referencing the default VPC
  health_check {
    matcher = "200,301,302"
    path = "/"
  }
}

resource "aws_lb_listener" "blog_app_lb_listener" {
  load_balancer_arn = aws_alb.blog_app_lb.arn # Referencing our load balancer
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    #target_group_arn = aws_lb_target_group.blog_app_lb_tg.arn # Referencing our tagrte group
    forward {
      target_group {
        arn    = aws_lb_target_group.blog_app_lb_tg.arn
        weight = 50
      }

      target_group {
        arn    = aws_lb_target_group.blog_app_lb_tg_green.arn
        weight = 50
      }

      stickiness {
        enabled  = false
        duration = 600
      }
    }
  }
  
}