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
  source = "../../../prod/services/webserver-cluster"
  cluster_name = "prod-webservers"
  db_remote_state_bucket = "terraformstatebucket-franco-123123498374"
  db_remote_state_key = "prod/data-stores/mysql/terraform.tfstate"
  m
}