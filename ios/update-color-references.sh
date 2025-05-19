#!/bin/bash

# Script to update direct Color references to use AppTheme.GeneratedColors
# This script is used as part of the design system migration

echo "🎨 Updating direct Color references to use AppTheme.GeneratedColors..."

# Directory to process
APP_DIR="ptchampion"

# Common color names to update
declare -a colors=("tacticalCream" "creamDark" "deepOpsGreen" "brassGold" "armyTan" "oliveMist" 
                   "commandBlack" "tacticalGray" "gridlineGray" "inactiveGray")

# Process each file containing Color references
for file in $(grep -l "Color\." $APP_DIR/**/*.swift | grep -v "/Generated/"); do
  
  echo "Processing $file"
  
  # For each color name, update direct references to use AppTheme.GeneratedColors
  for color in "${colors[@]}"; do
    # Get capitalized version for the Generated enum
    capitalized="$(tr '[:lower:]' '[:upper:]' <<< ${color:0:1})${color:1}"
    
    # Replace direct Color.colorName with AppTheme.GeneratedColors.colorName
    sed -i '' "s/Color\.$color/AppTheme\.GeneratedColors\.$color/g" "$file"
    
    # Also make sure we have the PTDesignSystem import
    if ! grep -q "import PTDesignSystem" "$file"; then
      sed -i '' '/^import /h; /^import /!H; $!d; g; s/\(^import [^\n]*\n\)/\1import PTDesignSystem\n/' "$file"
      echo "✅ Added import to $file"
    fi
  done
  
  echo "✅ Updated color references in $file"
done

echo "🎉 Done updating color references. Please build the project to catch any remaining issues."

 