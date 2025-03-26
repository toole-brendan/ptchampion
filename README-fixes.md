# PT Champion Backend Fix Guide

This guide provides multiple solutions to fix the PT Champion backend routing issue where API requests are incorrectly returning HTML content instead of JSON data.

## The Problem

The error you're seeing ("Unexpected token '<', '<!DOCTYPE "... is not valid JSON") indicates that:

1. The Nginx server on your EC2 instance (3.89.124.135) is serving frontend HTML content for all routes, including API routes (`/api/*`)
2. The Express backend application running on port 3000 isn't receiving the API requests
3. Your frontend is trying to parse the HTML response as JSON, which fails with the error

## Solution Options

We've provided multiple solutions depending on your AWS setup and preferences:

### Option 1: Direct Nginx Fix (Quickest)

If you have SSH access to your EC2 instance with the key file:

```bash
ssh -i ptchampion-key.pem ec2-user@3.89.124.135 << "EOF"
  sudo tee /etc/nginx/conf.d/ptchampion.conf > /dev/null << "CONFEOF"
server {
    listen 80;
    server_name _;

    # Handle frontend requests
    location / {
        root /home/ec2-user/ptchampion/dist/public;
        try_files $uri $uri/ /index.html;
    }

    # Handle API requests
    location /api/ {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
CONFEOF

  sudo systemctl restart nginx
  
  # Restart the backend
  cd /home/ec2-user/ptchampion
  pm2 restart ptchampion-api || pm2 start dist/index.js --name ptchampion-api
EOF
```

### Option 2: AWS Systems Manager Fix (No SSH Required)

Use the AWS Systems Manager script if you don't have direct SSH access:

```bash
./aws-fix-backend.sh
```

This script:
- Finds your EC2 instance using the IP address
- Creates and runs an SSM document to update the Nginx configuration
- Restarts Nginx and the backend service

### Option 3: CloudFront Fix (For CloudFront-Enabled Deployments)

If your site is behind AWS CloudFront and the issue persists even after fixing the Nginx configuration, run:

```bash
./fix-cloudfront.sh
```

This script:
- Lists your CloudFront distributions
- Adds or updates a specific cache behavior for `/api*` paths
- Creates an invalidation to apply changes quickly

### Option 4: Complete Deployment (All Improvements)

For a comprehensive solution that includes security improvements, containerization, and proper configuration:

```bash
./deploy-updated.sh
```

This script:
1. Builds the application
2. Packages it with Docker configuration
3. Deploys to your EC2 instance
4. Sets up proper Nginx routing
5. Starts all services with Docker Compose
6. Optionally migrates existing passwords to bcrypt

## Security Improvements

We've made several security improvements to your codebase:

1. Replaced the custom crypto-based password hashing with industry-standard bcrypt
2. Added proper password comparison using bcrypt's secure comparison function
3. Created a password migration script to safely migrate existing plaintext passwords

## Containerization Benefits

The new Docker and Docker Compose setup provides:

1. Consistent environment between development and production
2. Proper isolation between frontend, backend, and database
3. Simplified scaling and management of the application
4. Easier deployment and rollback processes

## Verifying the Fix

After applying any of the fixes:

1. Try registering a new user
2. Check if the registration is successful
3. If there are still issues:
   - Check the CloudFront distribution settings
   - Verify the EC2 instance is running properly
   - Look at Nginx logs: `/var/log/nginx/error.log`
   - Check the backend logs: `pm2 logs ptchampion-api`

## Additional Resources

- [Nginx Reverse Proxy Documentation](https://docs.nginx.com/nginx/admin-guide/web-server/reverse-proxy/)
- [AWS CloudFront Distribution Settings](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-settings-reference.html)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
