#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.

# Colors for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# --- Configuration ---
# Load primary configuration from .env.production
if [ -f ".env.production" ]; then
    echo -e "${YELLOW}Loading configuration from .env.production...${NC}"
    # Use a more robust method to export variables, ignoring comments and handling potential whitespace
    # Filter only the variables needed for deployment
    export $(grep -v '^#' .env.production | grep -E '^(AWS_REGION|ECR_REPOSITORY_URI|EC2_IP|EC2_HOSTNAME|S3_BUCKET|CLOUDFRONT_DISTRIBUTION_ID|DATABASE_URL|JWT_SECRET|CLIENT_ORIGIN|DB_SECRET_ARN|JWT_SECRET_ARN)=' | sed -e 's/[[:space:]]*$//' -e 's/^[[:space:]]*//' | xargs)
else
    echo -e "${RED}Error: .env.production file not found.${NC}"
    exit 1
fi

# --- Deployment Variables ---
# Mandatory variables - check if they are loaded
if [ -z "$AWS_REGION" ] || [ -z "$ECR_REPOSITORY_URI" ] || [ -z "$EC2_IP" ]; then
    echo -e "${RED}Error: One or more mandatory variables (AWS_REGION, ECR_REPOSITORY_URI, EC2_IP) are not set in .env.production.${NC}"
    exit 1
fi

# Check if we're using AWS Secrets Manager or direct secrets
USE_AWS_SECRETS=false
if [ -n "$DB_SECRET_ARN" ] && [ -n "$JWT_SECRET_ARN" ]; then
    USE_AWS_SECRETS=true
    echo -e "${GREEN}Using AWS Secrets Manager for sensitive configuration.${NC}"
elif [ -z "$DATABASE_URL" ] || [ -z "$JWT_SECRET" ]; then
    echo -e "${RED}Error: Either AWS Secret ARNs (DB_SECRET_ARN, JWT_SECRET_ARN) or direct secrets (DATABASE_URL, JWT_SECRET) must be set in .env.production.${NC}"
    exit 1
fi

# Optional/Defaulted variables
API_S3_BUCKET=${S3_BUCKET:-"ptchampion.ai"}
API_CLOUDFRONT_ID=${CLOUDFRONT_DISTRIBUTION_ID:-"E1FRFF3JQNGRE1"}
API_EC2_HOSTNAME=${EC2_HOSTNAME:-$EC2_IP} # Default hostname to IP if not set

KEY_FILE="ptchampion-key-new.pem"
LOCAL_FRONTEND_PATH="./dist/public" # Output from root vite build
REMOTE_APP_DIR="~/ptchampion-go" # Use a different directory for Go deployment
REMOTE_USER="ec2-user"
IMAGE_NAME=$(basename "$ECR_REPOSITORY_URI") # Extract image name from URI
GO_CONTAINER_NAME="ptchampion-go-backend"
GO_APP_PORT="8080" # Port the Go app listens on inside the container

# Print script banner
echo -e "${GREEN}PT Champion Go/Docker Deployment Script${NC}"
echo "=============================================================="
echo "ECR Repository URI:      $ECR_REPOSITORY_URI"
echo "Target EC2 IP:             $EC2_IP"
echo "Go Container Name:       $GO_CONTAINER_NAME"
echo "Go App Port (Internal):  $GO_APP_PORT"
echo "--------------------------------------------------------------"
echo "Frontend S3 Bucket:        $API_S3_BUCKET"
echo "CloudFront Distribution ID: $API_CLOUDFRONT_ID"
echo "Client Origin (CORS):      $CLIENT_ORIGIN"
echo "--------------------------------------------------------------"
echo "SSH Key File:              $KEY_FILE"
echo "Remote App Directory:      $REMOTE_APP_DIR"
echo "=============================================================="

# Ensure AWS CLI, Docker, jq are installed locally
if ! command -v aws &> /dev/null; then echo -e "${RED}AWS CLI not installed.${NC}"; exit 1; fi
if ! command -v docker &> /dev/null; then echo -e "${RED}Docker not installed.${NC}"; exit 1; fi
if ! command -v jq &> /dev/null; then echo -e "${RED}jq not installed.${NC}"; exit 1; fi
if ! aws sts get-caller-identity &> /dev/null; then echo -e "${RED}AWS CLI not configured. Run 'aws configure'.${NC}"; exit 1; fi
if ! docker info &> /dev/null; then echo -e "${RED}Docker daemon is not running.${NC}"; exit 1; fi

