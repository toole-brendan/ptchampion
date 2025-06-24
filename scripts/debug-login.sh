#!/bin/bash

echo "Testing PTChampion API Login Endpoint"
echo "====================================="

API_URL="https://ptchampion-api-westus.azurewebsites.net/api/v1"

# Test 1: Health check
echo -e "\n1. Testing API health:"
curl -s "$API_URL/health" | jq

# Test 2: Try with mock user
echo -e "\n2. Testing login with mock user (lowercase fields):"
curl -s -X POST "$API_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"mock@example.com","password":"mockpassword"}' | jq -r '.message' | jq

# Test 3: Try with test user  
echo -e "\n3. Testing login with test user (lowercase fields):"
curl -s -X POST "$API_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"testuser@ptchampion.ai","password":"TestUser123!"}' | jq -r '.message' | jq

# Test 4: Try with bad JSON to see error format
echo -e "\n4. Testing with malformed JSON:"
curl -s -X POST "$API_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{invalid json}' | jq -r '.message' | jq 2>/dev/null || echo "Failed to parse"

# Test 5: Try without content-type header
echo -e "\n5. Testing without Content-Type header:"
curl -s -X POST "$API_URL/auth/login" \
  -d '{"email":"mock@example.com","password":"mockpassword"}' | jq -r '.message' | jq 2>/dev/null || echo "Failed to parse"