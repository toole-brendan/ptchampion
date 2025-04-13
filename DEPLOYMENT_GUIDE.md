# PT Champion Deployment Guide

This guide provides step-by-step instructions for deploying the PT Champion application, including common pitfalls and troubleshooting tips.

## Architecture Overview

PT Champion uses a distributed architecture with several components:

- **Frontend**: React TypeScript application deployed to AWS S3
- **Backend**: Go server running in Docker on EC2
- **Database**: PostgreSQL on Amazon RDS Aurora
- **CDN**: CloudFront distribution for performance and HTTPS

```
                 ┌─────────────┐
                 │  CloudFront │
                 └──────┬──────┘
                        │
              ┌─────────┴─────────┐
              │                   │
     ┌────────▼───────┐    ┌──────▼──────┐
     │ S3 (Frontend)  │    │ API Routes  │
     └────────────────┘    └──────┬──────┘
                                  │
                           ┌──────▼──────┐
                           │ EC2 (Go API)│
                           └──────┬──────┘
                                  │
                           ┌──────▼──────┐
                           │ RDS Aurora  │
                           └─────────────┘
```

## Deployment Process

### 1. Environment Setup

1. Create a `.env.production` file with all required variables:

```
NODE_ENV=production
NODE_TLS_REJECT_UNAUTHORIZED=0

# AWS RDS PostgreSQL Connection
DATABASE_URL=[Your RDS connection string]

# JWT configuration
JWT_SECRET=[Your JWT secret]
JWT_EXPIRES_IN=24h

# Server port configuration
PORT=8080

# Deployment configuration
EC2_IP=[Your EC2 instance IP]
EC2_HOSTNAME=[Your EC2 hostname]

# New deployment variables for Go/Docker
AWS_REGION=us-east-1
S3_BUCKET=[Your S3 bucket name]
CLOUDFRONT_DISTRIBUTION_ID=[Your CloudFront ID]
CLIENT_ORIGIN=[Your frontend domain]
ECR_REPOSITORY_URI=[Your ECR repository URI]
```

### 2. Build and Deploy

The application can be deployed using the provided `deploy-go.sh` script:

```bash
./deploy-go.sh --full
```

This script will:
1. Build a multi-architecture Docker image (for both ARM64 and AMD64)
2. Push the image to ECR
3. Deploy the Go backend to EC2
4. Configure Nginx on the EC2 instance
5. Deploy the frontend to S3
6. Update CloudFront settings
7. Test the API connection

### 3. Manual Steps if Needed

If you need to update specific components:

- **Backend only**: `./deploy-go.sh --backend`
- **Frontend only**: `./deploy-go.sh --frontend`
- **CloudFront only**: `./deploy-go.sh --configure-cf`
- **Just invalidate cache**: `./deploy-go.sh --invalidate`
- **Test API**: `./deploy-go.sh --test-api`

## Common Pitfalls and Solutions

### 1. Docker Architecture Mismatch

**Problem**: Container fails to start on EC2 with "no matching manifest for linux/amd64" error.

**Solution**: Build multi-architecture Docker images using buildx:

```bash
# Create a buildx builder for multi-architecture support
docker buildx create --name multiarch --use

# Build and push the multi-architecture image
docker buildx build --platform linux/amd64,linux/arm64 -t [YOUR_ECR_REPOSITORY_URI]:latest --push .
```

### 2. CloudFront Redirect Loops

**Problem**: Browser shows "ERR_TOO_MANY_REDIRECTS" when accessing the website.

**Solution**: Ensure CloudFront's default behavior points to the S3 bucket origin (not EC2):

```bash
# Check current origin for default behavior
aws cloudfront get-distribution --id [YOUR_DISTRIBUTION_ID] \
  --query 'Distribution.DistributionConfig.DefaultCacheBehavior.TargetOriginId' \
  --output text

# Update CloudFront to use S3 bucket for default behavior
# 1. Get current config and ETag
aws cloudfront get-distribution-config --id [YOUR_DISTRIBUTION_ID] > tmp.json
etag=$(jq -r '.ETag' tmp.json)

# 2. Modify config to use S3 origin
jq '.DistributionConfig.DefaultCacheBehavior.TargetOriginId = "S3-[YOUR_BUCKET_NAME]"' tmp.json > tmp2.json
jq '.DistributionConfig' tmp2.json > config.json

# 3. Update distribution
aws cloudfront update-distribution --id [YOUR_DISTRIBUTION_ID] \
  --if-match "$etag" \
  --distribution-config file://config.json

# 4. Create invalidation
aws cloudfront create-invalidation --distribution-id [YOUR_DISTRIBUTION_ID] --paths "/*"
```

### 3. Database Connection Issues

**Problem**: Container exits immediately due to database connectivity issues.

**Solution**: 
- Check your `DATABASE_URL` format
- Ensure RDS security group allows traffic from EC2
- For local testing, use `?sslmode=disable` in the connection string
- For production, ensure proper SSL certificates are in place

Example connection string format:
```
postgres://[username]:[password]@[hostname]:[port]/[database_name]?sslmode=disable
```

### 4. Nginx Configuration Errors

**Problem**: Nginx fails to start due to configuration errors.

**Solution**: Use this basic configuration for Nginx:

```nginx
server {
    listen 80 default_server;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /api {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /health {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
    }
}
```

## Troubleshooting Steps

If the application is not working as expected, follow these steps:

1. **Check if container is running:**
   ```bash
   docker ps | grep ptchampion
   ```

2. **Examine container logs:**
   ```bash
   docker logs ptchampion-go-backend
   ```

3. **Test health endpoint directly on EC2:**
   ```bash
   curl -v localhost:8080/health
   curl -v localhost:8080/api/v1/health
   ```

4. **Test health endpoint through Nginx:**
   ```bash
   curl -v http://[EC2_IP]/health
   curl -v http://[EC2_IP]/api/v1/health
   ```

5. **Check RDS connectivity:**
   ```bash
   nc -vz [RDS_HOSTNAME] 5432
   ```

6. **Verify CloudFront settings:**
   ```bash
   aws cloudfront get-distribution --id [DISTRIBUTION_ID] --query 'Distribution.DistributionConfig.Origins.Items'
   aws cloudfront get-distribution --id [DISTRIBUTION_ID] --query 'Distribution.DistributionConfig.CacheBehaviors'
   ```

7. **Create CloudFront invalidation:**
   ```bash
   aws cloudfront create-invalidation --distribution-id [DISTRIBUTION_ID] --paths "/*"
   ```

## Monitoring

Once deployed, monitor your application using:

1. CloudWatch for EC2 and RDS metrics
2. CloudFront access logs for CDN performance and request patterns
3. Container logs for application-specific errors

Remember that CloudFront changes can take 5-30 minutes to propagate globally. 