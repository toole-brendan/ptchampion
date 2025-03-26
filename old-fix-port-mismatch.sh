#!/bin/bash
set -e

# Colors for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}PT Champion Backend Port Fix Script${NC}"
echo "This script deploys the backend port fix to your EC2 instance"
echo "=============================================================="

# Check if key file exists
KEY_FILE="ptchampion-key.pem"
if [ -f "$KEY_FILE" ]; then
    echo -e "${GREEN}Found SSH key file: $KEY_FILE${NC}"
    chmod 400 $KEY_FILE
    USE_SSH=true
else
    echo -e "${YELLOW}SSH key file not found. You'll need to manually apply the fix.${NC}"
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

# Build the application
echo -e "${YELLOW}Building application...${NC}"
npm run build
echo -e "${GREEN}Build completed successfully!${NC}"

if [ "$USE_SSH" = true ]; then
    # Deploy the fix using SSH
    echo -e "${YELLOW}Deploying fix to EC2 instance at $EC2_IP...${NC}"
    
    # Create a temporary directory for the backend files
    TEMP_DIR=$(mktemp -d)
    cp -r dist/index.js $TEMP_DIR/
    
    # Use SCP to copy the updated backend file
    echo -e "${YELLOW}Copying updated backend file to EC2...${NC}"
    scp -i $KEY_FILE -o StrictHostKeyChecking=no $TEMP_DIR/index.js ec2-user@$EC2_IP:~/ptchampion/dist/ || {
        echo -e "${RED}Failed to copy files to EC2 instance!${NC}"
        exit 1
    }
    
    # Clean up temporary directory
    rm -rf $TEMP_DIR
    
    # SSH into EC2 to restart the backend service
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

    echo -e "${GREEN}Port fix deployed! Backend should now be listening on port 3000.${NC}"
    echo -e "${YELLOW}Creating CloudFront invalidation to ensure changes are propagated...${NC}"
    
    # Use AWS CLI to create CloudFront invalidation if available
    if command -v aws &> /dev/null; then
        # Try to find CloudFront distribution
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
else
    # If SSH key not available, provide manual instructions
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
    echo ""
    echo "4. Create a CloudFront invalidation (if using CloudFront):"
    echo "   aws cloudfront create-invalidation --distribution-id YOUR_DISTRIBUTION_ID --paths \"/*\" \"/api/*\""
fi

echo -e "${GREEN}Port fix deployment process completed!${NC}"
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
