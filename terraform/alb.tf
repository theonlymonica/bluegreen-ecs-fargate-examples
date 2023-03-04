data "aws_elb_service_account" "main" {}

resource "aws_alb" "load_balancer" {
  name            = replace(local.name, "_", "-")
  internal        = false
  subnets         = module.vpc.public_subnets
  security_groups = [aws_security_group.sg.id]
  access_logs {
    bucket  = aws_s3_bucket.logs_bucket.bucket
    prefix  = "alb_access_logs"
    enabled = true
  }
  depends_on = [aws_s3_bucket_policy.logs_bucket_policy]
}

data "aws_lb_listener" "prod" {
  load_balancer_arn = aws_alb.load_balancer.arn
  port              = 80
}

data "aws_lb_listener" "test" {
  load_balancer_arn = aws_alb.load_balancer.arn
  port              = 8080
}

resource "aws_security_group" "sg" {
  name        = local.name
  description = local.name
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "8080"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name}_sg"
  }
}

resource "aws_alb_target_group" "tg_blue" {
  name        = join("-", [replace(local.name, "_", "-"), "blue"])
  port        = 80
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"

  health_check {
    interval            = "10"
    path                = "/index.html"
    timeout             = "3"
    healthy_threshold   = "2"
    unhealthy_threshold = "2"
  }
}

resource "aws_alb_target_group" "tg_green" {
  name        = join("-", [replace(local.name, "_", "-"), "green"])
  port        = 80
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"

  health_check {
    interval            = "10"
    path                = "/index.html"
    timeout             = "3"
    healthy_threshold   = "2"
    unhealthy_threshold = "2"
  }
}

resource "aws_alb_listener" "lb_listener_80" {
  load_balancer_arn = aws_alb.load_balancer.id
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.tg_blue.id
    type             = "forward"
  }

  lifecycle {
    ignore_changes = [default_action]
  }
}

resource "aws_alb_listener" "lb_listener_8080" {
  load_balancer_arn = aws_alb.load_balancer.id
  port              = "8080"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.tg_green.id
    type             = "forward"
  }

  lifecycle {
    ignore_changes = [default_action]
  }
}
