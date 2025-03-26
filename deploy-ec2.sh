#!/bin/bash
set -e

# Colors for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Print script banner
echo -e "${GREEN}PT Champion EC2 Deployment Script${NC}"
echo "=============================================================="

# Configuration
API_EC2_IP="52.1.128.170"
KEY_FILE="ptchampion-key.pem"

if [ ! -f "$KEY_FILE" ]; then
    echo -e "${RED}SSH key file not found: $KEY_FILE${NC}"
    exit 1
fi

chmod 400 $KEY_FILE

# Upload the minimal server
echo -e "${YELLOW}Uploading minimal server...${NC}"
scp -i $KEY_FILE minimal-server.js ec2-user@$API_EC2_IP:~/ptchampion/

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Successfully uploaded minimal server.${NC}"
else
    echo -e "${RED}Failed to upload minimal server.${NC}"
    exit 1
fi

# Start the server
echo -e "${YELLOW}Starting the server...${NC}"
ssh -i $KEY_FILE ec2-user@$API_EC2_IP << 'EOF'
cd ~/ptchampion
pm2 stop ptchampion-api || true
pm2 start minimal-server.js --name ptchampion-api
EOF

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Successfully started the server.${NC}"
else
    echo -e "${RED}Failed to start the server.${NC}"
    exit 1
fi

echo -e "${GREEN}Deployment completed!${NC}"
echo "==============================================================" 