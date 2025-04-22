#!/bin/bash
# Script to package and upload debugging tools to both Azure Storage accounts

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

# Check if az is installed
if ! command -v az &> /dev/null; then
  error "Azure CLI is not installed. Please install it and try again."
  exit 1
fi

# Check if logged in to Azure
status "Checking Azure login..."
az account show > /dev/null 2>&1 || { 
  error "Not logged in to Azure. Please run 'az login' first."
  exit 1
}

# Create debug directory
status "Creating debug tools directory..."
mkdir -p debug_tools

# Copy files to the debug directory
status "Preparing debug tools..."
cp api-connectivity-test.html debug_tools/index.html
cp DEPLOYMENT_DEBUG_GUIDE.md debug_tools/guide.md

# Generate HTML version of the debugging guide
status "Converting guide to HTML..."
cat > debug_tools/guide.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PT Champion: Azure Deployment Debug Guide</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Arial, sans-serif;
            line-height: 1.6;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            background-color: #F4F1E6;
            color: #1E1E1E;
        }
        h1, h2, h3, h4 {
            color: #1E241E;
        }
        pre {
            background-color: #f5f5f5;
            padding: 10px;
            border-radius: 5px;
            overflow-x: auto;
        }
        code {
            font-family: Consolas, Monaco, 'Andale Mono', monospace;
            background-color: #f5f5f5;
            padding: 2px 4px;
            border-radius: 3px;
        }
        ul, ol {
            padding-left: 25px;
        }
        .container {
            background-color: white;
            padding: 20px;
            border-radius: 10px;
            box-shadow: 0 0 10px rgba(0,0,0,0.1);
            margin-bottom: 20px;
        }
        .success {
            color: #155724;
        }
        .failure {
            color: #721c24;
        }
    </style>
</head>
<body>
    <div class="container">
        <div id="content"></div>
    </div>
    
    <script src="https://cdn.jsdelivr.net/npm/marked/marked.min.js"></script>
    <script>
        // Fetch and render the markdown file
        fetch('guide.md')
            .then(response => response.text())
            .then(markdown => {
                document.getElementById('content').innerHTML = marked.parse(markdown);
            })
            .catch(error => {
                console.error('Error loading markdown:', error);
                document.getElementById('content').innerHTML = '<p>Error loading guide. Please try again later.</p>';
            });
    </script>
</body>
</html>
EOF

# Create a simple index file to link both tools
status "Creating index page..."
cat > debug_tools/tools.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PT Champion Deployment Tools</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Arial, sans-serif;
            line-height: 1.6;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            background-color: #F4F1E6;
            color: #1E1E1E;
        }
        h1, h2 {
            color: #1E241E;
        }
        .container {
            background-color: white;
            padding: 20px;
            border-radius: 10px;
            box-shadow: 0 0 10px rgba(0,0,0,0.1);
            margin-bottom: 20px;
        }
        .card {
            border: 1px solid #ddd;
            border-radius: 8px;
            padding: 20px;
            margin-bottom: 20px;
            background-color: #f9f9f9;
        }
        a.button {
            display: inline-block;
            background-color: #BFA24D;
            color: #1E241E;
            text-decoration: none;
            padding: 10px 15px;
            border-radius: 5px;
            font-weight: bold;
            margin-top: 10px;
        }
        a.button:hover {
            opacity: 0.9;
        }
    </style>
</head>
<body>
    <h1>PT Champion Deployment Tools</h1>
    
    <div class="container">
        <div class="card">
            <h2>API Connectivity Test Tool</h2>
            <p>Use this interactive tool to test connectivity to your backend API and diagnose specific API issues.</p>
            <a href="index.html" class="button">Open API Test Tool</a>
        </div>
        
        <div class="card">
            <h2>Deployment Debug Guide</h2>
            <p>Comprehensive guide for troubleshooting deployment issues with your PT Champion application on Azure.</p>
            <a href="guide.html" class="button">View Debug Guide</a>
        </div>
    </div>
</body>
</html>
EOF

