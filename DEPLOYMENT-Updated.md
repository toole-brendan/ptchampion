# PT Champion AWS Deployment Guide (Tailored)

This guide provides detailed instructions for deploying the PT Champion application to AWS using your specific configuration details.

## Architecture Overview

The PT Champion deployment architecture consists of:

1. **Web Frontend**: React application deployed to S3 bucket `ptchampion.ai` and served via CloudFront CDN (Distribution ID: `E1FRFF3JQNGRE1`)
2. **Backend API**: Node.js/Express API deployed on AWS EC2 instance (t2.micro)
3. **Database**: PostgreSQL on AWS RDS (`ptchampion-1-instance-1.ck9iecaw2h6w.us-east-1.rds.amazonaws.com`)
4. **Mobile Apps**: 
   - iOS app deployed to Apple App Store
   - Android app deployed to Google Play Store
5. **Security**: SSL/TLS certificates for HTTPS connections

## Prerequisites

1. An AWS account with appropriate permissions
2. AWS CLI installed and configured on your local machine
3. Node.js (v18+) and npm installed
4. Git for version control
5. For mobile deployment:
   - Xcode 14+ (for iOS)
   - Android Studio (for Android)
   - Apple Developer account ($99/year)
   - Google Play Developer account ($25 one-time fee)

## Environment Configuration

Create an `.env.production` file with your production settings:

```
NODE_ENV=production
NODE_TLS_REJECT_UNAUTHORIZED=0

# AWS RDS PostgreSQL Connection
DATABASE_URL=postgres://postgres:Dunlainge1!@ptchampion-1-instance-1.ck9iecaw2h6w.us-east-1.rds.amazonaws.com:5432/postgres

# JWT configuration
# Use a strong, randomly generated secret in production
JWT_SECRET=use-a-secure-random-string-in-production
JWT_EXPIRES_IN=24h

# Redis configuration for caching - Update if using AWS ElastiCache
REDIS_URL=redis://your-elasticache-endpoint:6379
CACHE_TTL=300 # 5 minutes in seconds
DISABLE_CACHE=false

# Server port configuration
PORT=3000

# Set to true to enable HTTPS
USE_HTTPS=true

# SSL/TLS certificate paths
SSL_CERT_PATH=path/to/cert.pem
SSL_KEY_PATH=path/to/key.pem

# AWS S3 Configuration
AWS_REGION=us-east-1
AWS_S3_BUCKET=ptchampion.ai

# Log level
LOG_LEVEL=info

# Rate limiting
# Adjust based on expected load
RATE_LIMIT_WINDOW_MS=900000 # 15 minutes
RATE_LIMIT_MAX=100
AUTH_RATE_LIMIT_MAX=20
HEAVY_OP_RATE_LIMIT_MAX=10
```

## Automated Deployment Script

For streamlined deployments, use this automated deployment script:

