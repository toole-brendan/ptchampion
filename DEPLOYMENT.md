# PT Champion AWS Deployment Guide

This guide provides instructions on how to deploy the complete PT Champion ecosystem to AWS, including the web application and mobile clients (iOS and Android).

## Architecture Overview

The PT Champion deployment architecture consists of:

1. **Web Frontend**: React application deployed to S3 and served via CloudFront CDN
2. **Backend API**: Node.js/Express API deployed on AWS Elastic Beanstalk
3. **Database**: PostgreSQL on AWS RDS
4. **Mobile Apps**: 
   - iOS app deployed to Apple App Store
   - Android app deployed to Google Play Store
5. **Storage**: AWS S3 for user uploads and media content
6. **Authentication**: JWT-based authentication system with token refresh mechanism
7. **Monitoring**: AWS CloudWatch for logging and performance monitoring

## Prerequisites

1. An AWS account with appropriate permissions
2. AWS CLI installed and configured on your local machine
3. Node.js (v16+) and npm installed
4. Git for version control
5. For mobile deployment:
   - Xcode 14+ (for iOS)
   - Android Studio (for Android)
   - Apple Developer account ($99/year)
   - Google Play Developer account ($25 one-time fee)

## Initial AWS Setup

### 1. Configure AWS CLI

```bash
# Install AWS CLI if not already installed
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Configure with your credentials
aws configure
```

Provide the following when prompted:
- AWS Access Key ID
- AWS Secret Access Key
- Default region (e.g., us-east-1)
- Default output format (json is recommended)

### 2. Set Environment Variables

Create an `.env.production` file with your production settings:

```
NODE_ENV=production

# AWS RDS PostgreSQL Connection
DATABASE_URL=postgres://[username]:[password]@[rds-endpoint]:5432/[database]

# JWT configuration (used by both web and mobile apps)
JWT_SECRET=[generate-a-secure-random-string]
JWT_EXPIRES=7d

# Session configuration
SESSION_SECRET=[generate-a-secure-random-string]

# AWS S3 Configuration
S3_BUCKET_NAME=ptchampion-media
AWS_REGION=us-east-1
```

# Redis configuration for caching (if using ElastiCache)
REDIS_URL=redis://[redis-endpoint]:6379
CACHE_TTL=300 # 5 minutes in seconds
DISABLE_CACHE=false

# Server port configuration
PORT=3000
```

## Detailed Deployment Process

### 1. Database Setup (RDS)

```bash
# Create a PostgreSQL database instance
aws rds create-db-instance \
    --db-instance-identifier ptchampion-1-instance-1 \
    --db-instance-class db.t3.micro \
    --engine postgres \
    --allocated-storage 20 \
    --master-username postgres \
    --master-user-password [your-secure-password] \
    --vpc-security-group-ids [security-group-id] \
    --publicly-accessible \
    --port 5432
```

Create a security group that allows inbound connections on port 5432 from your EC2 instances.

### 2. Create EC2 Security Group

```bash
# Create security group
aws ec2 create-security-group \
    --group-name ptchampion-sg \
    --description "Security group for PT Champion application"

# Allow SSH (port 22), HTTP (port 80), HTTPS (port 443), and API (port 3000)
aws ec2 authorize-security-group-ingress \
    --group-name ptchampion-sg \
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0

aws ec2 authorize-security-group-ingress \
    --group-name ptchampion-sg \
    --protocol tcp \
    --port 80 \
    --cidr 0.0.0.0/0

aws ec2 authorize-security-group-ingress \
    --group-name ptchampion-sg \
    --protocol tcp \
    --port 443 \
    --cidr 0.0.0.0/0

aws ec2 authorize-security-group-ingress \
    --group-name ptchampion-sg \
    --protocol tcp \
    --port 3000 \
    --cidr 0.0.0.0/0
```

### 3. Launch EC2 Instance for Backend

```bash
# Create a key pair for SSH access
aws ec2 create-key-pair \
    --key-name ptchampion-key \
    --query "KeyMaterial" \
    --output text > ptchampion-key.pem

# Set proper permissions
chmod 400 ptchampion-key.pem

# Launch EC2 instance
aws ec2 run-instances \
    --image-id ami-0e731c8a588258d0d \
    --instance-type t2.micro \
    --key-name ptchampion-key \
    --security-group-ids [security-group-id] \
    --user-data file://ec2-user-data.sh \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=ptchampion-server}]"
```

### 4. Create S3 Bucket for Frontend

```bash
# Create S3 bucket
aws s3api create-bucket \
    --bucket ptchampion.ai \
    --region us-east-1

# Configure bucket for website hosting
aws s3 website s3://ptchampion.ai/ \
    --index-document index.html \
    --error-document index.html

# Set bucket policy for public access
aws s3api put-bucket-policy \
    --bucket ptchampion.ai \
    --policy file://bucket-policy.json
```

### 5. Build and Deploy Frontend

```bash
# Build frontend
npm install
npm run build