# --- SSH Setup ---
USE_SSH=false
SSH_OPTIONS="-o StrictHostKeyChecking=no -o ConnectTimeout=10"
if [ -f "$KEY_FILE" ]; then
    echo -e "${GREEN}Found SSH key file: $KEY_FILE${NC}"
    chmod 400 "$KEY_FILE"
    USE_SSH=true
else
    echo -e "${YELLOW}SSH key file '$KEY_FILE' not found. Backend deployment steps will be skipped.${NC}"
fi
SSH_CMD="ssh -i $KEY_FILE $SSH_OPTIONS $REMOTE_USER@$EC2_IP"

# --- Helper Functions ---

show_help() {
  echo "Usage: ./deploy-go.sh [OPTIONS]"
  echo ""
  echo "OPTIONS:"
  echo "  --full           Build & deploy Go backend, frontend, update CloudFront."
  echo "  --frontend       Deploy frontend to S3 and invalidate CloudFront."
  echo "  --backend        Build & deploy Go backend to EC2 via Docker."
  echo "  --configure-cf   Update CloudFront API origin and invalidate."
  echo "  --invalidate     Only create a CloudFront invalidation."
  echo "  --test-api       Test API connection (direct and via CloudFront)."
  echo "  --help           Show this help message."
  echo ""
  echo "If no option is specified, '--full' is assumed."
  echo "Note: Backend operations require the SSH key file '$KEY_FILE' and Docker running on EC2."
}

# (Adapted from old script)
create_cloudfront_invalidation() {
  echo -e "${YELLOW}Creating CloudFront invalidation for distribution: $API_CLOUDFRONT_ID${NC}"
  INVALIDATION_ID=$(aws cloudfront create-invalidation --distribution-id "$API_CLOUDFRONT_ID" --paths "/*" "/api/*" --query 'Invalidation.Id' --output text || echo "FAILED")
  if [ "$INVALIDATION_ID" != "FAILED" ] && [ -n "$INVALIDATION_ID" ]; then
    echo -e "${GREEN}Successfully created CloudFront invalidation. ID: $INVALIDATION_ID${NC}"
    echo -e "${YELLOW}Invalidation may take 5-10 minutes to complete.${NC}"
  else
    echo -e "${RED}Failed to create CloudFront invalidation.${NC}"
  fi
}

# (Adapted from old script - uses root build script now)
build_frontend() {
  if [ ! -d "$LOCAL_FRONTEND_PATH" ] || [ ! -f "$LOCAL_FRONTEND_PATH/index.html" ]; then
    echo -e "${YELLOW}Frontend build directory '$LOCAL_FRONTEND_PATH' not found or incomplete. Running build...${NC}"
    # Assuming the root package.json has the correct build script
    if npm run build:client; then
      echo -e "${GREEN}Frontend build successful.${NC}"
    else
      echo -e "${RED}Frontend build failed. Aborting.${NC}"
      exit 1
    fi
  else
    echo -e "${GREEN}Frontend already built in $LOCAL_FRONTEND_PATH.${NC}"
  fi
}

# (Adapted from old script)
deploy_frontend_to_s3() {
  build_frontend
  echo -e "${YELLOW}Syncing frontend files from '$LOCAL_FRONTEND_PATH' to S3 bucket: $API_S3_BUCKET${NC}"
  if aws s3 sync "$LOCAL_FRONTEND_PATH" "s3://$API_S3_BUCKET" --delete --acl public-read; then # Ensure files are public
    echo -e "${GREEN}Successfully synced frontend files to S3.${NC}"
    create_cloudfront_invalidation
  else
    echo -e "${RED}Failed to sync frontend files to S3.${NC}"
    exit 1
  fi
}

