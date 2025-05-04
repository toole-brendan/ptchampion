#!/bin/bash

# Script to update AppTheme references to use the new Generated format
# This script is used as part of the design system migration

echo "🔄 Updating AppTheme references to use Generated format..."

# Directory to process
APP_DIR="ptchampion"

# Update common style references
for file in $(grep -l "AppTheme\." $APP_DIR/**/*.swift | grep -v "/Generated/"); do
  echo "Processing $file"
  
  # Colors references
  sed -i '' 's/AppTheme\.Colors\./AppTheme\.GeneratedColors\./g' "$file"
  sed -i '' 's/AppTheme\.colors\./AppTheme\.GeneratedColors\./g' "$file"
  
  # Spacing references
  sed -i '' 's/AppTheme\.Spacing\./AppTheme\.GeneratedSpacing\./g' "$file"
  sed -i '' 's/AppTheme\.spacing\./AppTheme\.GeneratedSpacing\./g' "$file"
  
  # Typography references
  sed -i '' 's/AppTheme\.Typography\./AppTheme\.GeneratedTypography\./g' "$file"
  sed -i '' 's/AppTheme\.typography\./AppTheme\.GeneratedTypography\./g' "$file"
  
  # Radius references
  sed -i '' 's/AppTheme\.Radius\./AppTheme\.GeneratedRadius\./g' "$file"
  sed -i '' 's/AppTheme\.radius\./AppTheme\.GeneratedRadius\./g' "$file"
  
  # Shadow references
  sed -i '' 's/AppTheme\.Shadows\./AppTheme\.GeneratedShadows\./g' "$file"
  sed -i '' 's/AppTheme\.shadows\./AppTheme\.GeneratedShadows\./g' "$file"
  
  echo "✅ Updated references in $file"
done

echo "🎉 Done updating references. Please build the project to catch any remaining issues." 