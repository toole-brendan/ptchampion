#!/bin/bash
set -e

# Colors for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Print script banner
echo -e "${GREEN}PT Champion Unified Deployment Script${NC}"
echo "=============================================================="

# Ensure AWS CLI is installed
if ! command -v aws &> /dev/null; then
  echo -e "${RED}AWS CLI is not installed. Please install it first:${NC}"
  echo "https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
  exit 1
fi

# Ensure AWS CLI is configured
if ! aws sts get-caller-identity &> /dev/null; then
  echo -e "${RED}AWS CLI is not configured. Please run 'aws configure' first.${NC}"
  exit 1
fi

# Configuration
S3_BUCKET="ptchampion.ai"
CLOUDFRONT_DISTRIBUTION_ID="E1FRFF3JQNGRE1"
LOCAL_FRONTEND_PATH="./dist/public"

# Load EC2 IP from .env.production
if [ -f ".env.production" ]; then
    API_EC2_IP=$(grep -o 'EC2_IP=.*' .env.production | cut -d '=' -f2)
    API_EC2_HOSTNAME=$(grep -o 'EC2_HOSTNAME=.*' .env.production | cut -d '=' -f2)
    if [ -n "$API_EC2_IP" ]; then
        echo -e "${GREEN}Found API EC2 IP address in .env.production: $API_EC2_IP${NC}"
        if [ -n "$API_EC2_HOSTNAME" ]; then
            echo -e "${GREEN}Found API EC2 hostname in .env.production: $API_EC2_HOSTNAME${NC}"
        else
            echo -e "${YELLOW}EC2 hostname not found in .env.production. Using IP for SSH connection but this may cause issues with CloudFront.${NC}"
            read -p "Enter API EC2 hostname (e.g., ec2-xx-xx-xx-xx.compute-1.amazonaws.com): " API_EC2_HOSTNAME
        fi
    else
        read -p "Enter API EC2 instance IP address: " API_EC2_IP
        read -p "Enter API EC2 hostname (e.g., ec2-xx-xx-xx-xx.compute-1.amazonaws.com): " API_EC2_HOSTNAME
    fi
else
    read -p "Enter API EC2 instance IP address: " API_EC2_IP
    read -p "Enter API EC2 hostname (e.g., ec2-xx-xx-xx-xx.compute-1.amazonaws.com): " API_EC2_HOSTNAME
fi

# Check if key file exists
KEY_FILE="ptchampion-key.pem"
if [ -f "$KEY_FILE" ]; then
    echo -e "${GREEN}Found SSH key file: $KEY_FILE${NC}"
    chmod 400 $KEY_FILE
    USE_SSH=true
else
    echo -e "${YELLOW}SSH key file not found. Some operations may require manual steps.${NC}"
    USE_SSH=false
fi

# Function to display help
show_help() {
  echo "Usage: ./deploy-s3.sh [OPTIONS]"
  echo ""
  echo "OPTIONS:"
  echo "  --deploy             Deploy frontend to S3 and configure backend"
  echo "  --frontend-only      Only deploy frontend to S3 bucket"
  echo "  --backend-only       Only configure backend on EC2"
  echo "  --invalidate-only    Only create a CloudFront invalidation"
  echo "  --test-api           Test API connection"
  echo "  --help               Show this help message"
  echo ""
  echo "Examples:"
  echo "  ./deploy-s3.sh --deploy          # Deploy everything"
  echo "  ./deploy-s3.sh --frontend-only   # Only deploy frontend to S3"
  echo "  ./deploy-s3.sh --backend-only    # Only configure backend"
  echo "  ./deploy-s3.sh --invalidate-only # Just create a CloudFront invalidation"
  echo "  ./deploy-s3.sh --test-api        # Test API connection"
  echo ""
}

# Function to create CloudFront invalidation
create_cloudfront_invalidation() {
  echo -e "${YELLOW}Creating CloudFront invalidation for distribution: $CLOUDFRONT_DISTRIBUTION_ID${NC}"
  
  # Create invalidation
  INVALIDATION_ID=$(aws cloudfront create-invalidation \
    --distribution-id $CLOUDFRONT_DISTRIBUTION_ID \
    --paths "/*" "/api/*" \
    --query 'Invalidation.Id' \
    --output text)
  
  if [ -n "$INVALIDATION_ID" ]; then
    echo -e "${GREEN}Successfully created CloudFront invalidation. ID: $INVALIDATION_ID${NC}"
    echo -e "${YELLOW}Invalidation may take up to 5-10 minutes to complete.${NC}"
    echo -e "${YELLOW}Once completed, your site should be accessible at: https://ptchampion.ai${NC}"
  else
    echo -e "${RED}Failed to create CloudFront invalidation.${NC}"
    exit 1
  fi
}

