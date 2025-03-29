#!/bin/bash
# EC2 User Data Script for PT Champion Fresh Install

# --- Configuration ---
APP_DIR="/home/ec2-user/ptchampion"
GIT_REPO="https://github.com/toole-brendan/ptchampion.git"
GIT_BRANCH="main" # Or specify a different branch if needed

# Secrets
DATABASE_URL="postgres://postgres:Dunlainge1!@ptchampion-1-instance-1.ck9iecaw2h6w.us-east-1.rds.amazonaws.com:5432/postgres"
JWT_SECRET="f8a4c3ff94e950fa7b1245d3fe57562d148c371aab9233428c849e9d7ba6d251"
SESSION_SECRET="d3b1e8a7f6c5d4e3f2a1b0c9d8e7f6a5b4c3d2e1f0a9b8c7d6e5f4a3b2c1d0e9" # Generated Secret

# --- Log Setup ---
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
echo "Starting user data script execution..."

# --- Install Dependencies ---
echo "Updating packages and installing Git, Docker..."
dnf update -y
dnf install -y git docker shadow-utils # shadow-utils includes usermod

# --- Start and Enable Docker ---
echo "Starting and enabling Docker service..."
systemctl start docker
systemctl enable docker

# --- Install Docker Compose ---
echo "Installing Docker Compose..."
# Get the latest version URL from GitHub releases
LATEST_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
# Construct the download URL for Linux x86_64
DOCKER_COMPOSE_URL="https://github.com/docker/compose/releases/download/${LATEST_COMPOSE_VERSION}/docker-compose-linux-x86_64"
# Download and install
curl -L $DOCKER_COMPOSE_URL -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
# Verify installation
docker-compose --version

# --- Configure Docker Permissions ---
echo "Adding ec2-user to the docker group..."
usermod -a -G docker ec2-user

# --- Clone Repository ---
echo "Cloning repository ${GIT_REPO} into ${APP_DIR}..."
# Ensure the target directory exists and is owned by ec2-user
mkdir -p ${APP_DIR}
chown ec2-user:ec2-user ${APP_DIR}
# Clone as ec2-user
sudo -u ec2-user git clone --branch ${GIT_BRANCH} ${GIT_REPO} ${APP_DIR}
cd ${APP_DIR}

# --- Create .env file ---
echo "Creating .env file with secrets..."
cat << EOF > ${APP_DIR}/.env
NODE_ENV=production
DATABASE_URL=${DATABASE_URL}
JWT_SECRET=${JWT_SECRET}
SESSION_SECRET=${SESSION_SECRET}
PORT=3000
EOF
chown ec2-user:ec2-user ${APP_DIR}/.env
chmod 600 ${APP_DIR}/.env # Restrict permissions

# --- Build and Start Application ---
echo "Building and starting application with Docker Compose..."
# Run docker-compose up as ec2-user
# Using full path just in case
sudo -u ec2-user /usr/local/bin/docker-compose up --build -d

echo "User data script finished."
