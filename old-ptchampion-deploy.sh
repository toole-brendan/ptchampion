#!/bin/bash
set -e

# Colors for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Print script banner
echo -e "${GREEN}PT Champion Deployment & Maintenance Script${NC}"
echo "=============================================================="

# Function to display help
show_help() {
  echo "Usage: ./ptchampion-deploy.sh [OPTIONS]"
  echo ""
  echo "OPTIONS:"
  echo "  --deploy              Full application deployment to EC2"
  echo "  --fix-backend         Fix Nginx configuration for backend API routing"
  echo "  --fix-cloudfront      Fix CloudFront distribution for proper API handling"
  echo "  --port-fix            Fix backend port mismatch (5000 -> 3000)"
  echo "  --help                Show this help message"
  echo ""
  echo "Examples:"
  echo "  ./ptchampion-deploy.sh --deploy         # Deploy the full application"
  echo "  ./ptchampion-deploy.sh --fix-backend    # Fix only the backend configuration"
  echo "  ./ptchampion-deploy.sh --port-fix       # Fix the port mismatch issue"
  echo ""
}

# Show help if no arguments
if [ $# -eq 0 ]; then
  show_help
  exit 0
fi

# Parse command line arguments
while [ $# -gt 0 ]; do
  case "$1" in
    --deploy)
      DEPLOY_FULL=true
      ;;
    --fix-backend)
      FIX_BACKEND=true
      ;;
    --fix-cloudfront)
      FIX_CLOUDFRONT=true
      ;;
    --port-fix)
      FIX_PORT=true
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

# Get EC2 instance IP from .env.production
if [ -f ".env.production" ]; then
    EC2_IP=$(grep -o 'EC2_IP=.*' .env.production | cut -d '=' -f2)
    if [ -n "$EC2_IP" ]; then
        echo -e "${GREEN}Found EC2 IP address in .env.production: $EC2_IP${NC}"
    else
        read -p "Enter EC2 instance IP address: " EC2_IP
    fi
else
    read -p "Enter EC2 instance IP address: " EC2_IP
fi

# Function to build the application
build_application() {
    echo -e "${YELLOW}Building application...${NC}"
    npm run build
    echo -e "${GREEN}Build completed successfully!${NC}"
}

# Function to fix backend port mismatch
fix_port_mismatch() {
    echo -e "${YELLOW}Applying port mismatch fix...${NC}"
    
    if [ "$USE_SSH" = true ]; then
        # Create a temporary directory for the backend files
        TEMP_DIR=$(mktemp -d)
        cp -r dist/index.js $TEMP_DIR/
        
        # Copy files to EC2
        echo -e "${YELLOW}Copying updated backend file to EC2...${NC}"
        scp -i $KEY_FILE -o StrictHostKeyChecking=no $TEMP_DIR/index.js ec2-user@$EC2_IP:~/ptchampion/dist/ || {
            echo -e "${RED}Failed to copy files to EC2 instance!${NC}"
            return 1
        }
        
        # Clean up temporary directory
        rm -rf $TEMP_DIR
        
        # Restart backend service
        echo -e "${YELLOW}Restarting backend service...${NC}"
        ssh -i $KEY_FILE -o StrictHostKeyChecking=no ec2-user@$EC2_IP << 'EOF'
            cd ~/ptchampion
            
            # Check if the backend is running with PM2
            if command -v pm2 &> /dev/null; then
                echo "Restarting backend with PM2..."
                pm2 restart ptchampion-api || pm2 start dist/index.js --name ptchampion-api
                pm2 list
            elif [ -d "node_modules" ]; then
                # If PM2 not available but node_modules exists, try running with node
                echo "PM2 not found. Starting with Node directly..."
                pkill -f "node dist/index.js" || true
                nohup node dist/index.js > app.log 2>&1 &
                echo "Backend started with PID: $!"
            elif command -v docker-compose &> /dev/null; then
                # If Docker Compose is installed, try restarting with it
                echo "Restarting with Docker Compose..."
                docker-compose restart backend
                docker-compose ps
            else
                echo "Could not find PM2, Node, or Docker Compose. Please restart the backend manually."
            fi
            
            # Check if the backend is now responding
            echo "Checking if backend is responding..."
            curl -s http://localhost:3000/api/health || echo "Backend health check failed, but it might still be starting up."
EOF
        
        echo -e "${GREEN}Port fix applied successfully!${NC}"
    else
        echo -e "${YELLOW}SSH key not available. Please follow these steps to apply the fix manually:${NC}"
        echo "1. Copy the built backend file to your EC2 instance:"
        echo "   scp -i YOUR_KEY.pem dist/index.js ec2-user@$EC2_IP:~/ptchampion/dist/"
        echo ""
        echo "2. SSH into your EC2 instance:"
        echo "   ssh -i YOUR_KEY.pem ec2-user@$EC2_IP"
        echo ""
        echo "3. Restart the backend service:"
        echo "   cd ~/ptchampion"
        echo "   pm2 restart ptchampion-api || pm2 start dist/index.js --name ptchampion-api"
    fi
}

