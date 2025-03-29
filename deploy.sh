#!/bin/bash
set -e

# Colors for better output
RED='\\033[0;31m'
GREEN='\\033[0;32m'
YELLOW='\\033[1;33m'
NC='\\033[0m' # No Color

# --- Configuration ---
# Load primary configuration from .env.production
if [ -f ".env.production" ]; then
    # Use a more robust method to export variables, ignoring comments and handling potential whitespace
    export $(grep -v '^#' .env.production | sed -e 's/[[:space:]]*$//' -e 's/^[[:space:]]*//' | xargs -0)
else
    echo -e "${RED}Error: .env.production file not found.${NC}"
    exit 1
fi

# Rename variables to avoid potential conflicts with system env vars
API_EC2_IP="$EC2_IP"
API_EC2_HOSTNAME="$EC2_HOSTNAME"
API_S3_BUCKET="$S3_BUCKET"
API_CLOUDFRONT_ID="$CLOUDFRONT_DISTRIBUTION_ID"

# Add defaults if not found in .env.production
API_S3_BUCKET=${API_S3_BUCKET:-"ptchampion.ai"}
API_CLOUDFRONT_ID=${API_CLOUDFRONT_ID:-"E1FRFF3JQNGRE1"} # Replace if needed
KEY_FILE="ptchampion-key-new.pem" # Use the new key file name
LOCAL_FRONTEND_PATH="./dist/public"
REMOTE_APP_DIR="~/ptchampion"
REMOTE_USER="ec2-user"
PM2_PROCESS_NAME="ptchampion-api"

# Check if essential variables are set
if [ -z "$API_EC2_IP" ] || [ -z "$API_EC2_HOSTNAME" ]; then
    echo -e "${RED}Error: EC2_IP or EC2_HOSTNAME not set in .env.production.${NC}"
    exit 1
fi

# Print script banner
echo -e "${GREEN}PT Champion Unified Deployment Script${NC}"
echo "=============================================================="
echo "Target S3 Bucket:          $API_S3_BUCKET"
echo "CloudFront Distribution ID: $API_CLOUDFRONT_ID"
echo "Target EC2 IP:             $API_EC2_IP"
echo "Target EC2 Hostname:       $API_EC2_HOSTNAME"
echo "SSH Key File:              $KEY_FILE"
echo "Remote App Directory:      $REMOTE_APP_DIR"
echo "=============================================================="

# Ensure AWS CLI is installed and configured
if ! command -v aws &> /dev/null; then
  echo -e "${RED}AWS CLI is not installed. Please install it first.${NC}"
  exit 1
fi
if ! aws sts get-caller-identity &> /dev/null; then
  echo -e "${RED}AWS CLI is not configured. Please run 'aws configure' first.${NC}"
  exit 1
fi

# --- SSH Setup ---
USE_SSH=false
SSH_OPTIONS="-o StrictHostKeyChecking=no -o ConnectTimeout=10"
if [ -f "$KEY_FILE" ]; then
    echo -e "${GREEN}Found SSH key file: $KEY_FILE${NC}"
    chmod 400 "$KEY_FILE"
    USE_SSH=true
else
    echo -e "${YELLOW}SSH key file '$KEY_FILE' not found. Backend deployment steps will be skipped.${NC}"
    echo -e "${YELLOW}Will attempt CloudFront update and frontend deployment only.${NC}"
fi
SSH_CMD="ssh -i $KEY_FILE $SSH_OPTIONS $REMOTE_USER@$API_EC2_IP"
SCP_CMD="scp -i $KEY_FILE $SSH_OPTIONS"

# --- Helper Functions ---

# Function to display help
show_help() {
  echo "Usage: ./deploy.sh [OPTIONS]"
  echo ""
  echo "OPTIONS:"
  echo "  --full               Full deployment: frontend, backend, CloudFront update, test."
  echo "  --frontend           Deploy frontend to S3 and invalidate CloudFront."
  echo "  --backend            Deploy backend code/env, configure Nginx, restart app."
  echo "  --configure-cf       Configure CloudFront API origin and invalidate."
  echo "  --invalidate         Only create a CloudFront invalidation."
  echo "  --test-api           Test API connection (direct and via CloudFront)."
  echo "  --help               Show this help message."
  echo ""
  echo "If no option is specified, '--full' is assumed."
  echo "Note: Backend operations require the SSH key file '$KEY_FILE'."
}

