# PT Champion Infrastructure as Code

This directory contains the Terraform configuration for deploying PT Champion to AWS infrastructure.

## Directory Structure

```
terraform/
├── modules/               # Shared infrastructure modules 
│   ├── vpc/               # Network infrastructure (VPC, subnets, etc.)
│   ├── rds/               # PostgreSQL database setup
│   ├── redis/             # ElastiCache Redis setup
│   ├── ecr/               # Container registry for Docker images  
│   ├── ecs/               # ECS Fargate for running containers
│   └── monitoring/        # Observability (CloudWatch, alarms, etc.)
├── staging/               # Staging environment configuration
│   ├── main.tf            # Main configuration that uses modules
│   ├── variables.tf       # Input variables for the staging environment
│   └── outputs.tf         # Output values for the staging environment
└── production/            # Production environment configuration
    ├── main.tf            # Main configuration that uses modules
    ├── variables.tf       # Input variables for the production environment
    └── outputs.tf         # Output values for the production environment
```

## Usage

### Prerequisites

1. Install Terraform CLI (version 1.0.0 or higher)
2. Configure AWS credentials
3. Set up an S3 bucket for Terraform state
4. Set up a DynamoDB table for state locking

### Deploying to Staging

```bash
cd terraform/staging
terraform init
terraform plan -var-file=staging.tfvars
terraform apply -var-file=staging.tfvars
```

### Deploying to Production

```bash
cd terraform/production
terraform init
terraform plan -var-file=production.tfvars
terraform apply -var-file=production.tfvars
```

## Security Considerations

- Sensitive variables (passwords, secrets) should be stored in AWS Secrets Manager and referenced in Terraform
- Never commit `.tfvars` files with sensitive values to source control
- Use AWS IAM roles with least privilege

## Modules

### VPC Module

Creates a VPC with public and private subnets across multiple availability zones, along with internet and NAT gateways for secure network topology.

### RDS Module

Sets up a PostgreSQL database with proper security groups, automated backups, and performance insights.

### Redis Module

Configures ElastiCache Redis for caching with encryption at rest and in transit.

### ECR Module

Creates a Docker container registry with vulnerability scanning and lifecycle policies.

### ECS Module

Deploys the application using Fargate with auto-scaling, load balancing, and secure secret management.

### Monitoring Module

Sets up CloudWatch alarms, dashboards, and log groups for comprehensive system monitoring.

## Best Practices

1. Always run `terraform plan` before applying changes
2. Use workspaces to separate environments
3. Keep modules generic and reusable
4. Use variables to customize module behavior
5. Document module inputs and outputs
6. Use consistent naming conventions

## Troubleshooting

If you encounter issues:

1. Verify AWS credentials are correct and have necessary permissions
2. Check the Terraform state in S3
3. Review CloudWatch Logs for application issues
4. Ensure security groups allow required traffic 