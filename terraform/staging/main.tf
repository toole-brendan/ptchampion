terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "ptchampion-terraform-state"
    key            = "staging/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "ptchampion-terraform-locks"
  }

  required_version = ">= 1.0.0"
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = "staging"
      Project     = "PTChampion"
      ManagedBy   = "Terraform"
    }
  }
}

# Import modules
module "vpc" {
  source = "../modules/vpc"

  environment    = "staging"
  vpc_cidr_block = var.vpc_cidr_block
  azs            = var.availability_zones
}

module "rds" {
  source = "../modules/rds"

  environment      = "staging"
  vpc_id           = module.vpc.vpc_id
  subnet_ids       = module.vpc.private_subnet_ids
  db_instance_type = var.db_instance_type
  db_name          = var.db_name
  db_username      = var.db_username
  db_password      = var.db_password
}

module "redis" {
  source = "../modules/redis"

  environment         = "staging"
  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.vpc.private_subnet_ids
  redis_instance_type = var.redis_instance_type
}

module "ecr" {
  source = "../modules/ecr"

  repository_name = var.ecr_repository_name
}

module "ecs" {
  source = "../modules/ecs"

  environment         = "staging"
  vpc_id              = module.vpc.vpc_id
  public_subnet_ids   = module.vpc.public_subnet_ids
  private_subnet_ids  = module.vpc.private_subnet_ids
  ecr_repository_url  = module.ecr.repository_url
  api_image_tag       = var.api_image_tag
  container_cpu       = var.container_cpu
  container_memory    = var.container_memory
  db_host             = module.rds.db_host
  db_port             = module.rds.db_port
  db_name             = var.db_name
  db_username         = var.db_username
  db_password         = var.db_password
  redis_host          = module.redis.redis_host
  redis_port          = module.redis.redis_port
  domain_name         = "staging.ptchampion.com"
  certificate_arn     = var.certificate_arn
}

# Output variables useful for other scripts and resources
output "api_endpoint" {
  value = module.ecs.api_endpoint
  description = "The API Gateway endpoint URL"
}

output "rds_endpoint" {
  value = module.rds.db_host
  description = "The RDS endpoint"
  sensitive = true
}

output "redis_endpoint" {
  value = module.redis.redis_host
  description = "The ElastiCache Redis endpoint"
  sensitive = true
} 