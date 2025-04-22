#!/bin/bash
# PT Champion Deployment Verification Script
# This script checks if the frontend and backend are properly connected

set -e  # Exit on any error

# Configuration
BACKEND_URL="https://ptchampion-api-westus.azurewebsites.net"
FRONTEND_URL="https://www.ptchampion.ai"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to display status messages
status() {
  echo -e "${GREEN}[INFO]${NC} $1"
}

# Function to display warning messages
warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Function to display error messages
error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if a URL is accessible
check_url() {
  status "Checking $1..."
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" $1)
  if [ $HTTP_CODE -eq 200 ]; then
    status "✅ $1 is accessible (HTTP $HTTP_CODE)"
    return 0
  else
    warning "⚠️ $1 returned HTTP $HTTP_CODE"
    return 1
  fi
}

# Function to check CORS preflight
check_cors() {
  status "Testing CORS preflight from $FRONTEND_URL to $BACKEND_URL/health..."
  CORS_TEST=$(curl -s -I -X OPTIONS \
    -H "Origin: $FRONTEND_URL" \
    -H "Access-Control-Request-Method: GET" \
    -H "Access-Control-Request-Headers: Content-Type" \
    "${BACKEND_URL}/health" | grep -i "access-control-allow-origin")
  
  if [ -n "$CORS_TEST" ]; then
    status "✅ CORS is properly configured:"
    echo "$CORS_TEST"
    return 0
  else
    warning "⚠️ CORS preflight test failed. No Access-Control-Allow-Origin header found."
    return 1
  fi
}

status "==============================================="
status "PT Champion Deployment Verification"
status "==============================================="

# Check if frontend is accessible first
status "Checking frontend accessibility..."
check_url "$FRONTEND_URL" || FRONTEND_FAIL=true

# Check if backend is accessible
status "Checking backend health endpoint..."
check_url "$BACKEND_URL/health" || BACKEND_FAIL=true

# Check for static assets
status "Checking for critical frontend assets..."
check_url "$FRONTEND_URL/index.html" || ASSETS_FAIL=true
check_url "$FRONTEND_URL/assets/index-*.js" 2>/dev/null || ASSETS_FAIL=true

# Test CORS configuration
check_cors || CORS_FAIL=true

# Final summary
echo ""
status "==============================================="
status "Verification Summary"
status "==============================================="

if [ "$BACKEND_FAIL" = true ]; then
  error "❌ Backend is not accessible or not healthy"
  echo "   - Check if the App Service is running"
  echo "   - Verify health endpoint is implemented"
  echo "   - Check Azure App Service logs"
else
  status "✅ Backend is accessible and healthy"
fi

if [ "$FRONTEND_FAIL" = true ]; then
  error "❌ Frontend is not accessible"
  echo "   - Check if the Storage Account static website is enabled"
  echo "   - Verify Front Door is configured properly"
  echo "   - Check if all files were deployed correctly"
else
  status "✅ Frontend is accessible"
fi

if [ "$ASSETS_FAIL" = true ]; then
  warning "⚠️ Some frontend assets may be missing"
  echo "   - Verify all files were built and deployed correctly"
  echo "   - Check browser console for 404 errors"
else
  status "✅ Frontend assets are accessible"
fi

if [ "$CORS_FAIL" = true ]; then
  error "❌ CORS is not configured correctly"
  echo "   - Check if your backend CORS configuration includes $FRONTEND_URL"
  echo "   - Verify that OPTIONS preflight requests are handled correctly"
  echo "   - Check for appropriate Access-Control-Allow-* headers"
else
  status "✅ CORS is properly configured"
fi

echo ""
status "Next steps if there are issues:"
echo "1. For backend issues, check logs: az webapp log tail --name ptchampion-api-westus --resource-group ptchampion-rg"
echo "2. For frontend issues, verify the Azure Storage blob contents"
echo "3. For CORS issues, update the CORS configuration in internal/api/middleware/security.go"
echo "4. Redeploy using the deploy-to-azure.sh script"
echo ""
