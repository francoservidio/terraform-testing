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
  source = "../../../../modules/services/webserver-cluster"
  cluster_name = "prod-webservers"
  db_remote_state_bucket = "terraformstatebucket-franco-123123498374"
  db_remote_state_key = "prod/data-stores/mysql/terraform.tfstate"
  min_size = 2
  max_size = 2
  instance_type = "t2.micro"
  custom_tags = {
    Owner = "team-foo"
    DeployedBy = "terraform"
  }
  enable_autoscaling = true
}