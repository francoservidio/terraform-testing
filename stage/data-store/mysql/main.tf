terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.64.2"
    }
  }
  backend "s3" {
    bucket = "terraformstatebucket-franco-123123498374"
    key = "stage/data-store/mysql/terraform.tfstate"
    region = "us-east-1"
    dynamodb_table = "terraform_state_locks"
    encrypt = true
  }
}
provider "aws" {
  region  = "us-east-1"
  profile = "default"

}
data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = "mysql-master-password-stage2"
}

resource "aws_db_instance" "example" {
  identifier_prefix   = "terraform-up-and-running"
  engine              = "mysql"
  allocated_storage   = 10
  instance_class      = "db.t2.micro"
  name                = "example_database"
  username            = "admin"
  skip_final_snapshot = true

  password = "password"
}