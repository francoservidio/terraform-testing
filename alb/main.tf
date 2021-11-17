terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.64.2"
    }
  }
}
provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

variable "server_port" {
  description = "The port the server will use for http requests"
  type = number
  default = 80
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}

/*
resource "aws_instance" "example" {
  ami           = "ami-04ad2567c9e3d7893"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.instance.id]

  user_data = <<-EOF
              #!/bin/bash
              sudo yum install -y httpd
              sudo systemctl start httpd
              systemctl start httpd.service
              systemctl enable httpd.service
              echo “Hello World from $(hostname -f)” > /var/www/html/index.html
              EOF
  tags = {
    Name = "terraform example"
  }
}
*/
resource "aws_security_group" "instance" {
  name = "terraform example-instance"

  ingress {
    from_port = var.server_port
    protocol  = "tcp"
    to_port   = var.server_port
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 22
    protocol  = "tcp"
    to_port   = 22
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    protocol  = "-1"
    to_port   = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "alb" {
  name = "terraform-example-alb"

  ingress {
    from_port = 80
    protocol  = "TCP"
    to_port   = 80
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    protocol  = "-1"
    to_port   = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

}


resource "aws_lb" "example" {
  name = "terraform-lb-example"
  load_balancer_type = "application"
  subnets = data.aws_subnet_ids.default.ids
  security_groups = [aws_security_group.alb.id]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example.arn
  port = 80
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
  instance_type = "t2.micro"
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
  max_size = 3
  min_size = 2

  tag {
    key                 = "Name"
    propagate_at_launch = true
    value               = "terraform-asg-example"
  }
}
output "alb_dns_name" {
  value = aws_lb.example.dns_name
  description = "The domain name of the load balancer"
}






