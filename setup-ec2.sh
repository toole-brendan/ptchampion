#!/bin/bash
# Setup script for EC2 instance prerequisites

EC2_IP="23.20.242.95"
KEY_FILE="ptchampion-key-new.pem"

echo "===== Setting up EC2 instance at $EC2_IP ====="
echo "This will install Docker, AWS CLI, and Nginx on your EC2 instance."

# Connect to EC2 and set up prerequisites
ssh -i $KEY_FILE -o StrictHostKeyChecking=no ec2-user@$EC2_IP << 'EOF'
set -e  # Exit immediately if a command fails

echo "===== Updating System Packages ====="
sudo yum update -y

echo "===== Installing Docker ====="
# Check if Docker is already installed
if ! command -v docker &> /dev/null; then
    sudo amazon-linux-extras install docker -y
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -aG docker ec2-user
    echo "Docker installed successfully. You'll need to log out and back in for group changes to take effect."
else
    echo "Docker is already installed."
fi

echo "===== Installing AWS CLI ====="
# Check if AWS CLI is already installed
if ! command -v aws &> /dev/null; then
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    rm -rf aws awscliv2.zip
    echo "AWS CLI installed successfully."
else
    echo "AWS CLI is already installed."
fi

echo "===== Installing Nginx ====="
# Check if Nginx is already installed
if ! command -v nginx &> /dev/null; then
    sudo amazon-linux-extras install nginx1 -y
    sudo systemctl start nginx
    sudo systemctl enable nginx
    echo "Nginx installed successfully."
else
    echo "Nginx is already installed."
fi

echo "===== Creating directory for application ====="
mkdir -p ~/ptchampion-go

echo "===== Verifying Installations ====="
docker --version
aws --version
nginx -v

echo "===== All prerequisites installed successfully! ====="
# Note: You'll need to log out and back in for the docker group permissions to take effect
EOF

echo "===== Setup script completed ====="
echo "Remember to log back into the EC2 instance for Docker group permissions to take effect." 