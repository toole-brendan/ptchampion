#!/bin/bash
set -e

echo "🔍 Checking backend container status and logs..."

# Check if the container is running
echo "📦 Checking container status..."
az webapp show --name ptchampion-api-westus --resource-group ptchampion-rg --query "state" -o tsv

# Get recent logs
echo -e "\n📋 Recent backend logs:"
az webapp log download --name ptchampion-api-westus --resource-group ptchampion-rg --log-file backend-logs.zip

# Extract and show relevant logs
unzip -q backend-logs.zip -d backend-logs-temp
echo -e "\n🔍 Searching for authentication-related errors..."
grep -i "auth\|login\|401\|unauthorized\|testuser" backend-logs-temp/LogFiles/*.txt | tail -20 || echo "No auth-related entries found"

# Clean up
rm -rf backend-logs-temp backend-logs.zip

echo -e "\n💡 To view live logs, run:"
echo "az webapp log tail --name ptchampion-api-westus --resource-group ptchampion-rg"