# Function to fix Nginx backend configuration
fix_backend() {
    echo -e "${YELLOW}Applying Nginx backend configuration fix...${NC}"
    
    if [ "$USE_SSH" = true ]; then
        # SSH into EC2 to update Nginx config
        echo -e "${YELLOW}Updating Nginx configuration...${NC}"
        ssh -i $KEY_FILE -o StrictHostKeyChecking=no ec2-user@$EC2_IP << 'EOF'
            # Update Nginx configuration
            sudo bash -c 'cat > /etc/nginx/conf.d/ptchampion.conf << CONFEOF
server {
    listen 80;
    server_name _;

    # Handle frontend requests
    location / {
        root /home/ec2-user/ptchampion/dist/public;
        try_files \$uri \$uri/ /index.html;
    }

    # Handle API requests
    location /api/ {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
CONFEOF'
            
            # Restart Nginx
            sudo systemctl restart nginx
            
            # Verify Nginx is running
            sudo systemctl status nginx
EOF
        echo -e "${GREEN}Nginx configuration updated successfully!${NC}"
    elif command -v aws &> /dev/null; then
        # Use AWS SSM if available
        echo -e "${YELLOW}Using AWS Systems Manager to update Nginx configuration...${NC}"
        
        # Check if instance exists
        INSTANCE_ID=$(aws ec2 describe-instances \
            --filters "Name=ip-address,Values=$EC2_IP" \
            --query "Reservations[].Instances[].InstanceId" \
            --output text)
            
        if [ -z "$INSTANCE_ID" ]; then
            echo -e "${RED}Could not find EC2 instance with IP: $EC2_IP${NC}"
            return 1
        fi
        
        # Create and run SSM document
        DOCUMENT_NAME="PTChampion-Fix-Backend"
        
        # Create a temporary file for the command document
        DOCUMENT_FILE=$(mktemp)
        
        cat > $DOCUMENT_FILE << EOF
{
  "schemaVersion": "2.2",
  "description": "Update Nginx configuration for PT Champion Backend",
  "parameters": {},
  "mainSteps": [
    {
      "action": "aws:runShellScript",
      "name": "updateNginxConfig",
      "inputs": {
        "runCommand": [
          "# Update Nginx configuration",
          "cat > /etc/nginx/conf.d/ptchampion.conf << 'EOFCONF'",
          "server {",
          "    listen 80;",
          "    server_name _;",
          "",
          "    # Handle frontend requests",
          "    location / {",
          "        root /home/ec2-user/ptchampion/dist/public;",
          "        try_files \\$uri \\$uri/ /index.html;",
          "    }",
          "",
          "    # Handle API requests",
          "    location /api/ {",
          "        proxy_pass http://localhost:3000;",
          "        proxy_http_version 1.1;",
          "        proxy_set_header Upgrade \\$http_upgrade;",
          "        proxy_set_header Connection 'upgrade';",
          "        proxy_set_header Host \\$host;",
          "        proxy_cache_bypass \\$http_upgrade;",
          "    }",
          "}",
          "EOFCONF",
          "",
          "# Restart Nginx",
          "systemctl restart nginx",
          "",
          "# Check if backend is running",
          "cd /home/ec2-user/ptchampion",
          "pm2 list",
          "",
          "# Restart backend",
          "pm2 restart ptchampion-api || pm2 start dist/index.js --name ptchampion-api",
          "",
          "echo 'Fix completed successfully'"
        ]
      }
    }
  ]
}
EOF
        
        # Delete document if it exists
        aws ssm delete-document --name $DOCUMENT_NAME --ignore-errors
        
        # Create the document
        aws ssm create-document --name $DOCUMENT_NAME --document-type "Command" --content file://$DOCUMENT_FILE
        
        # Run the command
        COMMAND_ID=$(aws ssm send-command \
            --document-name $DOCUMENT_NAME \
            --targets "Key=instanceids,Values=$INSTANCE_ID" \
            --output text \
            --query "Command.CommandId")
            
        if [ -z "$COMMAND_ID" ]; then
            echo -e "${RED}Failed to run the command.${NC}"
            return 1
        fi
        
        echo -e "${YELLOW}Waiting for command to complete...${NC}"
        aws ssm wait command-executed --command-id $COMMAND_ID --instance-id $INSTANCE_ID
        
        # Get command output
        OUTPUT=$(aws ssm get-command-invocation \
            --command-id $COMMAND_ID \
            --instance-id $INSTANCE_ID \
            --query "StandardOutputContent" \
            --output text)
            
        echo -e "${GREEN}Command output:${NC}"
        echo "$OUTPUT"
        
        # Cleanup
        rm $DOCUMENT_FILE
        
        echo -e "${GREEN}Nginx configuration updated successfully!${NC}"
    else
        echo -e "${YELLOW}SSH key and AWS CLI not available. Please update Nginx configuration manually:${NC}"
        echo "1. SSH into your EC2 instance:"
        echo "   ssh -i YOUR_KEY.pem ec2-user@$EC2_IP"
        echo ""
        echo "2. Create/update Nginx configuration:"
        echo "   sudo vi /etc/nginx/conf.d/ptchampion.conf"
        echo ""
        echo "3. Paste this configuration:"
        echo "   server {"
        echo "       listen 80;"
        echo "       server_name _;"
        echo ""
        echo "       # Handle frontend requests"
        echo "       location / {"
        echo "           root /home/ec2-user/ptchampion/dist/public;"
        echo "           try_files \$uri \$uri/ /index.html;"
        echo "       }"
        echo ""
        echo "       # Handle API requests"
        echo "       location /api/ {"
        echo "           proxy_pass http://localhost:3000;"
        echo "           proxy_http_version 1.1;"
        echo "           proxy_set_header Upgrade \$http_upgrade;"
        echo "           proxy_set_header Connection 'upgrade';"
        echo "           proxy_set_header Host \$host;"
        echo "           proxy_cache_bypass \$http_upgrade;"
        echo "       }"
        echo "   }"
        echo ""
        echo "4. Restart Nginx:"
        echo "   sudo systemctl restart nginx"
    fi
}

# Function to fix CloudFront configuration
fix_cloudfront() {
    echo -e "${YELLOW}Applying CloudFront configuration fix...${NC}"
    
    if command -v aws &> /dev/null; then
        # Get CloudFront distributions
        DISTRIBUTIONS=$(aws cloudfront list-distributions --query "DistributionList.Items[*].{Id:Id,DomainName:DomainName,Origins:Origins.Items[*].DomainName,Comment:Comment}" --output json)
        
        if [ -z "$DISTRIBUTIONS" ] || [ "$DISTRIBUTIONS" == "[]" ]; then
            echo -e "${RED}No CloudFront distributions found in this account.${NC}"
            return 1
        fi
        
        echo -e "${GREEN}Found CloudFront distributions:${NC}"
        echo "$DISTRIBUTIONS" | jq -r '.[] | "ID: \(.Id) - Domain: \(.DomainName) - Comment: \(.Comment) - Origins: \(.Origins[])"'
        
        # Ask user to select a distribution
        echo -e "${YELLOW}Enter the CloudFront distribution ID to update (from the list above):${NC}"
        read -p "> " DISTRIBUTION_ID
        
        if [ -z "$DISTRIBUTION_ID" ]; then
            echo -e "${RED}No distribution ID provided.${NC}"
            return 1
        fi
        
        # Get the current configuration
        CONFIG=$(aws cloudfront get-distribution-config --id $DISTRIBUTION_ID)
        
        if [ -z "$CONFIG" ]; then
            echo -e "${RED}Failed to get configuration for distribution $DISTRIBUTION_ID.${NC}"
            return 1
        fi
        
        # Extract ETag and Config
        ETAG=$(echo "$CONFIG" | jq -r '.ETag')
        DISTRIBUTION_CONFIG=$(echo "$CONFIG" | jq -r '.DistributionConfig')
        
        # Create a temporary file for the fixed configuration
        CONFIG_FILE=$(mktemp)
        
        # Check if distribution has behaviors for API
        API_BEHAVIOR_EXISTS=$(echo "$DISTRIBUTION_CONFIG" | jq -e '.CacheBehaviors.Items[] | select(.PathPattern == "/api*")' 2>/dev/null)
        API_BEHAVIOR_EXISTS_STATUS=$?
        
        # Fix the configuration - create specific behavior for /api* path
        if [ $API_BEHAVIOR_EXISTS_STATUS -ne 0 ]; then
            # API behavior doesn't exist, we need to add it
            echo -e "${YELLOW}Creating a new cache behavior for /api* paths...${NC}"
            
            # Find the ID of the origin with EC2 instance
            ORIGINS=$(echo "$DISTRIBUTION_CONFIG" | jq -r '.Origins.Items')
            
            echo -e "${YELLOW}Available origins:${NC}"
            echo "$ORIGINS" | jq -r '.[] | "- \(.Id): \(.DomainName)"'
            
            # Try to automatically find a suitable origin
            API_ORIGIN_ID=$(echo "$ORIGINS" | jq -r '.[] | select(.DomainName | contains("ec2") or contains("instance") or contains("api") or contains("backend")) | .Id' | head -1)
            
            if [ -z "$API_ORIGIN_ID" ]; then
                echo -e "${YELLOW}Enter the origin ID for your backend API:${NC}"
                read -p "> " API_ORIGIN_ID
                
                if [ -z "$API_ORIGIN_ID" ]; then
                    echo -e "${RED}No origin ID provided.${NC}"
                    return 1
                fi
            else
                echo -e "${GREEN}Automatically selected origin ID: $API_ORIGIN_ID${NC}"
            fi
            
            # Add the new cache behavior for API
            UPDATED_CONFIG=$(echo "$DISTRIBUTION_CONFIG" | jq ".CacheBehaviors.Quantity = (.CacheBehaviors.Quantity + 1) | 
                .CacheBehaviors.Items += [{
                \"PathPattern\": \"/api*\",
                \"TargetOriginId\": \"$API_ORIGIN_ID\",
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
            echo -e "${YELLOW}API cache behavior already exists. No changes needed.${NC}"
            UPDATED_CONFIG="$DISTRIBUTION_CONFIG"
        fi
        
        # Write the updated configuration to a temporary file
        echo "$UPDATED_CONFIG" > $CONFIG_FILE
        
        # Update the CloudFront distribution
        echo -e "${YELLOW}Updating CloudFront distribution...${NC}"
        UPDATE_RESULT=$(aws cloudfront update-distribution --id $DISTRIBUTION_ID --distribution-config file://$CONFIG_FILE --if-match $ETAG)
        
        if [ -z "$UPDATE_RESULT" ]; then
            echo -e "${RED}Failed to update CloudFront distribution.${NC}"
            return 1
        fi
        
        echo -e "${GREEN}CloudFront distribution updated successfully!${NC}"
        
        # Create an invalidation to apply changes quickly
        echo -e "${YELLOW}Creating invalidation to apply changes...${NC}"
        INVALIDATION_ID=$(aws cloudfront create-invalidation --distribution-id $DISTRIBUTION_ID --paths "/api/*" "/*" --query "Invalidation.Id" --output text)
        
        if [ -z "$INVALIDATION_ID" ]; then
            echo -e "${RED}Failed to create invalidation.${NC}"
            return 1
        fi
        
        echo -e "${GREEN}Invalidation created successfully. Invalidation ID: $INVALIDATION_ID${NC}"
        echo -e "${YELLOW}Invalidation may take several minutes to complete.${NC}"
        
        # Cleanup
        rm $CONFIG_FILE
    else
        echo -e "${YELLOW}AWS CLI not available. Please update CloudFront configuration manually:${NC}"
        echo "1. Open the AWS CloudFront console: https://console.aws.amazon.com/cloudfront/"
        echo "2. Select your distribution and go to the Behaviors tab"
        echo "3. Add a new behavior for path pattern '/api*'"
        echo "4. Set the following:"
        echo "   - Origin: Select the origin for your EC2 instance"
        echo "   - Allowed HTTP methods: All (GET, HEAD, OPTIONS, PUT, POST, PATCH, DELETE)"
        echo "   - Cache policy: CachingDisabled (recommended)"
        echo "   - Origin request policy: AllViewer"
        echo "5. Save changes and create an invalidation for '/*' and '/api/*'"
    fi
}

# Function for full deployment
deploy_full_application() {
    echo -e "${YELLOW}Starting full application deployment...${NC}"
    
    # Build the application
    build_application
    
    # Create a working directory
    WORK_DIR=$(mktemp -d)
    echo -e "${GREEN}Created temporary directory: $WORK_DIR${NC}"
    
    # Copy necessary files to working directory
    cp -r dist $WORK_DIR/
    cp Dockerfile $WORK_DIR/
    cp docker-compose.yml $WORK_DIR/
    cp nginx.conf $WORK_DIR/
    cp .env.production $WORK_DIR/
    cp package.json $WORK_DIR/
    cp package-lock.json $WORK_DIR/
    cp -r scripts $WORK_DIR/
    cp prod-server.js $WORK_DIR/
    
    echo -e "${GREEN}Copied application files to temporary directory${NC}"
    
    # Create a deployment package
    TAR_FILE_NAME="ptchampion_deploy.tar.gz"
    TAR_FILE_PATH="$(pwd)/$TAR_FILE_NAME"
    cd $WORK_DIR
    tar -czf "$TAR_FILE_PATH" .
    cd - > /dev/null
    echo -e "${GREEN}Created deployment package: $TAR_FILE_NAME${NC}"
    
    if [ "$USE_SSH" = true ]; then
        # Deploy using SSH
        echo -e "${GREEN}Deploying using SSH...${NC}"
        
        # Copy the deployment package to the EC2 instance
        echo -e "${YELLOW}Copying deployment package to EC2 instance...${NC}"
        scp -i $KEY_FILE -o StrictHostKeyChecking=no "$TAR_FILE_PATH" ec2-user@$EC2_IP:~/ || {
            echo -e "${RED}Failed to copy files to EC2 instance!${NC}"
            rm -rf $WORK_DIR
            rm "$TAR_FILE_PATH"
            return 1
        }
        
        # Execute deployment commands on the EC2 instance
        echo -e "${YELLOW}Executing deployment commands on EC2 instance...${NC}"
        ssh -i $KEY_FILE -o StrictHostKeyChecking=no ec2-user@$EC2_IP << 'EOF'
            set -e
            echo "Cleaning up old deployment..."
            rm -rf ~/ptchampion_deploy
            mkdir -p ~/ptchampion_deploy
            
            echo "Extracting deployment package..."
            tar -xzf ~/ptchampion_deploy.tar.gz -C ~/ptchampion_deploy
            cd ~/ptchampion_deploy
            
            # Install Docker if not already installed
            if ! command -v docker &> /dev/null; then
                echo "Installing Docker..."
                sudo yum update -y
                sudo amazon-linux-extras install docker -y || sudo yum install docker -y
                sudo systemctl start docker
                sudo systemctl enable docker
                sudo usermod -a -G docker ec2-user
                
                # Use the new group without logging out
                newgrp docker << 'EOFNEWGRP'
                    echo "Docker installed!"
EOFNEWGRP
            fi
            
            # Install Docker Compose if not already installed
            if ! command -v docker-compose &> /dev/null; then
                echo "Installing Docker Compose..."
                sudo curl -L "https://github.com/docker/compose/releases/download/v2.12.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
                sudo chmod +x /usr/local/bin/docker-compose
            fi
            
            # Start the application with Docker Compose
            echo "Starting application with Docker Compose..."
            docker-compose down || true
            docker-compose up -d
            
            # Verify services are running
            echo "Verifying services are running..."
            docker-compose ps
EOF

        echo -e "${GREEN}Deployment via SSH completed successfully!${NC}"
    else
        # Alternative deployment method when SSH key is not available
        echo -e "${YELLOW}SSH key not available. Please follow these steps:${NC}"
        echo "1. Copy the deployment package to your EC2 instance:"
        echo "   scp -i YOUR_KEY.pem $TAR_FILE_NAME ec2-user@$EC2_IP:~/"
        echo ""
        echo "2. SSH into your EC2 instance:"
        echo "   ssh -i YOUR_KEY.pem ec2-user@$EC2_IP"
        echo ""
        echo "3. Run these commands on your EC2 instance:"
        echo "   mkdir -p ~/ptchampion_deploy"
        echo "   tar -xzf ~/ptchampion_deploy.tar.gz -C ~/ptchampion_deploy"
        echo "   cd ~/ptchampion_deploy"
        echo "   docker-compose up -d"
    fi
    
    # Clean up
    rm -rf $WORK_DIR
    rm "$TAR_FILE_PATH"
    echo -e "${GREEN}Cleaned up temporary files${NC}"
    
    echo -e "${GREEN}Full deployment process completed!${NC}"
    echo "=============================================================="
    echo "Access your application at: http://$EC2_IP:8080"
    echo "API is available at: http://$EC2_IP:8080/api"
    echo "=============================================================="
}

# Create CloudFront invalidation helper function
create_cloudfront_invalidation() {
    echo -e "${YELLOW}Creating CloudFront invalidation...${NC}"
    
    if command -v aws &> /dev/null; then
        # List distributions
        DISTRIBUTIONS=$(aws cloudfront list-distributions --query "DistributionList.Items[*].Id" --output text 2>/dev/null)
        if [ -n "$DISTRIBUTIONS" ]; then
            echo -e "${YELLOW}Found CloudFront distributions. Please select one to invalidate:${NC}"
            echo $DISTRIBUTIONS | tr '\t' '\n' | nl
            read -p "Enter distribution number (or press Enter to skip): " DIST_NUM
            
            if [ -n "$DIST_NUM" ]; then
                DIST_ID=$(echo $DISTRIBUTIONS | tr '\t' '\n' | sed -n "${DIST_NUM}p")
                if [ -n "$DIST_ID" ]; then
                    echo -e "${YELLOW}Creating invalidation for distribution $DIST_ID...${NC}"
                    aws cloudfront create-invalidation --distribution-id $DIST_ID --paths "/*" "/api/*"
                    echo -e "${GREEN}Invalidation created!${NC}"
                fi
            fi
        else
            echo -e "${YELLOW}No CloudFront distributions found or AWS CLI not configured.${NC}"
            echo "You may need to create an invalidation manually."
        fi
    else
        echo -e "${YELLOW}AWS CLI not found. Please create a CloudFront invalidation manually.${NC}"
    fi
}

# Execute requested operations
if [ "$DEPLOY_FULL" = true ]; then
    deploy_full_application
fi

if [ "$FIX_BACKEND" = true ]; then
    fix_backend
fi

if [ "$FIX_CLOUDFRONT" = true ]; then
    fix_cloudfront
fi

if [ "$FIX_PORT" = true ]; then
    build_application
    fix_port_mismatch
    create_cloudfront_invalidation
    
    echo -e "${GREEN}Port fix completed!${NC}"
    echo "=============================================================="
    echo "What to verify:"
    echo "1. Backend should now be listening on port 3000"
    echo "2. API endpoints should be properly routed through Nginx"
    echo "3. User registration and other backend functionality should now work correctly"
    echo ""
    echo "If issues persist, check the following:"
    echo "1. Nginx configuration on EC2 instance (/etc/nginx/conf.d/ptchampion.conf)"
    echo "2. CloudFront cache (wait for invalidation to complete)"
    echo "3. Backend logs using: ssh into EC2 and run 'pm2 logs ptchampion-api'"
    echo "=============================================================="
fi

# If no operations were selected (only help was shown), exit now
if [ "$DEPLOY_FULL" != true ] && [ "$FIX_BACKEND" != true ] && [ "$FIX_CLOUDFRONT" != true ] && [ "$FIX_PORT" != true ]; then
    exit 0
fi

echo -e "${GREEN}All requested operations completed!${NC}"