# (NEW - Go/Docker specific)
build_and_push_go_image() {
  echo -e "${YELLOW}Building Go Docker image...${NC}"
  # Tag with latest and a timestamp/commit hash for versioning (using date here)
  TIMESTAMP=$(date +%Y%m%d%H%M%S)
  IMAGE_TAG_LATEST="$ECR_REPOSITORY_URI:latest"
  IMAGE_TAG_VERSIONED="$ECR_REPOSITORY_URI:$TIMESTAMP"

  echo -e "${YELLOW}Creating multi-architecture build using buildx...${NC}"
  docker buildx use multiarch || docker buildx create --name multiarch --use
  
  echo -e "${YELLOW}Logging into AWS ECR...${NC}"
  if aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$ECR_REPOSITORY_URI"; then
    echo -e "${GREEN}ECR login successful.${NC}"
  else
    echo -e "${RED}ECR login failed.${NC}"
    exit 1
  fi

  echo -e "${YELLOW}Building and pushing multi-architecture image to ECR...${NC}"
  if docker buildx build --platform linux/amd64,linux/arm64 -t "$IMAGE_TAG_LATEST" -t "$IMAGE_TAG_VERSIONED" --push .; then
    echo -e "${GREEN}Multi-architecture image built and pushed successfully.${NC}"
  else
    echo -e "${RED}Docker buildx build and push failed.${NC}"
    exit 1
  fi
}

# (NEW - Go/Docker specific)
deploy_go_backend() {
  if [ "$USE_SSH" = false ]; then echo -e "${YELLOW}Skipping backend deployment (SSH key missing).${NC}"; return; fi

  echo -e "${YELLOW}Deploying Go backend container to $EC2_IP...${NC}"

  IMAGE_TAG_LATEST="$ECR_REPOSITORY_URI:latest"

  # SSH into EC2 and execute Docker commands
  $SSH_CMD << EOF
set -e # Exit on error within the heredoc

echo 'Logging into AWS ECR on EC2...'
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPOSITORY_URI

echo 'Pulling latest image from ECR...'
docker pull $IMAGE_TAG_LATEST

# Stop and remove existing container if it's running
if [ \$(docker ps -q -f name=$GO_CONTAINER_NAME) ]; then
    echo 'Stopping existing container: $GO_CONTAINER_NAME...'
    docker stop $GO_CONTAINER_NAME
fi
if [ \$(docker ps -aq -f status=exited -f name=$GO_CONTAINER_NAME) ]; then
    echo 'Removing existing container: $GO_CONTAINER_NAME...'
    docker rm $GO_CONTAINER_NAME
fi

echo 'Starting new container: $GO_CONTAINER_NAME...'
if [ "$USE_AWS_SECRETS" = true ]; then
    # Use AWS Secrets Manager - pass ARNs
    docker run -d \\
        --name $GO_CONTAINER_NAME \\
        --restart always \\
        -p $GO_APP_PORT:$GO_APP_PORT \\
        -e PORT=$GO_APP_PORT \\
        -e AWS_REGION='$AWS_REGION' \\
        -e DB_SECRET_ARN='$DB_SECRET_ARN' \\
        -e JWT_SECRET_ARN='$JWT_SECRET_ARN' \\
        -e CLIENT_ORIGIN='$CLIENT_ORIGIN' \\
        $IMAGE_TAG_LATEST
else
    # Use direct secrets
    docker run -d \\
        --name $GO_CONTAINER_NAME \\
        --restart always \\
        -p $GO_APP_PORT:$GO_APP_PORT \\
        -e PORT=$GO_APP_PORT \\
        -e DATABASE_URL='$DATABASE_URL' \\
        -e JWT_SECRET='$JWT_SECRET' \\
        -e CLIENT_ORIGIN='$CLIENT_ORIGIN' \\
        $IMAGE_TAG_LATEST
fi

echo 'Waiting a few seconds for container to start...'
sleep 5

echo 'Checking container status...'
docker ps -f name=$GO_CONTAINER_NAME

# Optional: Prune old unused images to save space
echo 'Pruning old docker images...'
docker image prune -af || echo "Docker prune failed, continuing..."

echo 'Go backend deployment steps completed on EC2.'
EOF

  if [ $? -eq 0 ]; then
      echo -e "${GREEN}Go backend deployed successfully via Docker on EC2.${NC}"
  else
      echo -e "${RED}Failed to deploy Go backend on EC2.${NC}"
      exit 1 # Exit if remote commands failed
  fi
}

