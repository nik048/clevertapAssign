data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_ecs_cluster" "aws-ecs-cluster" {
  name = "${var.app_name}-cluster"
  tags = {
    Name = "${var.app_name}-ecs"
  }
}

resource "aws_ecs_task_definition" "ecs-task-definition" {
  family = "${var.app_name}-ecs-task-definition"
  container_definitions =  file("${path.module}/task-definition/task.json")
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  memory                   = "512"
  cpu                      = "256"
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
  task_role_arn            = aws_iam_role.ecsTaskExecutionRole.arn
  volume {
    name      = "wp-upload"
    #host_path = "/var/www/html/wp-content"
    efs_volume_configuration {
      file_system_id          = var.efs_id
      root_directory          = "/wp-uploads"
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = var.efs_access_point_id
        iam             = "ENABLED"
      }
    }
  }
  
  # placement_constraints {
  #   type       = "memberOf"
  #   expression = "attribute:ecs.availability-zone in [us-west-2a, us-west-2b]"
  # }
}

resource "aws_ecs_service" "aws-ecs-service" {
  name                 = "${var.app_name}-ecs-service"
  cluster              = aws_ecs_cluster.aws-ecs-cluster.id
  task_definition      = aws_ecs_task_definition.ecs-task-definition.family
  launch_type          = "FARGATE"
  scheduling_strategy  = "REPLICA"
  desired_count        = 1
  force_new_deployment = true

  network_configuration {
    subnets          = var.subnet_id
    assign_public_ip = false
    security_groups = [
      aws_security_group.service_security_group.id,
      aws_security_group.load_balancer_security_group.id
    ]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.target_group.arn
    container_name   = "${var.app_name}-container"
    container_port   = 80
  }

  depends_on = [aws_lb_listener.listener]
}

resource "aws_security_group" "service_security_group" {
  vpc_id = var.load_balancer_vpc_id

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.load_balancer_security_group.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name        = "${var.app_name}-service-sg"
  }
}

resource "aws_cloudwatch_log_group" "log-group" {
  name = "${var.app_name}-logs"

  tags = {
    Application = var.app_name
  }
}

resource "aws_iam_role" "ecsTaskExecutionRole" {
  name               = "${var.app_name}-execution-task-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
  
  inline_policy {
    name = "secret_manager_secret_access"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect =  "Allow"
          Action = [
            #"ssm:GetParameters",
            "secretsmanager:GetSecretValue"
          ],
          Resource = [
            #"arn:aws:ssm:region:aws_account_id:parameter/parameter_name",
            "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:WP_USER_PASS-Thp7zH",
            #"arn:aws:kms:region:aws_account_id:key/key_id"
          ],
        }
      ]
    })
  }

  tags = {
    Name = "${var.app_name}-iam-role"
  }
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy" {
  role       = aws_iam_role.ecsTaskExecutionRole.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_alb" "application_load_balancer" {
  name               = "${var.app_name}-alb"
  internal           = true
  load_balancer_type = "application"
  subnets            = var.load_balancer_prv_subnet_id
  security_groups    = [aws_security_group.load_balancer_security_group.id]

  tags = {
    Name  = "${var.app_name}-alb"
  }
}

resource "aws_security_group" "load_balancer_security_group" {
  vpc_id = var.load_balancer_vpc_id

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    Name        = "${var.app_name}-sg"
  }
}

resource "aws_lb_target_group" "target_group" {
  name        = "${var.app_name}-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.load_balancer_vpc_id

  health_check {
    healthy_threshold   = "3"
    interval            = "300"
    protocol            = "HTTP"
    matcher             = "200-399"
    timeout             = "3"
    path                = "/"
    unhealthy_threshold = "3"
  }

  tags = {
    Name = "${var.app_name}-lb-tg"
  }
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_alb.application_load_balancer.id
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.id
  }
}