```bash
#!/bin/bash
set -e

# PT Champion Full AWS Deployment Script
# This script handles the complete AWS deployment process

echo "🚀 Starting full AWS deployment for PT Champion..."

# Check for required tools
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI is required but not installed. Please install AWS CLI and try again."
    exit 1
fi

if ! command -v node &> /dev/null; then
    echo "❌ Node.js is required but not installed. Please install Node.js and try again."
    exit 1
fi

# Variables - specific to your deployment
S3_BUCKET="ptchampion.ai"
DOMAIN_NAME="ptchampion.ai"
EC2_INSTANCE_TYPE="t2.micro"
EC2_KEY_NAME="ptchampion-key"
AWS_REGION="us-east-1"
CLOUDFRONT_DISTRIBUTION_ID="E1FRFF3JQNGRE1"
RDS_ENDPOINT="ptchampion-1-instance-1.ck9iecaw2h6w.us-east-1.rds.amazonaws.com"
RDS_USERNAME="postgres"
RDS_PASSWORD="Dunlainge1!"
RDS_DATABASE="postgres"

# Load environment variables
echo "📦 Loading production environment variables..."
if [ -f ".env.production" ]; then
    # Load env vars without comments
    set -a
    source <(grep -v '^#' .env.production)
    set +a
else
    echo "⚠️ .env.production file not found. Using default environment variables."
fi

# Step 1: Build the application
echo "🔨 Building application..."
npm install
npm run build

if [ ! -d "dist" ]; then
    echo "❌ Build failed - dist directory not found"
    exit 1
fi

# Step 2: Deploy to S3
echo "☁️ Deploying frontend to S3..."
# Check if bucket exists, create if not
if ! aws s3api head-bucket --bucket "$S3_BUCKET" 2>/dev/null; then
    echo "📦 Creating S3 bucket: $S3_BUCKET"
    aws s3api create-bucket --bucket "$S3_BUCKET" --region "$AWS_REGION"
    
    # Configure bucket for website hosting
    aws s3 website "s3://$S3_BUCKET/" --index-document index.html --error-document index.html
    
    # Set bucket policy for public access
    cat > bucket-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::$S3_BUCKET/*"
        }
    ]
}
EOF
    aws s3api put-bucket-policy --bucket "$S3_BUCKET" --policy file://bucket-policy.json
    rm bucket-policy.json
fi

# Upload files to S3
echo "📤 Uploading files to S3..."
aws s3 sync dist/public/ "s3://$S3_BUCKET/" --delete

# Step 3: Setup CloudFront
echo "🌐 Setting up CloudFront..."
# Check if distribution exists
if aws cloudfront get-distribution --id "$CLOUDFRONT_DISTRIBUTION_ID" &>/dev/null; then
    echo "✅ CloudFront distribution exists, creating invalidation..."
    aws cloudfront create-invalidation --distribution-id "$CLOUDFRONT_DISTRIBUTION_ID" --paths "/*"
else
    echo "🔄 Setting up new CloudFront distribution..."
    
    # Get S3 website endpoint
    S3_REGION=$(aws s3api get-bucket-location --bucket "$S3_BUCKET" --query "LocationConstraint" --output text)
    if [ "$S3_REGION" = "None" ] || [ "$S3_REGION" = "null" ]; then
        S3_REGION="us-east-1"
    fi
    S3_WEBSITE_ENDPOINT="${S3_BUCKET}.s3-website-${S3_REGION}.amazonaws.com"
    
    # Create CloudFront distribution
    cat > cloudfront-config.json << EOF
{
  "CallerReference": "setup-$(date +%s)",
  "Aliases": {
    "Quantity": 1,
    "Items": ["${DOMAIN_NAME}"]
  },
  "DefaultRootObject": "index.html",
  "Origins": {
    "Quantity": 1,
    "Items": [
      {
        "Id": "S3-${S3_BUCKET}",
        "DomainName": "${S3_WEBSITE_ENDPOINT}",
        "OriginPath": "",
        "CustomHeaders": {
          "Quantity": 0
        },
        "CustomOriginConfig": {
          "HTTPPort": 80,
          "HTTPSPort": 443,
          "OriginProtocolPolicy": "http-only",
          "OriginSslProtocols": {
            "Quantity": 1,
            "Items": ["TLSv1.2"]
          },
          "OriginReadTimeout": 30,
          "OriginKeepaliveTimeout": 5
        }
      }
    ]
  },
  "DefaultCacheBehavior": {
    "TargetOriginId": "S3-${S3_BUCKET}",
    "ViewerProtocolPolicy": "redirect-to-https",
    "AllowedMethods": {
      "Quantity": 2,
      "Items": ["GET", "HEAD"],
      "CachedMethods": {
        "Quantity": 2,
        "Items": ["GET", "HEAD"]
      }
    },
    "CachePolicyId": "658327ea-f89d-4fab-a63d-7e88639e58f6",
    "Compress": true
  },
  "Comment": "CloudFront distribution for ${DOMAIN_NAME}",
  "Enabled": true,
  "ViewerCertificate": {
    "CloudFrontDefaultCertificate": true,
    "MinimumProtocolVersion": "TLSv1.2_2021"
  },
  "HttpVersion": "http2",
  "PriceClass": "PriceClass_100",
  "CustomErrorResponses": {
    "Quantity": 1,
    "Items": [
      {
        "ErrorCode": 404,
        "ResponsePagePath": "/index.html",
        "ResponseCode": "200",
        "ErrorCachingMinTTL": 300
      }
    ]
  }
}
EOF
    
    # Create the CloudFront distribution
    DISTRIBUTION_INFO=$(aws cloudfront create-distribution --distribution-config file://cloudfront-config.json)
    CLOUDFRONT_DISTRIBUTION_ID=$(echo "$DISTRIBUTION_INFO" | grep -o '"Id": "[^"]*' | cut -d'"' -f4)
    CLOUDFRONT_DOMAIN=$(echo "$DISTRIBUTION_INFO" | grep -o '"DomainName": "[^"]*' | cut -d'"' -f4)
    
    echo "✅ Created CloudFront distribution: $CLOUDFRONT_DISTRIBUTION_ID"
    echo "🌎 CloudFront domain: $CLOUDFRONT_DOMAIN"
    
    # Save the distribution ID for future reference
    echo "CLOUDFRONT_DISTRIBUTION_ID=$CLOUDFRONT_DISTRIBUTION_ID" > cloudfront-info.txt
    
    # Clean up
    rm cloudfront-config.json
fi

# Step 4: Deploy backend on EC2
echo "🖥️ Setting up EC2 instance..."

# Check if EC2 key pair exists, create if not
if ! aws ec2 describe-key-pairs --key-names "$EC2_KEY_NAME" &>/dev/null; then
    echo "🔑 Creating EC2 key pair: $EC2_KEY_NAME"
    aws ec2 create-key-pair --key-name "$EC2_KEY_NAME" --query "KeyMaterial" --output text > "${EC2_KEY_NAME}.pem"
    chmod 400 "${EC2_KEY_NAME}.pem"
fi

# Create security group
SECURITY_GROUP_NAME="ptchampion-sg"
SECURITY_GROUP_ID=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=$SECURITY_GROUP_NAME" --query "SecurityGroups[0].GroupId" --output text 2>/dev/null)

if [ "$SECURITY_GROUP_ID" = "None" ] || [ -z "$SECURITY_GROUP_ID" ]; then
    echo "🔒 Creating security group: $SECURITY_GROUP_NAME"
    SECURITY_GROUP_ID=$(aws ec2 create-security-group --group-name "$SECURITY_GROUP_NAME" --description "Security group for PTChampion app" --query "GroupId" --output text)
    
    # Allow SSH, HTTP and HTTPS
    aws ec2 authorize-security-group-ingress --group-id "$SECURITY_GROUP_ID" --protocol tcp --port 22 --cidr 0.0.0.0/0
    aws ec2 authorize-security-group-ingress --group-id "$SECURITY_GROUP_ID" --protocol tcp --port 80 --cidr 0.0.0.0/0
    aws ec2 authorize-security-group-ingress --group-id "$SECURITY_GROUP_ID" --protocol tcp --port 443 --cidr 0.0.0.0/0
    aws ec2 authorize-security-group-ingress --group-id "$SECURITY_GROUP_ID" --protocol tcp --port 3000 --cidr 0.0.0.0/0
fi

# Create user data script
cat > ec2-user-data.sh << EOF
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
git clone https://github.com/yourusername/ptchampion.git
cd ptchampion

# Install dependencies and build
npm install
npm run build

# Create .env.production file
cat > .env.production << 'ENVEOF'
NODE_ENV=production
NODE_TLS_REJECT_UNAUTHORIZED=0

# AWS RDS PostgreSQL Connection
DATABASE_URL=postgres://${RDS_USERNAME}:${RDS_PASSWORD}@${RDS_ENDPOINT}:5432/${RDS_DATABASE}

# JWT configuration
# Use a strong, randomly generated secret in production
JWT_SECRET=use-a-secure-random-string-in-production
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
EOF

# Check if EC2 instance is already running
INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=ptchampion-server" "Name=instance-state-name,Values=running" --query "Reservations[0].Instances[0].InstanceId" --output text)

if [ "$INSTANCE_ID" = "None" ] || [ -z "$INSTANCE_ID" ]; then
    echo "🚀 Launching new EC2 instance..."
    
    # Terminate any existing instances with the same name but not running
    OLD_INSTANCE_IDS=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=ptchampion-server" "Name=instance-state-name,Values=pending,stopping,stopped" --query "Reservations[].Instances[].InstanceId" --output text)
    if [ -n "$OLD_INSTANCE_IDS" ]; then
        echo "🧹 Cleaning up old instances..."
        for OLD_ID in $OLD_INSTANCE_IDS; do
            echo "   Terminating instance $OLD_ID"
            aws ec2 terminate-instances --instance-ids "$OLD_ID" > /dev/null
        done
    fi
    
    # Launch new instance with user data
    INSTANCE_ID=$(aws ec2 run-instances \
        --image-id ami-0e731c8a588258d0d \
        --instance-type "$EC2_INSTANCE_TYPE" \
        --key-name "$EC2_KEY_NAME" \
        --security-group-ids "$SECURITY_GROUP_ID" \
        --user-data file://ec2-user-data.sh \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=ptchampion-server}]" \
        --query "Instances[0].InstanceId" \
        --output text)
    
    echo "⏳ Waiting for instance to be running..."
    aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"
    
    # Get instance public IP
    INSTANCE_IP=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" --query "Reservations[0].Instances[0].PublicIpAddress" --output text)
    echo "✅ EC2 instance launched with IP: $INSTANCE_IP"
    echo "🔑 Connect with: ssh -i ${EC2_KEY_NAME}.pem ec2-user@$INSTANCE_IP"
    
    # Wait for the instance to complete initialization
    echo "⏳ Waiting for instance initialization (this may take a few minutes)..."
    echo "   You can check the status with: ssh -i ${EC2_KEY_NAME}.pem ec2-user@$INSTANCE_IP 'sudo cat /var/log/cloud-init-output.log'"
    
    # Sleep for a short time to allow initialization to start
    sleep 10
else
    echo "✅ EC2 instance already running: $INSTANCE_ID"
    INSTANCE_IP=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" --query "Reservations[0].Instances[0].PublicIpAddress" --output text)
    echo "🖥️ Instance IP: $INSTANCE_IP"
    
    # Update CloudFront distribution with the EC2 backend origin if needed
    echo "🔄 Updating CloudFront configuration to point to EC2 backend..."
    EC2_DOMAIN="$INSTANCE_IP"
    
    # Update CloudFront for API requests if needed
    if [ -f "update-cloudfront.js" ]; then
        echo "   Running CloudFront update script..."
        EC2_DOMAIN=$EC2_DOMAIN node update-cloudfront.js
    fi
fi

# Clean up temp file
rm -f ec2-user-data.sh

echo "✅ Deployment complete!"
echo ""
echo "🌐 Frontend: https://$DOMAIN_NAME (via CloudFront)"
echo "🖥️ Backend: http://$INSTANCE_IP:3000 (via EC2)"
echo ""
echo "✨ Next steps:"
echo "1. Wait a few minutes for CloudFront distribution to fully deploy"
echo "2. If you're using a custom domain, configure Route 53 or your DNS provider to point to CloudFront"
echo "3. To SSH into your EC2 instance: ssh -i ${EC2_KEY_NAME}.pem ec2-user@$INSTANCE_IP" 
```