# (Adapted from old script - check Nginx config relevance)
# This assumes Nginx is installed and managed by systemd on EC2
configure_nginx_for_go() {
  if [ "$USE_SSH" = false ]; then echo -e "${YELLOW}Skipping Nginx configuration (SSH key missing).${NC}"; return; fi

  echo -e "${YELLOW}Configuring Nginx for Go backend on $EC2_IP...${NC}"

  # Simpler Nginx config that just proxies to the Go app
  NGINX_CONF="server {
    listen 80 default_server;
    server_name _;

    location / {
        return 404;
    }

    # Direct API route
    location /api {
        proxy_pass http://127.0.0.1:$GO_APP_PORT;
        proxy_http_version 1.1;
    }

    # API v1 specific route
    location /api/v1 {
        proxy_pass http://127.0.0.1:$GO_APP_PORT;
        proxy_http_version 1.1;
    }

    # Health check endpoint
    location /health {
        proxy_pass http://127.0.0.1:$GO_APP_PORT;
        proxy_http_version 1.1;
    }
}"

  # SSH into EC2 and execute commands
  $SSH_CMD << EOF
set -e # Exit on error

echo 'Updating Nginx configuration for Go backend...'
echo "$NGINX_CONF" | sudo tee /etc/nginx/conf.d/ptchampion-go.conf > /dev/null

# Remove old Node.js config if it exists
sudo rm -f /etc/nginx/conf.d/ptchampion.conf

echo 'Testing Nginx configuration...'
sudo nginx -t
echo 'Restarting Nginx...'
sudo systemctl restart nginx
EOF

  if [ $? -eq 0 ]; then
      echo -e "${GREEN}Nginx configured successfully for Go backend.${NC}"
  else
      echo -e "${RED}Failed to configure Nginx for Go backend.${NC}"
      # Don't exit here, maybe deployment still worked
  fi
}