# Function to create CloudFront invalidation
create_cloudfront_invalidation() {
  echo -e "${YELLOW}Creating CloudFront invalidation for distribution: $API_CLOUDFRONT_ID${NC}"
  # Combine the AWS command onto a single line for robustness
  INVALIDATION_ID=$(aws cloudfront create-invalidation --distribution-id "$API_CLOUDFRONT_ID" --paths "/*" "/api/*" --query 'Invalidation.Id' --output text)

  if [ -n "$INVALIDATION_ID" ]; then
    echo -e "${GREEN}Successfully created CloudFront invalidation. ID: $INVALIDATION_ID${NC}"
    echo -e "${YELLOW}Invalidation may take 5-10 minutes to complete.${NC}"
  else
    echo -e "${RED}Failed to create CloudFront invalidation.${NC}"
    # Don't exit, maybe other steps succeeded
  fi
}

# Function to build frontend if needed
build_frontend() {
  if [ ! -d "$LOCAL_FRONTEND_PATH" ] || [ ! -f "$LOCAL_FRONTEND_PATH/index.html" ]; then
    echo -e "${YELLOW}Frontend build directory '$LOCAL_FRONTEND_PATH' not found or incomplete. Running build...${NC}"
    if npm run build; then
      echo -e "${GREEN}Frontend build successful.${NC}"
    else
      echo -e "${RED}Frontend build failed. Aborting.${NC}"
      exit 1
    fi
  else
    echo -e "${GREEN}Frontend already built.${NC}"
  fi
}

# Function to sync frontend files to S3
deploy_frontend_to_s3() {
  build_frontend
  echo -e "${YELLOW}Syncing frontend files from '$LOCAL_FRONTEND_PATH' to S3 bucket: $API_S3_BUCKET${NC}"
  if aws s3 sync "$LOCAL_FRONTEND_PATH" "s3://$API_S3_BUCKET" --delete; then
    echo -e "${GREEN}Successfully synced frontend files to S3.${NC}"
    create_cloudfront_invalidation
  else
    echo -e "${RED}Failed to sync frontend files to S3.${NC}"
    exit 1
  fi
}

# Function to deploy backend code and environment
deploy_backend_code() {
  if [ "$USE_SSH" = false ]; then echo -e "${YELLOW}Skipping backend code deployment (SSH key missing).${NC}"; return; fi

  echo -e "${YELLOW}Deploying backend code and environment to $API_EC2_IP...${NC}"

  # Ensure remote directory exists
  $SSH_CMD "mkdir -p $REMOTE_APP_DIR/dist"

  # Copy backend build artifact
  echo "Copying dist/index.js..."
  if ! $SCP_CMD "./dist/index.js" "$REMOTE_USER@$API_EC2_IP:$REMOTE_APP_DIR/dist/"; then
      echo -e "${RED}Failed to copy backend code.${NC}"; exit 1;
  fi

  # Copy package.json (needed for npm install on server)
  echo "Copying package.json..."
   if ! $SCP_CMD "./package.json" "$REMOTE_USER@$API_EC2_IP:$REMOTE_APP_DIR/"; then
       echo -e "${RED}Failed to copy package.json.${NC}"; exit 1;
   fi
   # Copy package-lock.json (important for consistent dependencies)
   if [ -f "./package-lock.json" ]; then
       echo "Copying package-lock.json..."
       if ! $SCP_CMD "./package-lock.json" "$REMOTE_USER@$API_EC2_IP:$REMOTE_APP_DIR/"; then
           echo -e "${RED}Failed to copy package-lock.json.${NC}"; exit 1;
       fi
   fi


  # Copy .env.production
  echo "Copying .env.production..."
  if ! $SCP_CMD ".env.production" "$REMOTE_USER@$API_EC2_IP:$REMOTE_APP_DIR/.env.production"; then
      echo -e "${RED}Failed to copy .env.production.${NC}"; exit 1;
  fi

  echo -e "${GREEN}Backend code and environment copied successfully.${NC}"
}

