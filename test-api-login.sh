#!/bin/bash
set -e

echo "🔍 Testing API login endpoint directly..."

# API endpoint
API_URL="https://ptchampion-api-westus.azurewebsites.net/api/v1/auth/login"

# Test credentials
EMAIL="testuser@ptchampion.ai"
PASSWORD="TestUser123!"

# Create the JSON payload
PAYLOAD=$(cat <<EOF
{
  "email": "${EMAIL}",
  "password": "${PASSWORD}"
}
EOF
)

echo "📤 Request details:"
echo "   URL: ${API_URL}"
echo "   Payload: ${PAYLOAD}"
echo ""

# Make the request with verbose output
echo "📥 Making request..."
RESPONSE=$(curl -X POST "${API_URL}" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -H "Origin: https://ptchampion.ai" \
  -d "${PAYLOAD}" \
  -w "\n\nHTTP Status: %{http_code}\n" \
  -s)

echo "📥 Response:"
echo "${RESPONSE}"

# Also try with curl verbose mode for debugging
echo -e "\n\n🔍 Detailed request/response (with headers):"
curl -X POST "${API_URL}" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -H "Origin: https://ptchampion.ai" \
  -d "${PAYLOAD}" \
  -v 2>&1 | grep -E "^(>|<|{|\*)"