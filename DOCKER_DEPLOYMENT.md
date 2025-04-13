# Docker Deployment Guide for PT Champion

This document provides step-by-step instructions for deploying the PT Champion application using Docker, both locally and on AWS EC2.

## Prerequisites

- Docker installed on your local machine
- AWS CLI installed and configured
- Access to AWS ECR (Elastic Container Registry)
- An EC2 instance running Amazon Linux
- SSH key pair for EC2 access

## Local Docker Setup

### 1. Start Docker

Ensure Docker Desktop is running on your local machine:

```bash
# Check Docker version
docker --version

# Check if Docker daemon is running
docker info

# If Docker isn't running, start Docker Desktop
open -a Docker  # On macOS
```

### 2. Build Multi-Architecture Docker Image

Since EC2 instances typically run on AMD64 architecture while your development machine might be ARM-based (Apple Silicon), you need to build a multi-architecture image:

```bash
# Create a buildx builder for multi-architecture support
docker buildx create --name multiarch --use

# Log in to AWS ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin [YOUR_ECR_REPOSITORY_URI]

# Build and push the multi-architecture image
docker buildx build --platform linux/amd64,linux/arm64 -t [YOUR_ECR_REPOSITORY_URI]:latest --push .
```

### 3. Run Docker Container Locally

```bash
# Run the container locally
docker run -d -p 8080:8080 \
  --name ptchampion \
  --restart unless-stopped \
  -e DATABASE_URL='[YOUR_DATABASE_CONNECTION_STRING]' \
  -e JWT_SECRET="[YOUR_JWT_SECRET]" \
  -e JWT_EXPIRES_IN="24h" \
  -e PORT="8080" \
  [YOUR_ECR_REPOSITORY_URI]:latest

# Verify the container is running
docker ps

# Test the API
curl http://localhost:8080/health
```

## Deploying to AWS EC2

### 1. SSH into EC2 Instance

```bash
ssh -i [YOUR_KEY_FILE].pem ec2-user@[YOUR_EC2_IP]
```

### 2. Install and Configure Docker on EC2

```bash
# Update packages
sudo yum update -y

# Install Docker
sudo yum install -y docker

# Start and enable Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Add ec2-user to docker group to run Docker without sudo
sudo usermod -a -G docker ec2-user

# Apply group changes
newgrp docker
```

### 3. Configure AWS Credentials on EC2

```bash
aws configure
```

Enter your AWS credentials when prompted:
- AWS Access Key ID: [YOUR_AWS_ACCESS_KEY_ID]
- AWS Secret Access Key: [YOUR_AWS_SECRET_ACCESS_KEY]
- Default region: us-east-1
- Default output format: json

### 4. Pull and Run the Docker Image on EC2

```bash
# Log in to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin [YOUR_ECR_REPOSITORY_URI]

# Pull the Docker image
docker pull [YOUR_ECR_REPOSITORY_URI]:latest

# Remove any existing container with the same name
docker rm -f ptchampion 2>/dev/null || true

# Run the Docker container
docker run -d -p 8080:8080 \
  --name ptchampion \
  --restart unless-stopped \
  -e DATABASE_URL='[YOUR_DATABASE_CONNECTION_STRING]' \
  -e JWT_SECRET="[YOUR_JWT_SECRET]" \
  -e JWT_EXPIRES_IN="24h" \
  -e PORT="8080" \
  [YOUR_ECR_REPOSITORY_URI]:latest

# Verify the container is running
docker ps

# Test the API
curl http://localhost:8080/health
```

### 5. Configure Security and Networking

Ensure your EC2 security group allows inbound traffic on port 8080, or configure Nginx as a reverse proxy to route traffic from port 80/443 to your container.

## Troubleshooting

### Docker Architecture Issues

If you see errors related to "exec format error," it means there's an architecture mismatch. For example, if you're building on ARM (Apple Silicon) but deploying to x86_64/AMD64:

1. Make sure to use buildx to create multi-architecture images
2. Use the `--platform` flag to specify both architectures

### Container Won't Start

If the container fails to start:

```bash
# Check container logs
docker logs ptchampion

# Check if the port is already in use
sudo netstat -tulpn | grep 8080
```

## Automatic Deployment Script

For automated deployments, consider creating a deployment script that:

1. Builds the Docker image
2. Pushes it to ECR
3. SSHs into the EC2 instance
4. Pulls the latest image
5. Stops the old container and starts a new one

## Accessing the Application

- Local: http://localhost:8080
- EC2: http://[YOUR_EC2_IP]:8080
- Domain (requires CloudFront configuration): https://[YOUR_DOMAIN] 