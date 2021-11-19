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

module "webserver_cluster" {
  source = "../../../modules/services/webserver-cluster"
  cluster_name = "prod-webservers"
  db_remote_state_bucket = "terraformstatebucket-franco-123123498374"
  db_remote_state_key = "prod/data-stores/mysql/terraform.tfstate"
  min_size = 2
  max_size = 2
  instance_type = "t2.micro"
}

resource "aws_autoscaling_schedule" "scale_out_during_business_hours" {
  autoscaling_group_name = module.webserver_cluster.asg_name
  scheduled_action_name  = "scale-out-during-business-hours"
  min_size = 2
  max_size = 3
  desired_capacity = 3
  recurrence = "0 9 * * *"
}
resource "aws_autoscaling_schedule" "scale_in_at_night" {
  autoscaling_group_name = module.webserver_cluster.asg_name
  scheduled_action_name  = "scale-in-at-night"
  min_size = 1
  max_size = 1
  desired_capacity = 1
  recurrence = "0 17 * * *"
}