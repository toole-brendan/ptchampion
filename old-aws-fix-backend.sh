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

# Get the EC2 instance ID
EC2_IP="3.89.124.135"
echo -e "${YELLOW}Finding EC2 instance ID for IP: $EC2_IP${NC}"

INSTANCE_ID=$(aws ec2 describe-instances \
  --filters "Name=ip-address,Values=$EC2_IP" \
  --query "Reservations[].Instances[].InstanceId" \
  --output text)

if [ -z "$INSTANCE_ID" ]; then
  echo -e "${RED}Could not find EC2 instance with IP: $EC2_IP${NC}"
  exit 1
fi

echo -e "${GREEN}Found EC2 instance: $INSTANCE_ID${NC}"

# Check if Systems Manager agent is installed on the instance
INSTANCE_SSM_STATUS=$(aws ssm describe-instance-information \
  --filters "Key=InstanceIds,Values=$INSTANCE_ID" \
  --query "InstanceInformationList[].PingStatus" \
  --output text)

if [ "$INSTANCE_SSM_STATUS" != "Online" ]; then
  echo -e "${RED}Systems Manager agent is not installed or not online on the instance.${NC}"
  echo "Please install and configure SSM agent: https://docs.aws.amazon.com/systems-manager/latest/userguide/ssm-agent.html"
  echo -e "${YELLOW}Alternatively, follow the steps below using AWS CloudFormation:${NC}"
  
  # Create a CloudFormation template for the fix
  cat > ptchampion-fix.yaml << EOF
AWSTemplateFormatVersion: '2010-09-09'
Description: 'PT Champion Backend Fix - Update Nginx Configuration'

Resources:
  FixNginxConfig:
    Type: AWS::CloudFormation::Init
    Properties:
      ConfigSets:
        default:
          - UpdateNginx
      UpdateNginx:
        files:
          /etc/nginx/conf.d/ptchampion.conf:
            content: |
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
                      proxy_set_header Connection 'upgrade';
                      proxy_set_header Host \$host;
                      proxy_cache_bypass \$http_upgrade;
                  }
              }
            mode: '000644'
            owner: root
            group: root
        commands:
          01_restart_nginx:
            command: systemctl restart nginx
          02_restart_backend:
            command: |
              cd /home/ec2-user/ptchampion
              pm2 restart ptchampion-api || pm2 start dist/index.js --name ptchampion-api

  UpdateInstanceMetadata:
    Type: AWS::CloudFormation::Stack
    Properties:
      TemplateURL: https://aws-cloudformation-templates-us-east-1.s3.amazonaws.com/update-ec2-metadata.yaml
      Parameters:
        InstanceId: ${INSTANCE_ID}
        ConfigSetName: default
EOF

  echo -e "${YELLOW}Created CloudFormation template: ptchampion-fix.yaml${NC}"
  echo "To apply the fix using CloudFormation, run:"
  echo "aws cloudformation create-stack --stack-name ptchampion-fix --template-body file://ptchampion-fix.yaml --capabilities CAPABILITY_IAM"
  
  exit 1
fi

echo -e "${GREEN}Systems Manager agent is online on the instance.${NC}"

# Create the command document
echo -e "${YELLOW}Creating a command to update Nginx configuration...${NC}"

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

# Check if the document already exists
DOCUMENT_EXISTS=$(aws ssm list-documents --document-filter "key=Name,value=$DOCUMENT_NAME" --query "DocumentIdentifiers[].Name" --output text)

if [ -n "$DOCUMENT_EXISTS" ]; then
  echo -e "${YELLOW}Document $DOCUMENT_NAME already exists. Deleting it...${NC}"
  aws ssm delete-document --name $DOCUMENT_NAME
fi

# Create the document
echo -e "${GREEN}Creating Systems Manager document: $DOCUMENT_NAME${NC}"
aws ssm create-document --name $DOCUMENT_NAME --document-type "Command" --content file://$DOCUMENT_FILE

# Run the command
echo -e "${YELLOW}Running the command on instance $INSTANCE_ID...${NC}"
COMMAND_ID=$(aws ssm send-command \
  --document-name $DOCUMENT_NAME \
  --targets "Key=instanceids,Values=$INSTANCE_ID" \
  --output text \
  --query "Command.CommandId")

if [ -z "$COMMAND_ID" ]; then
  echo -e "${RED}Failed to run the command.${NC}"
  exit 1
fi

echo -e "${GREEN}Command sent successfully. Command ID: $COMMAND_ID${NC}"

# Wait for the command to complete
echo -e "${YELLOW}Waiting for the command to complete...${NC}"
aws ssm wait command-executed --command-id $COMMAND_ID --instance-id $INSTANCE_ID

# Get the command output
echo -e "${YELLOW}Getting command output...${NC}"
OUTPUT=$(aws ssm get-command-invocation \
  --command-id $COMMAND_ID \
  --instance-id $INSTANCE_ID \
  --query "StandardOutputContent" \
  --output text)

echo -e "${GREEN}Command output:${NC}"
echo "$OUTPUT"

# Check the command status
STATUS=$(aws ssm get-command-invocation \
  --command-id $COMMAND_ID \
  --instance-id $INSTANCE_ID \
  --query "Status" \
  --output text)

if [ "$STATUS" = "Success" ]; then
  echo -e "${GREEN}Fix applied successfully!${NC}"
  echo -e "${YELLOW}Please wait a few minutes and try accessing your application again.${NC}"
  echo "The API should now be properly routed to the backend service."
else
  echo -e "${RED}Command failed with status: $STATUS${NC}"
  echo -e "${YELLOW}Error output:${NC}"
  aws ssm get-command-invocation \
    --command-id $COMMAND_ID \
    --instance-id $INSTANCE_ID \
    --query "StandardErrorContent" \
    --output text
fi

# Cleanup
rm $DOCUMENT_FILE

# Extra steps for CloudFront
echo
echo -e "${YELLOW}If your site is behind CloudFront, you may need to create an invalidation:${NC}"
echo "aws cloudfront create-invalidation --distribution-id YOUR_DISTRIBUTION_ID --paths \"/*\""
echo
echo -e "${YELLOW}Also make sure your CloudFront origin is correctly set up:${NC}"
echo "1. Check your CloudFront distribution settings"
echo "2. Verify the origin domain name points to your EC2 instance: $EC2_IP"
echo "3. Ensure the origin protocol policy allows HTTP traffic"
