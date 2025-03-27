#!/bin/bash
set -e

# Colors for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Print script banner
echo -e "${GREEN}PT Champion Auth Fix Deployment Script${NC}"
echo "=============================================================="

# Configuration
API_EC2_IP="52.1.128.170"
KEY_FILE="ptchampion-key-new.pem"

if [ ! -f "$KEY_FILE" ]; then
    echo -e "${RED}SSH key file not found: $KEY_FILE${NC}"
    exit 1
fi

chmod 400 $KEY_FILE

# Upload the updated files
echo -e "${YELLOW}Uploading updated client files...${NC}"
scp -i $KEY_FILE client/src/lib/queryClient.ts ec2-user@$API_EC2_IP:~/ptchampion/client/src/lib/
scp -i $KEY_FILE client/src/hooks/use-auth.tsx ec2-user@$API_EC2_IP:~/ptchampion/client/src/hooks/

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Successfully uploaded updated files.${NC}"
else
    echo -e "${RED}Failed to upload updated files.${NC}"
    exit 1
fi

# Rebuild and restart the application
echo -e "${YELLOW}Rebuilding and restarting the application...${NC}"
ssh -i $KEY_FILE ec2-user@$API_EC2_IP << 'EOF'
cd ~/ptchampion
npm run build
pm2 restart ecosystem.config.cjs --env production
EOF

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Successfully rebuilt and restarted the application.${NC}"
else
    echo -e "${RED}Failed to rebuild and restart the application.${NC}"
    exit 1
fi

echo -e "${GREEN}Deployment completed!${NC}"
echo "=============================================================="
