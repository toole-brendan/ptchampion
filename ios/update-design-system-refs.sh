#!/bin/bash

# Script to update namespace references to design system
# This ensures the proper module qualifiers are used

echo "🔄 Updating design system references to use proper module qualifiers..."

# Directory to process
APP_DIR="ptchampion"

# Update references from DesignTokens.ThemeManager to ThemeManager
for file in $(grep -l "DesignTokens\.ThemeManager" $APP_DIR/**/*.swift | grep -v "/Generated/"); do
  echo "Processing $file for ThemeManager references"
  sed -i '' 's/DesignTokens\.ThemeManager/ThemeManager/g' "$file"
  echo "✅ Updated ThemeManager references in $file"
done

# Update references from DesignTokens.AppTheme to AppTheme
for file in $(grep -l "DesignTokens\.AppTheme" $APP_DIR/**/*.swift | grep -v "/Generated/"); do
  echo "Processing $file for AppTheme references"
  sed -i '' 's/DesignTokens\.AppTheme/AppTheme/g' "$file"
  echo "✅ Updated AppTheme references in $file"
done

# Update references to components used from the app instead of design system
for file in $(grep -l "Components\.PT" $APP_DIR/**/*.swift | grep -v "/Generated/"); do
  echo "Processing $file for Components references"
  sed -i '' 's/Components\.PT/PT/g' "$file"
  echo "✅ Updated Components references in $file"
done

echo "🎉 Done updating references. Please build the project to catch any remaining issues." 