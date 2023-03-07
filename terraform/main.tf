terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
  profile = "aws-stage"
}

module "efs" {
  source = "./efs"
  subnet_id = "subnet-0921c918e129f4d9c"
  vpc_id = "vpc-03109186db6390738"
}

module "ecs" {
  source = "./ecs"
  efs_id = module.efs.efs_id
  app_name = var.app_name
  load_balancer_vpc_id = "vpc-03109186db6390738"
  load_balancer_prv_subnet_id = ["subnet-0dce73fe96aba9e76", "subnet-0036397839d5bb832"]
  subnet_id = ["subnet-0921c918e129f4d9c"]
  efs_access_point_id = module.efs.efs_access_point
}