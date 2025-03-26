#!/bin/bash

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
  echo -e "${RED}AWS CLI is not installed. Please install it first:${NC}"
  echo "https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
  exit 1
fi

# Check if AWS CLI is configured
if ! aws sts get-caller-identity &> /dev/null; then
  echo -e "${RED}AWS CLI is not configured. Please run 'aws configure' first.${NC}"
  exit 1
fi

# Get CloudFront distributions
echo -e "${YELLOW}Retrieving CloudFront distributions...${NC}"
DISTRIBUTIONS=$(aws cloudfront list-distributions --query "DistributionList.Items[*].{Id:Id,DomainName:DomainName,Origins:Origins.Items[*].DomainName,Comment:Comment}" --output json)

if [ -z "$DISTRIBUTIONS" ] || [ "$DISTRIBUTIONS" == "[]" ]; then
  echo -e "${RED}No CloudFront distributions found in this account.${NC}"
  exit 1
fi

echo -e "${GREEN}Found CloudFront distributions:${NC}"
echo "$DISTRIBUTIONS" | jq -r '.[] | "ID: \(.Id) - Domain: \(.DomainName) - Comment: \(.Comment) - Origins: \(.Origins[])"'

# Ask user to select a distribution
echo -e "${YELLOW}Enter the CloudFront distribution ID to update (from the list above):${NC}"
read -p "> " DISTRIBUTION_ID

if [ -z "$DISTRIBUTION_ID" ]; then
  echo -e "${RED}No distribution ID provided.${NC}"
  exit 1
fi

# Get the current configuration
echo -e "${YELLOW}Getting configuration for distribution $DISTRIBUTION_ID...${NC}"
CONFIG=$(aws cloudfront get-distribution-config --id $DISTRIBUTION_ID)

if [ -z "$CONFIG" ]; then
  echo -e "${RED}Failed to get configuration for distribution $DISTRIBUTION_ID.${NC}"
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

# Fix the configuration - create specific behavior for /api* path
if [ $API_BEHAVIOR_EXISTS_STATUS -ne 0 ]; then
  # API behavior doesn't exist, we need to add it
  
  echo -e "${YELLOW}Creating a new cache behavior for /api* paths...${NC}"
  
  # Find the ID of the origin with EC2 instance
  ORIGINS=$(echo "$DISTRIBUTION_CONFIG" | jq -r '.Origins.Items')
  
  echo -e "${YELLOW}Available origins:${NC}"
  echo "$ORIGINS" | jq -r '.[] | "- \(.Id): \(.DomainName)"'
  
  echo -e "${YELLOW}Enter the origin ID for your backend API (from the list above):${NC}"
  read -p "> " API_ORIGIN_ID
  
  if [ -z "$API_ORIGIN_ID" ]; then
    # Let's try to find it automatically based on a common pattern
    API_ORIGIN_ID=$(echo "$ORIGINS" | jq -r '.[] | select(.DomainName | contains("ec2") or contains("instance") or contains("api") or contains("backend")) | .Id' | head -1)
    
    if [ -z "$API_ORIGIN_ID" ]; then
      echo -e "${RED}Could not automatically determine the API origin ID.${NC}"
      echo -e "${YELLOW}Available origins:${NC}"
      echo "$ORIGINS" | jq -r '.[] | "- \(.Id): \(.DomainName)"'
      echo -e "${YELLOW}Enter the origin ID for your backend API (from the list above):${NC}"
      read -p "> " API_ORIGIN_ID
      
      if [ -z "$API_ORIGIN_ID" ]; then
        echo -e "${RED}No origin ID provided.${NC}"
        exit 1
      fi
    else
      echo -e "${GREEN}Automatically selected origin ID: $API_ORIGIN_ID${NC}"
    fi
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
  echo -e "${YELLOW}API cache behavior already exists. Updating it...${NC}"
  UPDATED_CONFIG="$DISTRIBUTION_CONFIG"
fi

# Write the updated configuration to a temporary file
echo "$UPDATED_CONFIG" > $CONFIG_FILE

# Update the CloudFront distribution
echo -e "${YELLOW}Updating CloudFront distribution...${NC}"
UPDATE_RESULT=$(aws cloudfront update-distribution --id $DISTRIBUTION_ID --distribution-config file://$CONFIG_FILE --if-match $ETAG)

if [ -z "$UPDATE_RESULT" ]; then
  echo -e "${RED}Failed to update CloudFront distribution.${NC}"
  exit 1
fi

echo -e "${GREEN}CloudFront distribution updated successfully!${NC}"

# Create an invalidation to apply changes quickly
echo -e "${YELLOW}Creating invalidation to apply changes...${NC}"
INVALIDATION_ID=$(aws cloudfront create-invalidation --distribution-id $DISTRIBUTION_ID --paths "/api/*" "/*" --query "Invalidation.Id" --output text)

if [ -z "$INVALIDATION_ID" ]; then
  echo -e "${RED}Failed to create invalidation.${NC}"
  exit 1
fi

echo -e "${GREEN}Invalidation created successfully. Invalidation ID: $INVALIDATION_ID${NC}"
echo -e "${YELLOW}Waiting for invalidation to complete (this may take several minutes)...${NC}"

# Wait for the invalidation to complete
aws cloudfront wait invalidation-completed --distribution-id $DISTRIBUTION_ID --id $INVALIDATION_ID

echo -e "${GREEN}Invalidation completed! Your changes should now be propagated.${NC}"
echo -e "${YELLOW}Please test your application to verify the fix:${NC}"
echo "1. Try registering a new user"
echo "2. Verify that API requests are properly routed to the backend"
echo "3. If issues persist, check CloudFront and EC2 logs for errors"

# Cleanup
rm $CONFIG_FILE

echo -e "${GREEN}Fix process completed successfully!${NC}"
