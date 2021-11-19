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
  source = "github.com/francoservidio/alb-module-terraform//services/webserver-cluster?ref=V0.0.1"
  cluster_name = "stage-webservers"
  db_remote_state_bucket = "terraformstatebucket-franco-123123498374"
  db_remote_state_key = "stage/data-stores/mysql/terraform.tfstate"
  instance_type = "t2.micro"
  min_size = 1
  max_size = 1
}