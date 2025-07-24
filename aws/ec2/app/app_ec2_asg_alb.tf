# CIS Amazon Linux AMI
data "aws_ami" "cis_amazon_linux" {
  most_recent = true
  owners      = ["679593333241"]

  filter {
    name   = "name"
    values = ["CIS Amazon Linux 2023 Benchmark - Level 1 *"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# Security Group for ALB
resource "aws_security_group" "alb_sg" {
  name        = "alb-app-sg"
  description = "Allow HTTPS inbound traffic to ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.12.0/24","10.0.11.0/24"]
    description = "Allow HTTPS from web tier"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "alb-app-sg"
  }
}

# Security Group for EC2 instances
resource "aws_security_group" "ec2_sg" {
  name        = "ec2-app-sg"
  description = "Allow HTTPS from ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
    description     = "Allow HTTPS from ALB"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ec2-app-sg"
  }
}

# Application Load Balancer
resource "aws_lb" "cis_alb" {
  name               = "app-alb"
  internal           = true
  load_balancer_type = "application"
  subnets            = var.subnet_ids
  security_groups    = [aws_security_group.alb_sg.id]
  
}

# Launch Template using CIS AMI
resource "aws_launch_template" "cis_lt" {
  name_prefix   = "cis-lt-app"
  image_id      = data.aws_ami.cis_amazon_linux.id
  instance_type = "t3.micro"
  key_name      = var.key_name

  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  monitoring {
    enabled = true
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = 50
      volume_type           = "gp3"
      delete_on_termination = true
      encrypted             = true
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "cis-app-asg-instance"
    }
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "cis_asg" {
  name                      = "cis-app-asg"
  desired_capacity          = 2
  max_size                  = 3
  min_size                  = 1
  vpc_zone_identifier       = var.subnet_ids
  health_check_type         = "EC2"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.cis_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "cis-app-asg-instance"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Target Group for ALB
resource "aws_lb_target_group" "cis_tg" {
  name     = "cis-app-tg"
  port     = 443
  protocol = "HTTPS"
  vpc_id   = var.vpc_id

  health_check {
    protocol            = "HTTPS"
    port                = "443"
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-399"
  }

  target_type = "instance"
}



# HTTPS Listener for ALB
# this should be https but need valid acm cert first
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.cis_alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.acm_certificate_arn  # Must be passed as a variable

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.cis_tg.arn
  }
}

# Attach ASG to target group
resource "aws_autoscaling_attachment" "asg_to_tg" {
  autoscaling_group_name = aws_autoscaling_group.cis_asg.name
  lb_target_group_arn   = aws_lb_target_group.cis_tg.arn
}

# Associate WAF with ALB
#resource "aws_wafv2_web_acl_association" "cis_alb_waf_assoc" {
#  resource_arn = aws_lb.cis_alb.arn
#  web_acl_arn  = var.waf_web_acl_arn  # Must be passed as a variable
#}


resource "aws_wafv2_web_acl_association" "alb_waf_attachment" {
  resource_arn = aws_lb.cis_alb.arn
  web_acl_arn  = "arn:aws:wafv2:us-east-2:717279727434:regional/webacl/app-waf-acl/2ed14a59-7350-4018-a09f-ae2cf92aa755"
}