# Function to sync files to S3
deploy_frontend_to_s3() {
  echo -e "${YELLOW}Checking if frontend is built...${NC}"
  
  # Check if the frontend build directory exists
  if [ ! -d "$LOCAL_FRONTEND_PATH" ]; then
    echo -e "${RED}Frontend build directory not found at $LOCAL_FRONTEND_PATH${NC}"
    echo -e "${YELLOW}Building the frontend first...${NC}"
    
    # Build the frontend
    npm run build
    
    # Check if build was successful
    if [ ! -d "$LOCAL_FRONTEND_PATH" ]; then
      echo -e "${RED}Failed to build frontend. Please check for errors.${NC}"
      exit 1
    fi
  fi
  
  echo -e "${YELLOW}Syncing frontend files to S3 bucket: $S3_BUCKET${NC}"
  
  # Sync files to S3
  aws s3 sync $LOCAL_FRONTEND_PATH s3://$S3_BUCKET --delete
  
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}Successfully synced frontend files to S3 bucket: $S3_BUCKET${NC}"
    create_cloudfront_invalidation
  else
    echo -e "${RED}Failed to sync frontend files to S3 bucket: $S3_BUCKET${NC}"
    exit 1
  fi
}

# Function to copy the current .env.production to the EC2 instance
copy_env_to_ec2() {
  if [ "$USE_SSH" = true ]; then
    echo -e "${YELLOW}Copying .env.production to EC2 instance...${NC}"
    scp -i $KEY_FILE -o StrictHostKeyChecking=no .env.production ec2-user@$API_EC2_IP:~/ptchampion/.env.production
    
    if [ $? -eq 0 ]; then
      echo -e "${GREEN}Successfully copied .env.production to EC2 instance.${NC}"
    else
      echo -e "${RED}Failed to copy .env.production to EC2 instance.${NC}"
    fi
  else
    echo -e "${YELLOW}SSH key not available. Please copy .env.production manually to the EC2 instance.${NC}"
  fi
}

# Function to configure the backend on EC2
configure_backend() {
  echo -e "${YELLOW}Configuring backend on EC2 instance...${NC}"
  
  if [ "$USE_SSH" = true ]; then
    # Copy the environment file first
    copy_env_to_ec2
    
    # SSH into EC2 to update Nginx config
    echo -e "${YELLOW}Updating Nginx configuration...${NC}"
    ssh -i $KEY_FILE -o StrictHostKeyChecking=no ec2-user@$API_EC2_IP << 'EOF'
      # Update Nginx configuration
      sudo bash -c 'cat > /etc/nginx/conf.d/ptchampion.conf << CONFEOF
server {
    listen 80;
    server_name _;

    # Handle API requests
    location /api/ {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        proxy_read_timeout 300;
        proxy_connect_timeout 300;
    }
}
CONFEOF'
      
      # Restart Nginx
      sudo systemctl restart nginx
      
      # Check if backend is running with PM2
      if command -v pm2 &> /dev/null; then
          echo "Restarting backend with PM2..."
          cd ~/ptchampion
          
          # Stop any existing process
          pm2 stop ptchampion-api || true
          
          # Check and apply latest .env.production
          if [ -f ".env.production" ]; then
              echo "Using .env.production file..."
          fi
          
          # Start backend with PM2
          NODE_ENV=production pm2 start dist/index.js --name ptchampion-api
          pm2 list
      elif command -v docker-compose &> /dev/null && [ -f "~/ptchampion/docker-compose.yml" ]; then
          # If Docker Compose is installed, try restarting with it
          echo "Restarting with Docker Compose..."
          cd ~/ptchampion
          docker-compose restart backend
          docker-compose ps
      else
          echo "Could not find PM2 or Docker Compose. Starting with Node directly..."
          cd ~/ptchampion
          pkill -f "node dist/index.js" || true
          NODE_ENV=production nohup node dist/index.js > app.log 2>&1 &
          echo "Backend started with PID: $!"
      fi
      
      # Check if the backend is now responding
      sleep 5  # Wait a bit for the service to start
      echo "Checking if backend is responding..."
      curl -s http://localhost:3000/api/health || echo "Backend health check failed, but it might still be starting up."
EOF
    
    echo -e "${GREEN}Backend configuration completed.${NC}"
  else
    echo -e "${YELLOW}SSH key not available. Please follow these steps to configure the backend manually:${NC}"
    echo "1. SSH into your EC2 instance:"
    echo "   ssh -i YOUR_KEY.pem ec2-user@$API_EC2_IP"
    echo ""
    echo "2. Update the Nginx configuration:"
    echo "   sudo nano /etc/nginx/conf.d/ptchampion.conf"
    echo ""
    echo "3. Add the following configuration:"
    echo "   server {"
    echo "       listen 80;"
    echo "       server_name _;"
    echo ""
    echo "       # Handle API requests"
    echo "       location /api/ {"
    echo "           proxy_pass http://localhost:3000;"
    echo "           proxy_http_version 1.1;"
    echo "           proxy_set_header Upgrade \$http_upgrade;"
    echo "           proxy_set_header Connection \"upgrade\";"
    echo "           proxy_set_header Host \$host;"
    echo "           proxy_set_header X-Real-IP \$remote_addr;"
    echo "           proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;"
    echo "           proxy_set_header X-Forwarded-Proto \$scheme;"
    echo "           proxy_cache_bypass \$http_upgrade;"
    echo "       }"
    echo "   }"
    echo ""
    echo "4. Restart Nginx:"
    echo "   sudo systemctl restart nginx"
    echo ""
    echo "5. Copy the .env.production file:"
    echo "   scp -i YOUR_KEY.pem .env.production ec2-user@$API_EC2_IP:~/ptchampion/"
    echo ""
    echo "6. Restart the backend service:"
    echo "   cd ~/ptchampion"
    echo "   NODE_ENV=production pm2 restart ptchampion-api || NODE_ENV=production pm2 start dist/index.js --name ptchampion-api"
  fi
}