# Create a redirect file to help users find debug tools
status "Creating redirect page..."
cat > debug_tools/find-tools.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PT Champion Debug Tools Finder</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Arial, sans-serif;
            line-height: 1.6;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            background-color: #F4F1E6;
            color: #1E1E1E;
            text-align: center;
        }
        h1 {
            color: #1E241E;
            margin-bottom: 30px;
        }
        .container {
            background-color: white;
            padding: 20px;
            border-radius: 10px;
            box-shadow: 0 0 10px rgba(0,0,0,0.1);
            margin-bottom: 20px;
        }
        .links {
            display: flex;
            flex-direction: column;
            gap: 15px;
            margin-top: 30px;
        }
        a.button {
            display: inline-block;
            background-color: #BFA24D;
            color: #1E241E;
            text-decoration: none;
            padding: 15px 20px;
            border-radius: 5px;
            font-weight: bold;
            margin: 5px;
            font-size: 16px;
        }
        a.button:hover {
            opacity: 0.9;
        }
        .storage-account {
            margin-top: 30px;
            padding: 15px;
            background-color: #f9f9f9;
            border-radius: 5px;
            margin-bottom: 20px;
        }
        .storage-account h2 {
            margin-top: 0;
        }
    </style>
</head>
<body>
    <h1>PT Champion Debug Tools Finder</h1>
    
    <div class="container">
        <p>This page will help you locate the debug tools, regardless of which storage account is hosting them.</p>
        
        <div class="storage-account">
            <h2>Storage Account: ptchampionweb</h2>
            <div class="links">
                <a href="https://ptchampionweb.z13.web.core.windows.net/debug/tools.html" class="button">Try Debug Tools (ptchampionweb)</a>
            </div>
        </div>
        
        <div class="storage-account">
            <h2>Storage Account: ptchampionwebstorage</h2>
            <div class="links">
                <a href="https://ptchampionwebstorage.z13.web.core.windows.net/debug/tools.html" class="button">Try Debug Tools (ptchampionwebstorage)</a>
            </div>
        </div>
        
        <div class="storage-account">
            <h2>Custom Domain</h2>
            <div class="links">
                <a href="https://www.ptchampion.ai/debug/tools.html" class="button">Try Debug Tools (ptchampion.ai)</a>
            </div>
        </div>
        
        <p style="margin-top: 30px;">If none of these links work, please follow the manual upload instructions to deploy the debug tools to your Azure Storage account.</p>
    </div>
</body>
</html>
EOF

# Create a zip file for manual upload
status "Creating zip file..."
if command -v zip &> /dev/null; then
    zip -r ptchampion_debug_tools.zip debug_tools/
else
    tar -czvf ptchampion_debug_tools.tar.gz debug_tools/
fi

# Array of storage accounts
STORAGE_ACCOUNTS=("ptchampionweb" "ptchampionwebstorage")

# Try uploading to both storage accounts
for ACCOUNT in "${STORAGE_ACCOUNTS[@]}"; do
    status "Attempting to upload to $ACCOUNT..."
    
    # Try to get the storage account key
    STORAGE_KEY=$(az storage account keys list --account-name $ACCOUNT --query "[0].value" -o tsv 2>/dev/null)
    
    if [ -n "$STORAGE_KEY" ]; then
        status "Using storage account key for $ACCOUNT..."
        az storage blob upload-batch \
          --account-name $ACCOUNT \
          --account-key "$STORAGE_KEY" \
          --source debug_tools \
          --destination '$web/debug' \
          --overwrite

        if [ $? -eq 0 ]; then
            status "✅ Successfully uploaded to $ACCOUNT!"
            # Try to get the website URL
            WEBSITE_URL=$(az storage account show -n $ACCOUNT --query "primaryEndpoints.web" -o tsv 2>/dev/null | sed 's/\/$//g')
            if [ -n "$WEBSITE_URL" ]; then
                status "Debug tools should be available at: ${WEBSITE_URL}/debug/tools.html"
            fi
        else
            warning "Failed to upload to $ACCOUNT. Trying next one..."
        fi
    else
        warning "Could not retrieve storage key for $ACCOUNT. Trying next one..."
    fi
done

status "✅ Debug tools package created: ptchampion_debug_tools.zip"
status "----------------------------------------------------------------------------------------"
status "MANUAL UPLOAD INSTRUCTIONS:"
status "1. Go to Azure Portal (https://portal.azure.com)"
status "2. Determine which storage account hosts your website (ptchampionweb or ptchampionwebstorage)"
status "3. Navigate to that storage account"
status "4. Select 'Containers' and find the '\$web' container"
status "5. Create a new directory called 'debug'"
status "6. Upload all files from the debug_tools directory to this 'debug' folder"
status "7. After upload, try accessing your debug tools at:"
status "   https://www.ptchampion.ai/debug/tools.html"
status "   OR"
status "   https://ptchampionweb.z13.web.core.windows.net/debug/tools.html"
status "   OR"
status "   https://ptchampionwebstorage.z13.web.core.windows.net/debug/tools.html"
status "----------------------------------------------------------------------------------------"
status "The debug_tools directory has been left intact for your reference."
