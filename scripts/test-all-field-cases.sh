#!/bin/bash

API_URL="https://ptchampion-api-westus.azurewebsites.net/api/v1/auth/login"

echo "Testing all field name combinations..."
echo "====================================="

# Test 1: lowercase (standard JSON convention)
echo -e "\n1. Lowercase fields (email, password):"
curl -s -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -d '{"email":"testuser@ptchampion.ai","password":"TestUser123!"}' | jq -r '.message' | jq

# Test 2: Uppercase (Go struct field names)  
echo -e "\n2. Uppercase fields (Email, Password):"
curl -s -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -d '{"Email":"testuser@ptchampion.ai","Password":"TestUser123!"}' | jq -r '.message' | jq

# Test 3: Mixed case
echo -e "\n3. Mixed case (Email, password):"
curl -s -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -d '{"Email":"testuser@ptchampion.ai","password":"TestUser123!"}' | jq -r '.message' | jq

# Test 4: No Content-Type to see validation error
echo -e "\n4. No Content-Type header (to see validation):"
curl -s -X POST "$API_URL" \
  -d '{"email":"testuser@ptchampion.ai","password":"TestUser123!"}' | jq -r '.message' | jq