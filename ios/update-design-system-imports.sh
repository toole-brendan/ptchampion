#!/bin/bash

# Script to add PTDesignSystem import to all Swift files that use AppTheme
# This script is used as part of the design system migration

echo "🎨 Adding PTDesignSystem imports to Swift files..."

# Directory to process
APP_DIR="ptchampion"

# Find all Swift files that reference AppTheme but don't import PTDesignSystem
for file in $(grep -l "AppTheme" $APP_DIR/**/*.swift | grep -v "/Generated/"); do
  # Check if file already imports PTDesignSystem
  if ! grep -q "import PTDesignSystem" "$file"; then
    echo "Processing $file"
    # Add the import after the last import statement
    sed -i '' '/^import /h; /^import /!H; $!d; g; s/\(^import [^\n]*\n\)/\1import PTDesignSystem\n/' "$file"
    echo "✅ Added import to $file"
  else
    echo "⏭️  Skipping $file (already has import)"
  fi
done

echo "🎉 Done adding imports. Please build the project to catch any remaining issues." 