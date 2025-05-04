#!/bin/bash

# Script to replace app-specific component references with design system components
# This ensures the PTDesignSystem is the source of truth

echo "🔄 Replacing app-specific component references with design system components..."

# Directory to process
APP_DIR="ptchampion"

# List of component name mappings (app -> design system)
COMPONENT_MAPPINGS=(
  "AppPTLabel:PTLabel"
  "AppPTButton:PTButton"
  "AppPTTextField:PTTextField"
  "AppPTCard:PTCard"
  "AppPTSeparator:PTSeparator"
)

# Process all Swift files directly
echo "🔧 Scanning all Swift files for component references..."
find "$APP_DIR" -name "*.swift" -type f | while read -r file; do
  echo "  Checking $file"
  
  # Apply all component replacements to each file
  for mapping in "${COMPONENT_MAPPINGS[@]}"; do
    app_component="${mapping%%:*}"
    ds_component="${mapping##*:}"
    
    # Check if the file contains the app component
    if grep -q "$app_component" "$file"; then
      echo "    Replacing $app_component with $ds_component"
      sed -i '' "s/$app_component/$ds_component/g" "$file"
    fi
  done
  
  # Add import if PT components are used but import is missing
  if grep -q "PT[A-Za-z]\+" "$file" && ! grep -q "import PTDesignSystem" "$file"; then
    echo "    Adding missing PTDesignSystem import"
    sed -i '' '1s/^/import SwiftUI\nimport PTDesignSystem\n/' "$file"
  fi
done

echo "🎉 Done replacing component references. Please build the project to catch any remaining issues." 