## Manual Deployment Steps

If you prefer a manual approach, here are the step-by-step instructions:

### 1. Database Setup (RDS)

Your RDS instance is already configured at:
- Endpoint: `ptchampion-1-instance-1.ck9iecaw2h6w.us-east-1.rds.amazonaws.com`
- Username: `postgres`
- Password: `Dunlainge1!`
- Database: `postgres`

### 2. Backend Deployment (EC2)

1. Launch an EC2 instance:
   ```bash
   aws ec2 run-instances \
       --image-id ami-0e731c8a588258d0d \
       --instance-type t2.micro \
       --key-name ptchampion-key \
       --security-group-ids [your-security-group-id] \
       --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=ptchampion-server}]"
   ```

2. SSH into your instance:
   ```bash
   ssh -i ptchampion-key.pem ec2-user@[your-instance-ip]
   ```

3. Install dependencies:
   ```bash
   sudo yum update -y
   sudo yum install -y git
   curl -sL https://rpm.nodesource.com/setup_18.x | sudo bash -
   sudo yum install -y nodejs
   sudo npm install -g pm2
   ```

4. Clone and build your application:
   ```bash
   git clone [your-repository-url]
   cd ptchampion
   npm install
   npm run build
   ```

5. Create `.env.production` file with your environment variables