# Function to update CloudFront configuration
update_cloudfront_config() {
  echo -e "${YELLOW}Updating CloudFront configuration...${NC}"
  
  # Get the current configuration
  echo -e "${YELLOW}Getting configuration for distribution $CLOUDFRONT_DISTRIBUTION_ID...${NC}"
  CONFIG=$(aws cloudfront get-distribution-config --id $CLOUDFRONT_DISTRIBUTION_ID)
  
  if [ -z "$CONFIG" ]; then
    echo -e "${RED}Failed to get configuration for distribution $CLOUDFRONT_DISTRIBUTION_ID.${NC}"
    exit 1
  fi
  
  # Extract ETag and Config
  ETAG=$(echo "$CONFIG" | jq -r '.ETag')
  DISTRIBUTION_CONFIG=$(echo "$CONFIG" | jq -r '.DistributionConfig')
  
  # Create a temporary file for the fixed configuration
  CONFIG_FILE=$(mktemp)
  
  # Check if distribution has behaviors for API
  API_BEHAVIOR_EXISTS=$(echo "$DISTRIBUTION_CONFIG" | jq -e '.CacheBehaviors.Items[] | select(.PathPattern == "/api*")' 2>/dev/null)
  API_BEHAVIOR_EXISTS_STATUS=$?
  
  if [ $API_BEHAVIOR_EXISTS_STATUS -ne 0 ]; then
    # API behavior doesn't exist, we need to add it
    echo -e "${YELLOW}Creating a new cache behavior for /api* paths...${NC}"
    
    # Find the custom origin ID for the EC2 instance (using hostname)
    EC2_ORIGIN_ID=$(echo "$DISTRIBUTION_CONFIG" | jq -r '.Origins.Items[] | select(.DomainName | contains("'$API_EC2_HOSTNAME'")) | .Id')
    
    if [ -z "$EC2_ORIGIN_ID" ]; then
      echo -e "${YELLOW}EC2 origin not found. Creating a new origin for the EC2 instance...${NC}"
      
      # Create a unique ID for the new origin
      EC2_ORIGIN_ID="EC2-API-Origin"
      
      # Add a new origin for EC2 using hostname
      UPDATED_CONFIG=$(echo "$DISTRIBUTION_CONFIG" | jq ".Origins.Quantity = (.Origins.Quantity + 1) | 
        .Origins.Items += [{
          \"Id\": \"$EC2_ORIGIN_ID\",
          \"DomainName\": \"$API_EC2_HOSTNAME\",
          \"OriginPath\": \"\",
          \"CustomHeaders\": {
            \"Quantity\": 0,
            \"Items\": []
          },
          \"CustomOriginConfig\": {
            \"HTTPPort\": 80,
            \"HTTPSPort\": 443,
            \"OriginProtocolPolicy\": \"http-only\",
            \"OriginSslProtocols\": {
              \"Quantity\": 1,
              \"Items\": [\"TLSv1.2\"]
            },
            \"OriginReadTimeout\": 300,
            \"OriginKeepaliveTimeout\": 60
          }
        }]")
    else
      # Update the existing origin with the new API EC2 hostname
      UPDATED_CONFIG=$(echo "$DISTRIBUTION_CONFIG" | jq --arg DOMAIN "$API_EC2_HOSTNAME" '.Origins.Items[] |= if .Id == "'"$EC2_ORIGIN_ID"'" then .DomainName = $DOMAIN else . end')
    fi
    
    # Add the new cache behavior for API
    UPDATED_CONFIG=$(echo "$UPDATED_CONFIG" | jq ".CacheBehaviors.Quantity = (.CacheBehaviors.Quantity + 1) | 
      .CacheBehaviors.Items += [{
        \"PathPattern\": \"/api*\",
        \"TargetOriginId\": \"$EC2_ORIGIN_ID\",
        \"ViewerProtocolPolicy\": \"redirect-to-https\",
        \"AllowedMethods\": {
          \"Quantity\": 7,
          \"Items\": [\"GET\", \"HEAD\", \"OPTIONS\", \"PUT\", \"POST\", \"PATCH\", \"DELETE\"],
          \"CachedMethods\": {
            \"Quantity\": 3,
            \"Items\": [\"GET\", \"HEAD\", \"OPTIONS\"]
          }
        },
        \"SmoothStreaming\": false,
        \"Compress\": true,
        \"LambdaFunctionAssociations\": {
          \"Quantity\": 0,
          \"Items\": []
        },
        \"FunctionAssociations\": {
          \"Quantity\": 0,
          \"Items\": []
        },
        \"FieldLevelEncryptionId\": \"\",
        \"CachePolicyId\": \"658327ea-f89d-4fab-a63d-7e88639e58f6\", 
        \"OriginRequestPolicyId\": \"216adef6-5c7f-47e4-b989-5492eafa07d3\"
      }]")
  else
    # API behavior exists, just update the target origin if needed
    echo -e "${YELLOW}API cache behavior already exists. Checking if target origin needs updating...${NC}"
    
    # Get the current API behavior's target origin ID
    CURRENT_ORIGIN_ID=$(echo "$DISTRIBUTION_CONFIG" | jq -r '.CacheBehaviors.Items[] | select(.PathPattern == "/api*") | .TargetOriginId')
    
    # Find the domain name for the current origin
    CURRENT_ORIGIN_DOMAIN=$(echo "$DISTRIBUTION_CONFIG" | jq -r '.Origins.Items[] | select(.Id == "'"$CURRENT_ORIGIN_ID"'") | .DomainName')
    
    if [ "$CURRENT_ORIGIN_DOMAIN" != "$API_EC2_HOSTNAME" ]; then
      echo -e "${YELLOW}Updating origin domain from $CURRENT_ORIGIN_DOMAIN to $API_EC2_HOSTNAME...${NC}"
      
      # Update the origin domain
      UPDATED_CONFIG=$(echo "$DISTRIBUTION_CONFIG" | jq --arg DOMAIN "$API_EC2_HOSTNAME" '.Origins.Items[] |= if .Id == "'"$CURRENT_ORIGIN_ID"'" then .DomainName = $DOMAIN else . end')
    else
      echo -e "${GREEN}Origin already pointing to correct API instance.${NC}"
      UPDATED_CONFIG="$DISTRIBUTION_CONFIG"
    fi
  fi
  
  # Write the updated configuration to a temporary file
  echo "$UPDATED_CONFIG" > $CONFIG_FILE
  
  # Update the CloudFront distribution
  echo -e "${YELLOW}Updating CloudFront distribution...${NC}"
  UPDATE_RESULT=$(aws cloudfront update-distribution --id $CLOUDFRONT_DISTRIBUTION_ID --distribution-config file://$CONFIG_FILE --if-match $ETAG)
  
  if [ -z "$UPDATE_RESULT" ]; then
    echo -e "${RED}Failed to update CloudFront distribution.${NC}"
    exit 1
  fi
  
  echo -e "${GREEN}CloudFront distribution updated successfully!${NC}"
  
  # Create an invalidation to apply changes quickly
  create_cloudfront_invalidation
  
  # Cleanup
  rm $CONFIG_FILE
}

