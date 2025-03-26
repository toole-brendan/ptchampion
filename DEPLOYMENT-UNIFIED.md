# PT Champion Unified Deployment Guide

This guide explains how to use the unified deployment script for deploying the PT Champion application to S3 with a working backend.

## Deployment Architecture

The PT Champion application uses the following architecture:

1. **Frontend**: Hosted on S3, served through CloudFront
2. **Backend API**: Running on a dedicated EC2 instance (ptchampion-api)
3. **CloudFront Distribution**: Routes requests between frontend (S3) and backend (EC2)

## Prerequisites

Before deploying, ensure you have:

1. AWS CLI installed and configured with proper credentials
2. SSH key file `ptchampion-key.pem` (for backend configuration)
3. EC2 API instance with the backend code deployed (currently 52.1.128.170)
4. Properly configured S3 bucket and CloudFront distribution

## Deployment Using the Unified Script

The `deploy-s3.sh` script handles the complete deployment process:

```bash
# Full deployment (frontend + backend + CloudFront)
./deploy-s3.sh --deploy

# Deploy only the frontend to S3
./deploy-s3.sh --frontend-only

# Configure only the backend on EC2
./deploy-s3.sh --backend-only

# Just create a CloudFront invalidation
./deploy-s3.sh --invalidate-only

# Test API connection
./deploy-s3.sh --test-api
```

## What the Script Does

### Full Deployment (`--deploy`)

1. Builds the application if needed
2. Uploads frontend files to S3
3. Configures the backend on EC2:
   - Copies your `.env.production` file to the EC2 instance
   - Updates Nginx configuration
   - Restarts the backend service with the latest environment
4. Updates CloudFront configuration:
   - Ensures API requests route to the correct API EC2 instance
   - Creates an invalidation to refresh cache
5. Tests API connection

### Frontend-Only Deployment (`--frontend-only`)

1. Builds the application if needed
2. Uploads frontend files to S3
3. Creates a CloudFront invalidation

### Backend-Only Configuration (`--backend-only`)

1. Connects to API EC2 via SSH
2. Copies your `.env.production` file to synchronize environment variables
3. Updates Nginx configuration
4. Restarts the backend service 
5. Tests API connection

### Invalidation-Only (`--invalidate-only`)

1. Creates a CloudFront invalidation for both frontend and API paths

### Test API Connection (`--test-api`)

1. Tests direct connection to API EC2 instance
2. Tests connection through CloudFront
3. Reports success or failure

## Multi-Instance Setup

The PT Champion application uses multiple EC2 instances:

1. **ptchampion-api** (52.1.128.170): Dedicated API server handling all backend requests
2. **ptchampion-server** (3.89.124.135): Legacy server (not actively used)

The deployment script is now configured to work with the dedicated API instance.

## Troubleshooting

If you encounter issues:

1. **Frontend not updating**:
   - Check S3 bucket contents
   - Create a CloudFront invalidation: `./deploy-s3.sh --invalidate-only`

2. **Backend API not working**:
   - Test API connection: `./deploy-s3.sh --test-api`
   - Ensure EC2 security groups allow traffic on port 80/443
   - Check EC2 logs: `ssh -i ptchampion-key.pem ec2-user@52.1.128.170 "cat ~/ptchampion/app.log"`
   - Reconfigure backend: `./deploy-s3.sh --backend-only`

3. **Registration/Authentication Issues**:
   - Verify database connection in `.env.production` 
   - Deploy updated `.env.production` to EC2: `./deploy-s3.sh --backend-only`
   - Check backend logs for database connection errors

4. **CloudFront routing issues**:
   - Run full deployment: `./deploy-s3.sh --deploy`
   - Check CloudFront configuration in AWS Console

## Access URLs

- Frontend: https://ptchampion.ai
- API: https://ptchampion.ai/api
- EC2 direct API: http://52.1.128.170/api 