# Deploy to S3
aws s3 sync dist/public/ s3://ptchampion.ai/ --delete
```

### 6. Set Up CloudFront Distribution

Create a CloudFront distribution with two origins:
1. S3 bucket for static assets
2. EC2 instance for API endpoints

```bash
# Create CloudFront distribution
aws cloudfront create-distribution \
    --distribution-config file://cloudfront-config.json
```

### 7. EC2 Configuration Script

Example `ec2-user-data.sh` script:

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
git clone https://github.com/yourusername/ptchampion.git
cd ptchampion

# Install dependencies and build
npm install
npm run build

# Create .env.production file with your configuration
# Start the server with PM2
NODE_ENV=production pm2 start dist/index.js --name ptchampion-api
pm2 startup
pm2 save

# Configure Nginx as a reverse proxy
# Enable and start Nginx
systemctl enable nginx
systemctl start nginx
```

## Database Security Configuration

Configure the RDS Security Group to allow EC2 access:

```bash
# Get EC2 instance security group ID
EC2_SG_ID=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=ptchampion-server" \
    --query "Reservations[0].Instances[0].SecurityGroups[0].GroupId" \
    --output text)

# Get RDS security group ID
RDS_SG_ID=$(aws rds describe-db-instances \
    --db-instance-identifier ptchampion-1-instance-1 \
    --query "DBInstances[0].VpcSecurityGroups[0].VpcSecurityGroupId" \
    --output text)

# Allow EC2 security group to access RDS on port 5432
aws ec2 authorize-security-group-ingress \
    --group-id $RDS_SG_ID \
    --protocol tcp \
    --port 5432 \
    --source-group $EC2_SG_ID
```

## CloudFront Configuration for API Routing

### Critical Configuration Points

1. **Ensure the correct EC2 domain:** Always use the current EC2 public DNS or IP
2. **Configure proper cache behaviors:**
   - Use `CachePolicyId: "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"` (CachingDisabled policy)
   - Use `OriginRequestPolicyId: "216adef6-5c7f-47e4-b989-5492eafa07d3"` (AllViewer policy)
3. **Include all HTTP methods for API routes**
4. **Create invalidations after updates**

## Security Best Practices

1. Always use a strong random JWT secret in production
2. Regularly update your EC2 instance with security patches
3. Use HTTPS everywhere (including for API requests)
4. Apply the principle of least privilege for IAM roles and security groups
5. Regularly back up your RDS database

## Monitoring and Maintenance

1. Set up CloudWatch Alarms for monitoring EC2 and RDS instances
2. Configure S3 logging for frontend access analysis
3. Implement CloudTrail for AWS API activity monitoring
4. Create a regular backup strategy for your database

## Mobile App Deployment

The PT Champion ecosystem includes native mobile applications for iOS (Swift) and Android (Kotlin) that integrate with the same backend API.

### Preparing the Mobile Apps for Production

Before deploying the mobile apps, you need to configure them to point to your production API endpoint.

#### 1. Update API Endpoint Configuration

**For iOS (Swift):**
1. Open the Xcode project in the `PTChampion-Swift` directory
2. Navigate to the `APIClient.swift` file
3. Update the base URL to point to your CloudFront distribution or EC2 instance:

```swift
// In APIClient.swift
private let baseURL = "https://api.ptchampion.ai" // Update this URL
```

**For Android (Kotlin):**
1. Open the Android Studio project in the `PTChampion-Kotlin` directory
2. Navigate to the `build.gradle` file
3. Update the production API endpoint:

```kotlin
// In build.gradle (Module level)
buildTypes {
    release {
        buildConfigField "String", "API_BASE_URL", "\"https://api.ptchampion.ai\""
        // Other release configurations...
    }
}
```

#### 2. Configure Firebase (Optional but Recommended)

Both mobile apps can benefit from Firebase services:
- Firebase Cloud Messaging for push notifications
- Firebase Analytics for usage tracking
- Firebase Crashlytics for error reporting

