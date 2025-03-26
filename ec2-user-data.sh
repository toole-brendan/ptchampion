#!/bin/bash
yum update -y
yum install -y git
curl -sL https://rpm.nodesource.com/setup_18.x | bash -
yum install -y nodejs
npm install -g pm2

# Install nginx for Amazon Linux 2023
dnf install -y nginx

# Clone repository
cd /home/ec2-user
git clone https://github.com/toole-brendan/ptchampion.git
cd ptchampion

# Install dependencies in root and server directories
npm install
cd server
npm install
cd ..

# Build the application
npm run build

# Create .env.production file in the root directory
cat > .env.production << 'ENVEOF'
NODE_ENV=production
NODE_TLS_REJECT_UNAUTHORIZED=0

# AWS RDS PostgreSQL Connection
DATABASE_URL=postgres://postgres:Dunlainge1!@ptchampion-1-instance-1.ck9iecaw2h6w.us-east-1.rds.amazonaws.com:5432/postgres

# JWT configuration
JWT_SECRET=use-a-secure-random-string-in-production
JWT_EXPIRES_IN=24h

# Server port configuration
PORT=3000
ENVEOF

# Initialize database with schema and seed data
NODE_ENV=production npm run db:push

# Start the server with PM2 from the server directory
cd server
NODE_ENV=production pm2 start index.ts --name ptchampion-api
pm2 startup
pm2 save
cd ..

# Configure Nginx as a reverse proxy
cat > /etc/nginx/conf.d/ptchampion.conf << 'NGINXEOF'
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
NGINXEOF

# Enable and start Nginx
systemctl enable nginx
systemctl start nginx 