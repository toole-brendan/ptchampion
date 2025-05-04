#!/bin/bash

# Script to fix PTButton parameter references
# Design system PTButton uses unnamed first parameter, not 'title:'

echo "🔄 Fixing PTButton parameter references..."

# Directory to process
APP_DIR="ptchampion"

# Find all Swift files with PTButton calls
echo "🔧 Scanning Swift files for PTButton parameter references..."

find "$APP_DIR" -name "*.swift" -type f | while read -r file; do
  # Check if the file contains PTButton with title: parameter
  if grep -q "PTButton(title:" "$file"; then
    echo "  Fixing PTButton parameters in $file"
    
    # Replace PTButton(title: "Text" with PTButton("Text"
    sed -i '' 's/PTButton(title: \("[^"]*"\)/PTButton(\1/g' "$file"
    
    # Handle cases with single quotes if any
    sed -i '' "s/PTButton(title: \('[^']*'\)/PTButton(\1/g" "$file"
    
    echo "  ✅ Fixed PTButton parameters in $file"
  fi
done

echo "🎉 Done fixing PTButton parameters. Please build the project to catch any remaining issues." 