Follow the Firebase setup guides for [iOS](https://firebase.google.com/docs/ios/setup) and [Android](https://firebase.google.com/docs/android/setup).

### iOS App Deployment

#### 1. Prepare App for App Store

1. Create an App Store Connect account and register your app
2. Generate all required app icons and splash screens
3. Configure app signing certificates and provisioning profiles

#### 2. Build and Archive the iOS App

1. Open the Xcode project
2. Select the "Generic iOS Device" or a specific device as the build target
3. Select Product > Archive from the menu
4. Once the archive is created, click "Distribute App"
5. Choose "App Store Connect" as the distribution method
6. Follow the prompts to upload your app to App Store Connect

#### 3. Submit for App Store Review

1. Complete all required metadata in App Store Connect:
   - App description
   - Screenshots
   - Privacy policy URL
   - Support URL
   - App Store icon
2. Complete the App Privacy section
3. Set up in-app purchases (if applicable)
4. Submit for review

### Android App Deployment

#### 1. Prepare App for Google Play

1. Create a Google Play Developer account
2. Create a new application in the Google Play Console
3. Generate all required app icons and splash screens
4. Configure app signing

#### 2. Build a Release APK or Bundle

1. Open the Android Studio project
2. Select Build > Generate Signed Bundle/APK
3. Choose Android App Bundle (recommended) or APK
4. Create or select a keystore for signing
5. Select release build variant
6. Click "Finish" to generate the bundle/APK

#### 3. Submit to Google Play

1. Go to Google Play Console
2. Select your app and navigate to "Production" track
3. Upload your app bundle or APK
4. Complete all required metadata:
   - App title and description
   - Graphics assets (feature graphic, screenshots)
   - Categorization
   - Content rating
5. Complete the App Content section
6. Set up in-app purchases (if applicable)
7. Submit for review

### Testing Mobile Apps with Production Backend

Before submitting to app stores, thoroughly test the mobile apps against your production backend:

1. Use TestFlight for iOS beta testing
2. Use Internal Test Track on Google Play for Android beta testing
3. Verify all API endpoints work correctly with production data
4. Test offline synchronization capabilities
5. Test location-based features with real-world coordinates
6. Test authentication flow including token refresh

## Continuous Integration/Continuous Deployment (CI/CD)

To streamline your deployment process, consider setting up CI/CD pipelines:

### Web Application CI/CD with GitHub Actions

```yaml
# .github/workflows/deploy.yml
name: Deploy Web App

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Setup Node.js
        uses: actions/setup-node@v2
        with:
          node-version: '16'
          
      - name: Install dependencies
        run: npm ci
        
      - name: Build project
        run: npm run build
        
      - name: Deploy to S3
        uses: jakejarvis/s3-sync-action@master
        with:
          args: --delete
        env:
          AWS_S3_BUCKET: ${{ secrets.AWS_S3_BUCKET }}
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          SOURCE_DIR: 'dist/public'
          
      - name: Invalidate CloudFront
        uses: chetan/invalidate-cloudfront-action@master
        env:
          DISTRIBUTION: ${{ secrets.CLOUDFRONT_DISTRIBUTION_ID }}
          PATHS: '/*'
          AWS_REGION: 'us-east-1'
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
```

### Mobile App CI/CD

For mobile apps, consider using:
- Fastlane for iOS automation
- GitHub Actions for Android build and deployment

## Troubleshooting Common Issues

### API Connection Issues

If mobile apps cannot connect to the backend:
1. Verify network security groups allow traffic from external IPs
2. Check CORS settings on your API
3. Verify SSL certificates are valid and trusted
4. Test API endpoints with Postman or curl

### Authentication Issues

If users cannot authenticate:
1. Verify JWT secret is correctly set on the server
2. Check token expiration settings
3. Verify the mobile app is sending the correct authentication headers
4. Check if HTTPS is properly configured (required for secure cookie transmission)

### Database Connectivity Issues

If the application cannot connect to the database:
1. Verify RDS security group allows connections from your EC2 instances
2. Check database credentials in environment variables
3. Verify the database exists and has the correct schema
4. Check maximum connection limits on RDS instance

## Mobile-Web Integration and Synchronization

A key feature of the PT Champion ecosystem is seamless data synchronization between mobile apps and the web application. Here's how to ensure proper integration:

### 1. Synchronization Infrastructure

The `/api/sync` endpoint on your backend handles data synchronization between devices:
- Each device maintains a record of its last sync time
- During sync, devices send local changes to the server
- The server resolves conflicts and sends back updated data
- The device updates its local state with server data

### 2. Conflict Resolution Strategy

When conflicts occur (same data modified on multiple devices):
1. Server-side timestamps determine the "winner" (most recent wins)
2. Conflicting records are returned to the client for review
3. Mobile clients can choose to override server data if needed

### 3. Testing Synchronization

To ensure synchronization works properly:
1. Create test accounts with data on multiple devices
2. Perform actions offline on mobile devices
3. Reconnect to the internet and trigger synchronization
4. Verify data appears correctly across all devices
5. Test edge cases like conflicting edits to the same exercise record

### 4. Offline Support Implementation

Both the Swift and Kotlin apps implement offline support through:
1. Local storage for user data (Core Data for iOS, Room for Android)
2. Pending changes queue for operations made while offline
3. Background synchronization when connectivity is restored
4. Conflict resolution UI for user intervention when needed

### 5. User Identity Management

Ensure consistent user identity across platforms:
1. Use the same authentication backend for web and mobile apps
2. JWT tokens should be valid across all platforms
3. User profile updates should propagate to all devices
4. Password changes should invalidate tokens on all devices

## Final Deployment Checklist

Before launching your PT Champion ecosystem:

- [ ] Backend API is deployed and accessible
- [ ] Database is properly configured with initial data
- [ ] Web application is deployed and tested
- [ ] Mobile apps are configured to use production API
- [ ] Cross-platform synchronization is tested thoroughly
- [ ] Monitoring is set up for all components
- [ ] Backup strategy is implemented and tested
- [ ] SSL certificates are installed and valid
- [ ] User data is properly secured
- [ ] Performance testing completed under expected load
- [ ] Automated deployment pipeline is operational