6. Initialize the database and start the server:
   ```bash
   NODE_ENV=production npm run db:push
   NODE_ENV=production pm2 start dist/index.js --name ptchampion-api
   pm2 startup
   pm2 save
   ```

### 3. Frontend Deployment (S3 and CloudFront)

1. Create and configure S3 bucket for website hosting:
   ```bash
   aws s3api create-bucket --bucket ptchampion.ai --region us-east-1
   aws s3 website s3://ptchampion.ai/ --index-document index.html --error-document index.html
   ```

2. Set bucket policy for public access:
   ```json
   {
       "Version": "2012-10-17",
       "Statement": [
           {
               "Sid": "PublicReadGetObject",
               "Effect": "Allow",
               "Principal": "*",
               "Action": "s3:GetObject",
               "Resource": "arn:aws:s3:::ptchampion.ai/*"
           }
       ]
   }
   ```

3. Build and upload the frontend:
   ```bash
   npm run build
   aws s3 sync dist/public/ s3://ptchampion.ai/ --delete
   ```

4. Create CloudFront invalidation after deploying updates:
   ```bash
   aws cloudfront create-invalidation --distribution-id E1FRFF3JQNGRE1 --paths "/*"
   ```

## Mobile App Configuration

### iOS App (Swift)

1. Update the API endpoint in `APIClient.swift`:
   ```swift
   private let baseURL = "https://ptchampion.ai/api"
   ```

