terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Production remote state storage with DynamoDB state locking
  # backend "s3" {
  #   bucket         = "devops-projectfirst-terraform-state"
  #   key            = "environments/dev/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "devops-terraform-locks"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source = "../../modules/vpc"

  project_name         = var.project_name
  environment          = "dev"
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs

  tags = {
    Environment = "dev"
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

module "eks" {
  source = "../../modules/eks"

  project_name       = var.project_name
  environment        = "dev"
  k8s_version        = var.k8s_version
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids
  instance_types     = ["t3.medium"]
  desired_nodes      = 2
  min_nodes          = 1
  max_nodes          = 3

  tags = {
    Environment = "dev"
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}
