resource "aws_lb" "load_balancer" {
  name               = "server-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.sg]
  subnets = var.subnets
  enable_deletion_protection = false

  tags = {
    Name = "lb"
  }
}

resource "aws_lb_listener" "jenkins_listener" {
  load_balancer_arn = aws_lb.load_balancer.arn
  port              = 8080
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.jenkins_target_group.arn
  }
}

resource "aws_lb_listener" "sonarqube_listener" {
  load_balancer_arn = aws_lb.load_balancer.arn
  port              = 9000
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sonarqube_target_group.arn
  }
}


resource "aws_lb_target_group" "jenkins_target_group" {
  name     = "jenkins-target-group"
  port     = 8080
  protocol = "HTTP"
  health_check {
    path                = "/"
    port                = 8000
    protocol            = "HTTP"
    interval            = 30
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  vpc_id   = var.vpc_id
  tags = {
    Name = "jenkins-target-group"
  }
}

resource "aws_lb_target_group" "sonarqube_target_group" {
  name     = "sonarqube-target-group"
  port     = 9000
  protocol = "HTTP"
  health_check {
    path                = "/"
    port                = 9000
    protocol            = "HTTP"
    interval            = 30
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  vpc_id   = var.vpc_id
  tags = {
    Name = "sonarqube-target-group"
  }
}

resource "aws_lb_target_group_attachment" "attach_instance" {
  target_group_arn = aws_lb_target_group.jenkins_target_group.arn
  target_id        = var.instance_id
  port             = 8080
}
resource "aws_lb_target_group_attachment" "attach_instance2" {
  target_group_arn = aws_lb_target_group.sonarqube_target_group.arn
  target_id        = var.instance_id
  port             = 9000
}