# Function to configure Nginx and restart backend app
configure_and_restart_backend() {
  if [ "$USE_SSH" = false ]; then echo -e "${YELLOW}Skipping backend configuration (SSH key missing).${NC}"; return; fi

  echo -e "${YELLOW}Configuring Nginx and restarting backend on $API_EC2_IP...${NC}"

  # Define Nginx config content - use PORT from .env or default to 3000
  # Use standard grep options to extract PORT from the copied .env.production on the server
  # We need to execute this command remotely via SSH to get the PORT from the server's file
  # Use absolute path for reliability
  REMOTE_APP_ABS_PATH="/home/$REMOTE_USER/ptchampion"
  TARGET_PORT=$($SSH_CMD "grep '^PORT=' $REMOTE_APP_ABS_PATH/.env.production | cut -d'=' -f2" || echo 3000)
  # Default to 3000 if grep fails or PORT is not set
  TARGET_PORT=${TARGET_PORT:-3000}

  NGINX_CONF="server {
    listen 80;
    server_name _; # Listen for any hostname

    # Handle Let's Encrypt challenges
    location /.well-known/acme-challenge/ {
        root /var/www/html; # Or adjust path as needed
    }

    # Proxy API requests to the Node app
    location /api/ {
        proxy_pass http://localhost:$TARGET_PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \\\$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \\\$host;
        proxy_set_header X-Real-IP \\\$remote_addr;
        proxy_set_header X-Forwarded-For \\\$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \\\$scheme;
        proxy_cache_bypass \\\$http_upgrade;
        proxy_read_timeout 300s; # Increase timeout for potentially long requests
        proxy_connect_timeout 75s;
    }

    # Optional: Redirect root to a specific page or handle differently
    # location = / {
    #    return 404; # Or redirect, proxy_pass, etc.
    # }
}"

  # SSH into EC2 and execute commands
  $SSH_CMD << EOF
set -e # Exit on error

# Use absolute path for remote directory
REMOTE_APP_ABS_PATH="/home/$REMOTE_USER/ptchampion"

# Ensure the base remote directory exists
echo "Ensuring remote directory exists: $REMOTE_APP_ABS_PATH"
mkdir -p "$REMOTE_APP_ABS_PATH"

echo 'Updating Nginx configuration...'
echo "$NGINX_CONF" | sudo tee /etc/nginx/conf.d/ptchampion.conf > /dev/null
echo 'Testing Nginx configuration...'
sudo nginx -t
echo 'Restarting Nginx...'
sudo systemctl restart nginx

echo "Navigating to app directory: $REMOTE_APP_ABS_PATH"
cd "$REMOTE_APP_ABS_PATH"

echo 'Ensuring clean dependencies...'
rm -rf node_modules

echo 'Installing all dependencies...'
# Run npm install in the correct absolute directory
npm install --no-progress --prefix "$REMOTE_APP_ABS_PATH"

echo 'Checking PM2 status before restart...'
pm2 list

echo 'Force restarting application with PM2...'
# Use absolute paths for pm2 commands as well
ECOSYSTEM_CJS="$REMOTE_APP_ABS_PATH/ecosystem.config.cjs"
ECOSYSTEM_JS="$REMOTE_APP_ABS_PATH/ecosystem.config.js"
BACKEND_SCRIPT="$REMOTE_APP_ABS_PATH/dist/index.js"

# Delete existing process first to ensure clean start
pm2 delete "$PM2_PROCESS_NAME" || echo "Process $PM2_PROCESS_NAME not found or already stopped."

# Start based on ecosystem file or script path
if [ -f "$ECOSYSTEM_CJS" ]; then
    pm2 start "$ECOSYSTEM_CJS" --env production
elif [ -f "$ECOSYSTEM_JS" ]; then
     pm2 start "$ECOSYSTEM_JS" --env production
else
    # Start using script path
    NODE_ENV=production pm2 start "$BACKEND_SCRIPT" --name "$PM2_PROCESS_NAME"
fi

echo 'Checking PM2 status after restart...'
pm2 list

echo 'Waiting a few seconds for the app to start...'
sleep 5

echo 'Checking app health...'
# Use curl on localhost inside EC2 to check health
curl -sf http://localhost:$TARGET_PORT/api/health || echo "Warning: Health check failed, app might still be starting."