# (Adapted from old script - verify logic)
update_cloudfront_origin() {
  echo -e "${YELLOW}Updating CloudFront distribution '$API_CLOUDFRONT_ID' to point API origin to '$API_EC2_HOSTNAME'...${NC}"

  echo "Fetching current CloudFront config..."
  CONFIG_OUTPUT=$(aws cloudfront get-distribution-config --id "$API_CLOUDFRONT_ID" 2>&1)
  if [ $? -ne 0 ]; then echo -e "${RED}Failed to get CloudFront config: $CONFIG_OUTPUT${NC}"; exit 1; fi
  ETAG=$(echo "$CONFIG_OUTPUT" | jq -r '.ETag')
  CURRENT_CONFIG=$(echo "$CONFIG_OUTPUT" | jq '.DistributionConfig')

  if [ -z "$ETAG" ] || [ -z "$CURRENT_CONFIG" ]; then echo -e "${RED}Failed to parse ETag or DistributionConfig.${NC}"; exit 1; fi

  # Find the Origin ID used by the /api* cache behavior
  API_ORIGIN_ID=$(echo "$CURRENT_CONFIG" | jq -r '.CacheBehaviors.Items[]? | select(.PathPattern == "/api/*") | .TargetOriginId' | head -n 1)
  if [ -z "$API_ORIGIN_ID" ]; then
      echo -e "${RED}Error: Could not find cache behavior for '/api/*' in CloudFront config.${NC}"; exit 1;
  fi
  echo "Found API Origin ID: $API_ORIGIN_ID"

  # Check if update is needed (Domain and Cache Policy)
  CURRENT_DOMAIN=$(echo "$CURRENT_CONFIG" | jq -r --arg ID "$API_ORIGIN_ID" '.Origins.Items[]? | select(.Id == $ID) | .DomainName')
  CURRENT_CACHE_POLICY=$(echo "$CURRENT_CONFIG" | jq -r '.CacheBehaviors.Items[]? | select(.PathPattern == "/api/*") | .CachePolicyId')
  DESIRED_CACHE_POLICY="4135ea2d-6df8-44a3-9df3-4b5a84be39ad" # Managed-CachingDisabled

  if [ "$CURRENT_DOMAIN" == "$API_EC2_HOSTNAME" ] && [ "$CURRENT_CACHE_POLICY" == "$DESIRED_CACHE_POLICY" ]; then
    echo -e "${GREEN}CloudFront origin domain and API cache policy are already correct.${NC}"; return 0;
  fi

  echo "Updating CloudFront configuration..."
  UPDATED_CONFIG=$(echo "$CURRENT_CONFIG" | jq \
    --arg ID "$API_ORIGIN_ID" \
    --arg HOSTNAME "$API_EC2_HOSTNAME" \
    --arg CACHE_POLICY "$DESIRED_CACHE_POLICY" '
    (.Origins.Items[] | select(.Id == $ID) | .DomainName) |= $HOSTNAME |
    (.CacheBehaviors.Items[] | select(.PathPattern == "/api/*") | .CachePolicyId) |= $CACHE_POLICY
  ')

  if [ -z "$UPDATED_CONFIG" ]; then echo -e "${RED}Error modifying CloudFront config with jq.${NC}"; exit 1; fi

  CONFIG_FILE=$(mktemp)
  echo "$UPDATED_CONFIG" > "$CONFIG_FILE"

  echo "Applying updated configuration to CloudFront..."
  UPDATE_OUTPUT=$(aws cloudfront update-distribution --id "$API_CLOUDFRONT_ID" --distribution-config "file://$CONFIG_FILE" --if-match "$ETAG" 2>&1)
  rm "$CONFIG_FILE"

  if [ $? -eq 0 ]; then
    echo -e "${GREEN}Successfully submitted CloudFront update request.${NC}"
    create_cloudfront_invalidation
  else
    echo -e "${RED}Failed to update CloudFront distribution:${NC}"; echo "$UPDATE_OUTPUT"; exit 1;
  fi
}

# (Adapted from old script - update ports/paths)
test_api_connection() {
  echo -e "${YELLOW}Testing API connection...${NC}"
  # Assuming your Go app has a /api/health endpoint
  HEALTH_PATH="/api/health"
  # Use http for direct IP, potentially https for domain via CloudFront
  DIRECT_URL="http://$EC2_IP$HEALTH_PATH"
  CF_URL="https://$API_S3_BUCKET$HEALTH_PATH" # Use S3 bucket name assuming it's the domain

  echo "Testing direct connection to EC2: $DIRECT_URL (via Nginx port 80)"
  if curl -sfL -m 10 "$DIRECT_URL"; then
    echo -e "${GREEN}Direct connection to EC2 API (via Nginx) successful.${NC}"
  else
    echo -e "${RED}Direct connection to EC2 API failed. Check Nginx and Go container status on $EC2_IP.${NC}"
    # Add a check directly to the Go app port if possible
    echo "Testing direct connection to Go container port $GO_APP_PORT..."
    if curl -sfL -m 5 "http://$EC2_IP:$GO_APP_PORT/api/health"; then
        echo -e "${GREEN}Direct connection to Go container port $GO_APP_PORT successful.${NC}"
    else
        echo -e "${RED}Direct connection to Go container port $GO_APP_PORT failed.${NC}"
    fi
  fi

  echo "Testing connection via CloudFront: $CF_URL"
  if curl -sfL -m 15 "$CF_URL"; then
    echo -e "${GREEN}Connection via CloudFront successful.${NC}"
  else
    echo -e "${RED}Connection via CloudFront failed.${NC}"
    echo -e "${YELLOW}Check CloudFront config, DNS, and EC2 logs.${NC}"
  fi
}

# --- Main Execution Logic ---

ACTION=${1:-"--full"}

case "$ACTION" in
  --full)
    echo "Starting full deployment (Go Backend + Frontend)..."
    build_and_push_go_image
    deploy_go_backend
    configure_nginx_for_go # Configure Nginx after backend is deployed
    deploy_frontend_to_s3
    update_cloudfront_origin # Update CF origin after backend/nginx should be ready
    test_api_connection
    ;;
  --frontend)
    echo "Starting frontend-only deployment..."
    deploy_frontend_to_s3
    ;;
  --backend)
    if [ "$USE_SSH" = false ]; then echo -e "${RED}Cannot perform backend deployment without SSH key '$KEY_FILE'.${NC}"; exit 1; fi
    echo "Starting Go backend-only deployment..."
    build_and_push_go_image
    deploy_go_backend
    configure_nginx_for_go
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
echo "Application URL: https://$API_S3_BUCKET" # Assuming S3 bucket name is domain
echo "API Endpoint:    https://$API_S3_BUCKET/api"
echo "Direct API URL:  http://$EC2_IP/api (via Nginx)"
echo "Go App Port:     $GO_APP_PORT (on EC2)"
echo "==============================================================" 