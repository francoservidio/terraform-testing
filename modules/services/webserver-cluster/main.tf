terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.64.2"
    }
  }
  backend "s3" {
    bucket = "terraformstatebucket-franco-123123498374"
    key = "stage/services/webserver-cluster/terraform.tfstate"
    region = "us-east-1"
    dynamodb_table = "terraform_state_locks"
    encrypt = true
  }
}
provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}
data "terraform_remote_state" "db" {
  backend = "s3"
  config {
    bucket = var.db_remote_state_bucket
    key = var.db_remote_state_key
    region = "us-east-1"
  }
}

locals {
  http_port = 80
  ssh_port = 22
  any_port = 0
  any_protocol = "-1"
  tcp_protocol = "tcp"
  all_ips = ["0.0.0.0/0"]
}
resource "aws_security_group" "instance" {
  name = "${var.cluster_name}-instance"
}
resource "aws_security_group_rule" "allow_http_inbound_intances" {
  type              = "Ingress"
  from_port         = local.http_port
  protocol          = local.http_port
  security_group_id = aws_security_group.instance.id
  to_port           = local.http_port
  cidr_blocks = local.all_ips

}
resource "aws_security_group_rule" "allow_any_outbound_instances" {
  type              = "Egress"
  from_port         = local.any_port
  protocol          = local.any_protocol
  security_group_id = aws_security_group.instance.id
  to_port           = local.any_port
  cidr_blocks = local.all_ips

}

resource "aws_security_group" "alb" {
  name = "${var.cluster_name}-alb"
}
resource "aws_security_group_rule" "allow_http_inbound" {
  type              = "ingress"
  from_port         = local.http_port
  protocol          = local.tcp_protocol
  security_group_id = aws_security_group.alb.id
  to_port           = local.http_port
  cidr_blocks = local.all_ips
}
resource "aws_security_group_rule" "allow_all_outbound" {
  type              = "egress"
  from_port         = local.any_port
  protocol          = local.any_protocol
  security_group_id = aws_security_group.alb.id
  to_port           = local.any_port
  cidr_blocks = local.all_ips

}


resource "aws_lb" "example" {
  name = "terraform-lb-example"
  load_balancer_type = "application"
  subnets = data.aws_subnet_ids.default.ids
  security_groups = [aws_security_group.alb.id]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example.arn
  port = local.http_port
  protocol = "HTTP"
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code = "404"
    }

  }
}

resource "aws_lb_target_group" "asg" {
  name = "terraform-target-asg-example"
  port = var.server_port
  protocol = "HTTP"
  vpc_id = data.aws_vpc.default.id

  health_check {
    path = "/"
    protocol = "HTTP"
    matcher = "200"
    interval = 15
    timeout = 3
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority = 100
  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
  condition {
    path_pattern {
      values = ["*"]
    }
  }
}

resource "aws_launch_configuration" "example" {
  image_id      = "ami-04ad2567c9e3d7893"
  instance_type = var.instance_type
  security_groups = [aws_security_group.instance.id]
  user_data = <<-EOF
              #!/bin/bash
              sudo yum install -y httpd
              sudo systemctl start httpd
              systemctl start httpd.service
              systemctl enable httpd.service
              echo “Hello World from $(hostname -f)” > /var/www/html/index.html
              EOF
  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_autoscaling_group" "example" {
  launch_configuration = aws_launch_configuration.example.name
  vpc_zone_identifier = data.aws_subnet_ids.default.ids
  target_group_arns = [aws_lb_target_group.asg.arn]
  health_check_type = "ELB"
  max_size = var.max_size
  min_size = var.min_size

  tag {
    key                 = "Name"
    propagate_at_launch = true
    value               = "${var.cluster_name}-asg"
  }
}