echo 'Backend configuration and restart complete.'
EOF

  if [ $? -eq 0 ]; then
      echo -e "${GREEN}Backend configured and restarted successfully.${NC}"
  else
      echo -e "${RED}Failed to configure/restart backend.${NC}"
      exit 1
  fi
}

# Function to update CloudFront Origin to point to the correct EC2 Hostname
update_cloudfront_origin() {
  echo -e "${YELLOW}Updating CloudFront distribution '$API_CLOUDFRONT_ID' to point API to '$API_EC2_HOSTNAME'...${NC}"

  # 1. Get current distribution config and ETag
  echo "Fetching current CloudFront config..."
  CONFIG_OUTPUT=$(aws cloudfront get-distribution-config --id "$API_CLOUDFRONT_ID" 2>&1)
  if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to get CloudFront config: $CONFIG_OUTPUT${NC}"
    exit 1
  fi
  ETAG=$(echo "$CONFIG_OUTPUT" | jq -r '.ETag')
  CURRENT_CONFIG=$(echo "$CONFIG_OUTPUT" | jq '.DistributionConfig')

  if [ -z "$ETAG" ] || [ -z "$CURRENT_CONFIG" ]; then
    echo -e "${RED}Failed to parse ETag or DistributionConfig.${NC}"
    exit 1
  fi

  # 2. Find the Origin ID used by the /api* cache behavior
  # Check both /api* and /api/* patterns
  API_ORIGIN_ID=$(echo "$CURRENT_CONFIG" | jq -r '.CacheBehaviors.Items[]? | select(.PathPattern == "/api*" or .PathPattern == "/api/*") | .TargetOriginId' | head -n 1)

  if [ -z "$API_ORIGIN_ID" ]; then
    echo -e "${RED}Error: Could not find a cache behavior for '/api*' or '/api/*' in CloudFront config.${NC}"
    echo -e "${YELLOW}You may need to add one manually in the AWS console first.${NC}"
    exit 1
  fi
  echo "Found API Origin ID: $API_ORIGIN_ID"

  # 3. Check if the origin domain or cache policy needs updating
  CURRENT_DOMAIN=$(echo "$CURRENT_CONFIG" | jq -r --arg ID "$API_ORIGIN_ID" '.Origins.Items[]? | select(.Id == $ID) | .DomainName')
  CURRENT_CACHE_POLICY=$(echo "$CURRENT_CONFIG" | jq -r '.CacheBehaviors.Items[]? | select(.PathPattern == "/api/*") | .CachePolicyId')
  DESIRED_CACHE_POLICY="4135ea2d-6df8-44a3-9df3-4b5a84be39ad" # Managed-CachingDisabled

  echo "Current domain for Origin ID $API_ORIGIN_ID: $CURRENT_DOMAIN"
  echo "Current cache policy for /api/*: $CURRENT_CACHE_POLICY"

  if [ "$CURRENT_DOMAIN" == "$API_EC2_HOSTNAME" ] && [ "$CURRENT_CACHE_POLICY" == "$DESIRED_CACHE_POLICY" ]; then
    echo -e "${GREEN}CloudFront origin domain and API cache policy are already correct. No update needed.${NC}"
    return 0 # Success, no change needed
  fi

  # 4. Modify the config JSON: Update domain and/or cache policy if needed
  echo "Updating CloudFront configuration..."
  UPDATED_CONFIG=$(echo "$CURRENT_CONFIG" | jq \
    --arg ID "$API_ORIGIN_ID" \
    --arg HOSTNAME "$API_EC2_HOSTNAME" \
    --arg CACHE_POLICY "$DESIRED_CACHE_POLICY" '
    # Update origin domain name if needed
    (if .Origins.Items[] | select(.Id == $ID) | .DomainName != $HOSTNAME then (.Origins.Items[] | select(.Id == $ID) | .DomainName) |= $HOSTNAME else . end) |
    # Update cache policy for /api/* behavior if needed
    (if .CacheBehaviors.Items[] | select(.PathPattern == "/api/*") | .CachePolicyId != $CACHE_POLICY then (.CacheBehaviors.Items[] | select(.PathPattern == "/api/*") | .CachePolicyId) |= $CACHE_POLICY else . end)
  ')

  # Check if jq command succeeded
  if [ -z "$UPDATED_CONFIG" ]; then
    echo -e "${RED}Error modifying CloudFront config with jq.${NC}"
    exit 1
  fi

  # 5. Save the updated config to a temporary file
  CONFIG_FILE=$(mktemp)
  echo "$UPDATED_CONFIG" > "$CONFIG_FILE"
  echo "Updated config saved to $CONFIG_FILE"

  # 6. Update the distribution
  echo "Applying updated configuration to CloudFront..."
  # Combine the AWS command onto a single line for robustness
  UPDATE_OUTPUT=$(aws cloudfront update-distribution --id "$API_CLOUDFRONT_ID" --distribution-config "file://$CONFIG_FILE" --if-match "$ETAG" 2>&1)

  # Clean up temp file
  rm "$CONFIG_FILE"

  if [ $? -eq 0 ]; then
    echo -e "${GREEN}Successfully submitted CloudFront update request.${NC}"
    echo "$UPDATE_OUTPUT" | jq '.' # Print formatted JSON output
    create_cloudfront_invalidation # Invalidate cache after successful update
  else
    echo -e "${RED}Failed to update CloudFront distribution:${NC}"
    echo "$UPDATE_OUTPUT"
    exit 1
  fi
}


# Function to test API connection
test_api_connection() {
  echo -e "${YELLOW}Testing API connection...${NC}"
  HEALTH_PATH="/api/health"
  DIRECT_URL="http://$API_EC2_IP$HEALTH_PATH"
  CF_URL="https://ptchampion.ai$HEALTH_PATH" # Assuming ptchampion.ai is the domain

  echo "Testing direct connection to EC2: $DIRECT_URL"
  # Use curl with options: -s silent, -f fail fast, -L follow redirects, -m timeout
  if curl -sfL -m 10 "$DIRECT_URL"; then
    echo -e "${GREEN}Direct connection to EC2 API successful.${NC}"
  else
    echo -e "${RED}Direct connection to EC2 API failed. Check if Nginx/Node app are running on $API_EC2_IP.${NC}"
    if [ "$USE_SSH" = false ]; then echo -e "${YELLOW}(Skipped detailed check because SSH key is missing)${NC}"; fi
  fi

  echo "Testing connection via CloudFront: $CF_URL"
  if curl -sfL -m 15 "$CF_URL"; then
    echo -e "${GREEN}Connection via CloudFront successful.${NC}"
  else
    echo -e "${RED}Connection via CloudFront failed.${NC}"
    echo -e "${YELLOW}This might be due to DNS propagation delays, CloudFront caching, or configuration issues.${NC}"
    echo -e "${YELLOW}Wait a few minutes and try again. If it persists, check CloudFront config and EC2 logs.${NC}"
  fi
}

# --- Main Execution Logic ---

# Default action is --full
ACTION=${1:-"--full"}

case "$ACTION" in
  --full)
    echo "Starting full deployment..."
    deploy_frontend_to_s3
    deploy_backend_code
    configure_and_restart_backend
    update_cloudfront_origin # Update CF *after* backend should be ready
    test_api_connection
    ;;
  --frontend)
    echo "Starting frontend-only deployment..."
    deploy_frontend_to_s3
    ;;
  --backend)
    if [ "$USE_SSH" = false ]; then echo -e "${RED}Cannot perform backend deployment without SSH key '$KEY_FILE'.${NC}"; exit 1; fi
    echo "Starting backend-only deployment..."
    deploy_backend_code
    configure_and_restart_backend
    test_api_connection
    ;;
  --configure-cf)
    echo "Starting CloudFront configuration update..."
    update_cloudfront_origin
    ;;
  --invalidate)
    echo "Starting CloudFront invalidation only..."
    create_cloudfront_invalidation
    ;;
  --test-api)
    echo "Starting API connection test..."
    test_api_connection
    ;;
  --help)
    show_help
    exit 0
    ;;
  *)
    echo -e "${RED}Unknown option: $ACTION${NC}"
    show_help
    exit 1
    ;;
esac

echo -e "${GREEN}Deployment script finished.${NC}"
echo "=============================================================="
echo "Application URL: https://ptchampion.ai"
echo "API Endpoint:    https://ptchampion.ai/api"
echo "Direct API URL:  http://$API_EC2_IP/api"
echo "==============================================================" 