# Function to test API connection
test_api_connection() {
  echo -e "${YELLOW}Testing API connection...${NC}"
  
  # Test direct connection to API instance
  echo -e "${YELLOW}Testing direct connection to API instance (http://$API_EC2_IP/api/health)...${NC}"
  DIRECT_RESPONSE=$(curl -s -m 10 http://$API_EC2_IP/api/health || echo "Failed to connect")
  
  if [[ "$DIRECT_RESPONSE" == *"status"*"ok"* ]]; then
    echo -e "${GREEN}Successfully connected to API instance directly.${NC}"
  else
    echo -e "${RED}Failed to connect to API instance directly. Response: $DIRECT_RESPONSE${NC}"
  fi
  
  # Test through CloudFront
  echo -e "${YELLOW}Testing connection through CloudFront (https://ptchampion.ai/api/health)...${NC}"
  CF_RESPONSE=$(curl -s -m 10 https://ptchampion.ai/api/health || echo "Failed to connect")
  
  if [[ "$CF_RESPONSE" == *"status"*"ok"* ]]; then
    echo -e "${GREEN}Successfully connected to API through CloudFront.${NC}"
  else
    echo -e "${RED}Failed to connect to API through CloudFront. Response: $CF_RESPONSE${NC}"
    echo -e "${YELLOW}This may indicate a CloudFront configuration issue.${NC}"
  fi
}

# Function to deploy code to EC2
deploy_code_to_ec2() {
  echo -e "${YELLOW}Deploying code to EC2 API instance...${NC}"
  
  if [ "$USE_SSH" = true ]; then
    # Ensure the dist directory exists
    ssh -i $KEY_FILE -o StrictHostKeyChecking=no ec2-user@$API_EC2_IP "mkdir -p ~/ptchampion/dist"
    
    # Copy the backend code
    echo -e "${YELLOW}Copying backend code to EC2...${NC}"
    scp -i $KEY_FILE -o StrictHostKeyChecking=no dist/index.js ec2-user@$API_EC2_IP:~/ptchampion/dist/
    
    # Copy the frontend code (for serving directly from EC2 if needed)
    echo -e "${YELLOW}Copying frontend files to EC2...${NC}"
    scp -i $KEY_FILE -o StrictHostKeyChecking=no -r dist/public ec2-user@$API_EC2_IP:~/ptchampion/dist/
    
    echo -e "${GREEN}Code deployment completed.${NC}"
  else
    echo -e "${YELLOW}SSH key not available. Please deploy code manually:${NC}"
    echo "1. Copy backend code:"
    echo "   scp -i YOUR_KEY.pem dist/index.js ec2-user@$API_EC2_IP:~/ptchampion/dist/"
    echo ""
    echo "2. Copy frontend files:"
    echo "   scp -i YOUR_KEY.pem -r dist/public ec2-user@$API_EC2_IP:~/ptchampion/dist/"
  fi
}

# Parse command line arguments
if [ $# -eq 0 ]; then
  show_help
  exit 0
fi

while [ $# -gt 0 ]; do
  case "$1" in
    --deploy)
      DEPLOY_ALL=true
      ;;
    --frontend-only)
      FRONTEND_ONLY=true
      ;;
    --backend-only)
      BACKEND_ONLY=true
      ;;
    --invalidate-only)
      INVALIDATE_ONLY=true
      ;;
    --test-api)
      TEST_API=true
      ;;
    --help)
      show_help
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      show_help
      exit 1
      ;;
  esac
  shift
done

# Execute requested operations
if [ "$DEPLOY_ALL" = true ]; then
  deploy_frontend_to_s3
  deploy_code_to_ec2
  configure_backend
  update_cloudfront_config
  test_api_connection
elif [ "$FRONTEND_ONLY" = true ]; then
  deploy_frontend_to_s3
elif [ "$BACKEND_ONLY" = true ]; then
  deploy_code_to_ec2
  configure_backend
  test_api_connection
elif [ "$INVALIDATE_ONLY" = true ]; then
  create_cloudfront_invalidation
elif [ "$TEST_API" = true ]; then
  test_api_connection
else
  show_help
fi

echo -e "${GREEN}Deployment script completed!${NC}"
echo "=============================================================="
echo "To access your application:"
echo " - Frontend: https://ptchampion.ai"
echo " - API: https://ptchampion.ai/api"
echo " - EC2 direct (API): http://$API_EC2_IP/api"
echo "=============================================================="
