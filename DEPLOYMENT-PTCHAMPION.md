# PT Champion Deployment Guide

## Deployment Architecture

The PT Champion application is deployed using the following architecture:

1. **EC2 Instance**: Hosts Docker containers for the backend, frontend, and database
2. **CloudFront Distribution**: Routes traffic from ptchampion.ai to the appropriate destinations:
   - Frontend requests go to an S3 bucket (static hosting)
   - API requests are routed to the EC2 instance

## Current Configuration

- **Domain**: ptchampion.ai
- **EC2 Instance**: ec2-3-89-124-135.compute-1.amazonaws.com (3.89.124.135)
- **CloudFront Distribution ID**: E1FRFF3JQNGRE1
- **CloudFront Domain**: d27xkawvwy48u.cloudfront.net

## Deployment Components

### 1. Backend Server (Docker)

The backend server runs on the EC2 instance through Docker. It uses a simplified production server that doesn't rely on Vite in production, avoiding dependency issues.

### 2. Frontend Serving

The frontend is served in two ways:
- Through the Docker Nginx container on the EC2 instance (for development/testing)
- Through CloudFront + S3 for production traffic from ptchampion.ai

## Deployment Steps

### Deploying to EC2 Instance

Use the deployment script to build and deploy to EC2:

```bash
./ptchampion-deploy.sh --deploy
```

This script:
1. Builds the application locally
2. Packages it for deployment
3. Copies it to the EC2 instance
4. Sets up and starts Docker containers

After deployment, the application is available at:
- http://3.89.124.135:8080 (EC2 instance direct access)
- http://ptchampion.ai (through CloudFront)

### CloudFront Configuration

The CloudFront distribution is already set up to route:
- API requests (/api/*) to the EC2 instance
- All other requests to an S3 bucket for static content

If you need to update the CloudFront configuration, use:

```bash
./fix-cloudfront.sh
```

## Troubleshooting

### Backend Issues

If the backend is not responding:

1. Check Docker container status on EC2:
   ```bash
   ssh -i ptchampion-key.pem ec2-user@3.89.124.135 "docker ps"
   ```

2. View backend logs:
   ```bash
   ssh -i ptchampion-key.pem ec2-user@3.89.124.135 "docker logs ptchampion-backend"
   ```

3. Restart containers if needed:
   ```bash
   ssh -i ptchampion-key.pem ec2-user@3.89.124.135 "cd ~/ptchampion_deploy && docker-compose restart"
   ```

### CloudFront Issues

1. Create a new invalidation to refresh content:
   ```bash
   aws cloudfront create-invalidation --distribution-id E1FRFF3JQNGRE1 --paths "/*" "/api/*"
   ```

2. Verify the CloudFront configuration routes to the correct origins.

## S3 Bucket Deployment

We've created a script to deploy the frontend directly to the S3 bucket:

```bash
# Deploy frontend to S3 and create CloudFront invalidation
./deploy-s3.sh --deploy

# Only create a CloudFront invalidation (if you've made changes manually)
./deploy-s3.sh --invalidate-only
```

This script will:
1. Check if the frontend is built, and build it if needed
2. Sync the built files to the S3 bucket
3. Create a CloudFront invalidation to refresh the cache
4. Provide feedback on the deployment process

## Maintenance

The Docker containers are configured to restart automatically unless explicitly stopped. The database data is persisted through a Docker volume.
