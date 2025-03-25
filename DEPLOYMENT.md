# PT Champion AWS Deployment Guide

This guide provides instructions on how to deploy the PT Champion application to AWS.

## Architecture Overview

The PT Champion deployment architecture consists of:

1. **Frontend**: React application deployed to S3 and served via CloudFront CDN
2. **Backend**: Node.js/Express API deployed on EC2
3. **Database**: PostgreSQL on AWS RDS
4. **Caching**: Redis (optional, for improved performance)

## Prerequisites

1. An AWS account with appropriate permissions
2. AWS CLI installed and configured on your local machine
3. Node.js and npm installed
4. Git for version control

## Initial AWS Setup

### 1. Configure AWS CLI

```bash
# Install AWS CLI if not already installed
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Configure with your credentials
aws configure
```

Provide the following when prompted:
- AWS Access Key ID
- AWS Secret Access Key
- Default region (e.g., us-east-1)
- Default output format (json is recommended)

### 2. Set Environment Variables

Create a `.env.production` file with your production settings:

```
NODE_ENV=production
NODE_TLS_REJECT_UNAUTHORIZED=0

# AWS RDS PostgreSQL Connection
DATABASE_URL=postgres://[username]:[password]@[rds-endpoint]:5432/[database]

# JWT configuration
# Use a strong, randomly generated secret
JWT_SECRET=[generate-a-secure-random-string]
JWT_EXPIRES_IN=24h

# Redis configuration for caching (if using ElastiCache)
REDIS_URL=redis://[redis-endpoint]:6379
CACHE_TTL=300 # 5 minutes in seconds
DISABLE_CACHE=false

# Server port configuration
PORT=3000
```

## Detailed Deployment Process

### 1. Database Setup (RDS)

```bash
# Create a PostgreSQL database instance
aws rds create-db-instance \
    --db-instance-identifier ptchampion-1-instance-1 \
    --db-instance-class db.t3.micro \
    --engine postgres \
    --allocated-storage 20 \
    --master-username postgres \
    --master-user-password [your-secure-password] \
    --vpc-security-group-ids [security-group-id] \
    --publicly-accessible \
    --port 5432
```

Create a security group that allows inbound connections on port 5432 from your EC2 instances.

### 2. Create EC2 Security Group

```bash
# Create security group
aws ec2 create-security-group \
    --group-name ptchampion-sg \
    --description "Security group for PT Champion application"

# Allow SSH (port 22), HTTP (port 80), HTTPS (port 443), and API (port 3000)
aws ec2 authorize-security-group-ingress \
    --group-name ptchampion-sg \
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0

aws ec2 authorize-security-group-ingress \
    --group-name ptchampion-sg \
    --protocol tcp \
    --port 80 \
    --cidr 0.0.0.0/0

aws ec2 authorize-security-group-ingress \
    --group-name ptchampion-sg \
    --protocol tcp \
    --port 443 \
    --cidr 0.0.0.0/0

aws ec2 authorize-security-group-ingress \
    --group-name ptchampion-sg \
    --protocol tcp \
    --port 3000 \
    --cidr 0.0.0.0/0
```

### 3. Launch EC2 Instance for Backend

```bash
# Create a key pair for SSH access
aws ec2 create-key-pair \
    --key-name ptchampion-key \
    --query "KeyMaterial" \
    --output text > ptchampion-key.pem

# Set proper permissions
chmod 400 ptchampion-key.pem

# Launch EC2 instance
aws ec2 run-instances \
    --image-id ami-0e731c8a588258d0d \
    --instance-type t2.micro \
    --key-name ptchampion-key \
    --security-group-ids [security-group-id] \
    --user-data file://ec2-user-data.sh \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=ptchampion-server}]"
```

### 4. Create S3 Bucket for Frontend

```bash
# Create S3 bucket
aws s3api create-bucket \
    --bucket ptchampion.ai \
    --region us-east-1

# Configure bucket for website hosting
aws s3 website s3://ptchampion.ai/ \
    --index-document index.html \
    --error-document index.html

# Set bucket policy for public access
aws s3api put-bucket-policy \
    --bucket ptchampion.ai \
    --policy file://bucket-policy.json
```

### 5. Build and Deploy Frontend

```bash
# Build frontend
npm install
npm run build

# Deploy to S3
aws s3 sync dist/public/ s3://ptchampion.ai/ --delete
```

### 6. Set Up CloudFront Distribution

Create a CloudFront distribution with two origins:
1. S3 bucket for static assets
2. EC2 instance for API endpoints

```bash
# Create CloudFront distribution
aws cloudfront create-distribution \
    --distribution-config file://cloudfront-config.json
```

### 7. EC2 Configuration Script

Example `ec2-user-data.sh` script:

```bash
#!/bin/bash
yum update -y
yum install -y git
curl -sL https://rpm.nodesource.com/setup_18.x | bash -
yum install -y nodejs
npm install -g pm2

# Install nginx for reverse proxy
amazon-linux-extras install -y nginx1 || dnf install -y nginx

# Clone repository
cd /home/ec2-user
git clone https://github.com/yourusername/ptchampion.git
cd ptchampion

# Install dependencies and build
npm install
npm run build

# Create .env.production file with your configuration
# Start the server with PM2
NODE_ENV=production pm2 start dist/index.js --name ptchampion-api
pm2 startup
pm2 save

# Configure Nginx as a reverse proxy
# Enable and start Nginx
systemctl enable nginx
systemctl start nginx
```

## Database Security Configuration

Configure the RDS Security Group to allow EC2 access:

```bash
# Get EC2 instance security group ID
EC2_SG_ID=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=ptchampion-server" \
    --query "Reservations[0].Instances[0].SecurityGroups[0].GroupId" \
    --output text)

# Get RDS security group ID
RDS_SG_ID=$(aws rds describe-db-instances \
    --db-instance-identifier ptchampion-1-instance-1 \
    --query "DBInstances[0].VpcSecurityGroups[0].VpcSecurityGroupId" \
    --output text)

# Allow EC2 security group to access RDS on port 5432
aws ec2 authorize-security-group-ingress \
    --group-id $RDS_SG_ID \
    --protocol tcp \
    --port 5432 \
    --source-group $EC2_SG_ID
```

## CloudFront Configuration for API Routing

### Critical Configuration Points

1. **Ensure the correct EC2 domain:** Always use the current EC2 public DNS or IP
2. **Configure proper cache behaviors:**
   - Use `CachePolicyId: "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"` (CachingDisabled policy)
   - Use `OriginRequestPolicyId: "216adef6-5c7f-47e4-b989-5492eafa07d3"` (AllViewer policy)
3. **Include all HTTP methods for API routes**
4. **Create invalidations after updates**

## Security Best Practices

1. Always use a strong random JWT secret in production
2. Regularly update your EC2 instance with security patches
3. Use HTTPS everywhere (including for API requests)
4. Apply the principle of least privilege for IAM roles and security groups
5. Regularly back up your RDS database

## Monitoring and Maintenance

1. Set up CloudWatch Alarms for monitoring EC2 and RDS instances
2. Configure S3 logging for frontend access analysis
3. Implement CloudTrail for AWS API activity monitoring
4. Create a regular backup strategy for your database