### Android App (Kotlin)

1. Update the API endpoint in `build.gradle`:
   ```gradle
   buildTypes {
       release {
           buildConfigField "String", "API_BASE_URL", "\"https://ptchampion.ai/api\""
       }
   }
   ```

## Security Best Practices

1. **Database Security**:
   - Restrict RDS security group to only allow connections from your EC2 instance
   - Regularly update the database password

2. **JWT Secrets**:
   - Generate a strong random JWT secret:
     ```bash
     openssl rand -hex 32
     ```
   - Update it regularly in your production environment

3. **HTTPS and SSL/TLS**:
   - Use AWS Certificate Manager to generate SSL certificates
   - Configure CloudFront to use HTTPS with TLS 1.2+

4. **Regular Backups**:
   - Set up automated RDS snapshots
   - Configure S3 versioning for frontend assets

## Monitoring and Maintenance

1. Set up CloudWatch Alarms for:
   - EC2 CPU utilization (>80%)
   - RDS connections (>80% of max)
   - RDS storage space (<20% free)

2. Create a log monitoring strategy with CloudWatch Logs:
   ```bash
   # Install CloudWatch agent on EC2
   sudo yum install -y amazon-cloudwatch-agent
   ```

3. Configure regular maintenance windows for patching and updates

## Troubleshooting

1. **CloudFront Caching Issues**:
   - Create invalidations for updated content: 
     ```bash
     aws cloudfront create-invalidation --distribution-id E1FRFF3JQNGRE1 --paths "/*"
     ```

2. **EC2 Connectivity Issues**:
   - Check security group inbound rules
   - Verify the instance is running: 
     ```bash
     aws ec2 describe-instances --filters "Name=tag:Name,Values=ptchampion-server"
     ```

3. **Database Connection Issues**:
   - Test connection from EC2:
     ```bash
     psql -h ptchampion-1-instance-1.ck9iecaw2h6w.us-east-1.rds.amazonaws.com -U postgres -d postgres
     ```
   - Check security group rules for RDS

## Conclusion

This customized deployment guide is tailored specifically for your PT Champion application deployment on AWS. The guide incorporates your specific AWS resources, including the RDS endpoint, CloudFront distribution ID, and other configuration details.

Follow these instructions to deploy and maintain your application effectively in the AWS environment.