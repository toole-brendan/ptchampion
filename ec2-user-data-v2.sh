#!/bin/bash
# Log everything to a file
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "--- Starting User Data Script ---"

# Update and install dependencies
echo "Updating packages and installing dependencies..."
yum update -y
yum install -y git
curl -sL https://rpm.nodesource.com/setup_18.x | bash -
yum install -y nodejs
npm install -g pm2

# Install nginx
echo "Installing nginx..."
amazon-linux-extras install -y nginx1 || dnf install -y nginx

# Clone repository
echo "Cloning repository..."
cd /home/ec2-user
git clone https://github.com/toole-brendan/ptchampion.git
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to clone repository."
    exit 1
fi
cd ptchampion
chown -R ec2-user:ec2-user /home/ec2-user/ptchampion

# Install dependencies and build
echo "Installing npm dependencies..."
sudo -u ec2-user npm install
if [ $? -ne 0 ]; then
    echo "ERROR: npm install failed."
    exit 1
fi

echo "Building the application..."
sudo -u ec2-user npm run build
if [ $? -ne 0 ]; then
    echo "ERROR: npm run build failed."
    exit 1
fi
if [ ! -d "dist" ]; then
    echo "ERROR: Build failed - dist directory not found"
    exit 1
fi

# Create .env.production file
echo "Creating .env.production file..."
cat > .env.production << 'ENVEOF'
NODE_ENV=production
NODE_TLS_REJECT_UNAUTHORIZED=0

# AWS RDS PostgreSQL Connection
DATABASE_URL=postgres://postgres:Dunlainge1!@ptchampion-1-instance-1.ck9iecaw2h6w.us-east-1.rds.amazonaws.com:5432/postgres

# JWT configuration
JWT_SECRET=f8a4c3ff94e950fa7b1245d3fe57562d148c371aab9233428c849e9d7ba6d251
JWT_EXPIRES_IN=24h

# Server port configuration
PORT=3000

# Log level
LOG_LEVEL=info
ENVEOF
chown ec2-user:ec2-user .env.production

# Initialize database with schema
echo "Initializing database schema..."
sudo -u ec2-user NODE_ENV=production npm run db:push
if [ $? -ne 0 ]; then
    echo "ERROR: Database initialization (db:push) failed."
    # Decide if this is critical. Maybe the app can start without it?
    # For now, let's proceed but log the error.
fi

# Start the server with PM2
echo "Starting the application with PM2..."
sudo -u ec2-user NODE_ENV=production pm2 start dist/index.js --name ptchampion-api
# Ensure PM2 restarts on boot
pm2 startup systemd -u ec2-user --hp /home/ec2-user
pm2 save --force

# Configure Nginx as a reverse proxy
echo "Configuring Nginx..."
cat > /etc/nginx/conf.d/ptchampion.conf << 'NGINXEOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _; # Listen for all hostnames

    location / {
        proxy_pass http://localhost:3000; # Forward requests to Node app
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }

    # Optional: Add error pages, access logs etc.
    access_log /var/log/nginx/ptchampion.access.log;
    error_log /var/log/nginx/ptchampion.error.log;
}
NGINXEOF

# Test Nginx configuration
nginx -t
if [ $? -ne 0 ]; then
    echo "ERROR: Nginx configuration test failed."
    # Attempt to start anyway, but log the error
fi

# Enable and start Nginx
echo "Enabling and starting Nginx..."
systemctl enable nginx
systemctl restart nginx # Use restart to ensure it picks up new config

echo "--- User Data Script Finished ---"
