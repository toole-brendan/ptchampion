#!/bin/bash
# Script to package debugging tools for manual upload to Azure Storage

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to display status messages
status() {
  echo -e "${GREEN}[INFO]${NC} $1"
}

# Function to display error messages
error() {
  echo -e "${RED}[ERROR]${NC} $1"
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

# Create a zip file for manual upload
status "Creating debug_tools.zip..."
if command -v zip &> /dev/null; then
    zip -r debug_tools.zip debug_tools/
    ZIP_EXIT_CODE=$?
else
    # If zip command is not available, try using tar
    tar -czvf debug_tools.zip debug_tools/
    ZIP_EXIT_CODE=$?
fi

if [ $ZIP_EXIT_CODE -eq 0 ]; then
    status "✅ Debug tools package created successfully!"
    status "The package is available at: $(pwd)/debug_tools.zip"
    status "----------------------------------------------------------------------------------------"
    status "MANUAL UPLOAD INSTRUCTIONS:"
    status "1. Go to Azure Portal (https://portal.azure.com)"
    status "2. Navigate to your Storage Account (ptchampionweb)"
    status "3. Select 'Containers' and find the '\$web' container"
    status "4. Create a new directory called 'debug'"
    status "5. Upload all files from the debug_tools directory to this 'debug' folder"
    status "6. After upload, your debug tools will be available at:"
    status "   https://www.ptchampion.ai/debug/tools.html"
    status "----------------------------------------------------------------------------------------"
else
    error "Failed to create the zip file."
    error "Please manually create a zip file of the debug_tools directory."
fi

# Don't remove the directory yet so user can manually upload if needed
status "Note: The debug_tools directory has been left intact for your reference."
