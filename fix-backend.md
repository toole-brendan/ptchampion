# PT Champion Backend Fix Instructions

## Issue Identified

The current issue with user registration is due to the following problems:

1. The Nginx server on the EC2 instance (`3.89.124.135`) is serving the frontend application for all routes, including API routes (`/api/*`)
2. The Express backend application on port 3000 doesn't appear to be running or properly accessible
3. The CloudFront configuration is correctly set up, but it's pointing to a backend that isn't properly handling API requests

## Fix Options

### Option 1: SSH into the EC2 instance (if you have the key)

If you have the SSH key (`ptchampion-key.pem`), you can connect to the instance and fix it:

```bash
ssh -i ptchampion-key.pem ec2-user@3.89.124.135
```

Then run these commands to fix the Nginx configuration and restart the services:

```bash
# Fix Nginx configuration to properly route API requests
sudo tee /etc/nginx/conf.d/ptchampion.conf > /dev/null << 'EOF'
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
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
EOF

# Restart Nginx
sudo systemctl restart nginx

# Check PM2 status
pm2 list

# Restart the backend service
cd /home/ec2-user/ptchampion
pm2 restart ptchampion-api || pm2 start dist/index.js --name ptchampion-api
```

### Option 2: Launch a new EC2 instance

If you don't have SSH access, create a new EC2 instance with the following user data script:

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
git clone https://github.com/toole-brendan/ptchampion.git
cd ptchampion

# Install dependencies and build
npm install
npm run build

# Create .env.production file
cat > .env.production << 'ENVEOF'
NODE_ENV=production
NODE_TLS_REJECT_UNAUTHORIZED=0

# AWS RDS PostgreSQL Connection
DATABASE_URL=postgres://postgres:Dunlainge1!@ptchampion-1-instance-1.ck9iecaw2h6w.us-east-1.rds.amazonaws.com:5432/postgres

# JWT configuration
JWT_SECRET=$(openssl rand -hex 32)
JWT_EXPIRES_IN=24h

# Server port configuration
PORT=3000
ENVEOF

# Initialize database with schema and seed data
NODE_ENV=production npm run db:push

# Start the server with PM2
NODE_ENV=production pm2 start dist/index.js --name ptchampion-api
pm2 startup
pm2 save

# Configure Nginx with proper API routing
cat > /etc/nginx/conf.d/ptchampion.conf << 'NGINXEOF'
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
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
NGINXEOF

# Enable and start Nginx
systemctl enable nginx
systemctl start nginx
```

After launching the new instance, update the CloudFront distribution to point to the new instance's public DNS name.

### Option 3: Temporary workaround - deploy to a serverless platform

As a quick workaround, you could deploy the backend to a serverless platform like Vercel, AWS Lambda, or Railway, then update CloudFront to point to that instead.

## Next Steps

1. After applying any of these fixes, wait a few minutes for CloudFront to update and the invalidation to complete
2. Try the registration process again
3. If still unsuccessful, check CloudFront logs for errors
4. If possible, SSH into the EC2 instance and check logs in `/var/log/nginx/error.log` and the output of `pm2 logs` 