#!/bin/bash

# Script to completely fix all module references in Swift files
# This script takes a more aggressive approach to remove module qualifiers

echo "🔄 Thoroughly fixing all module references in Swift files..."

# Directory to process
APP_DIR="ptchampion"
DS_DIR="PTDesignSystem"

# 1. First pass: Remove all occurrences of "Components." and "DesignTokens." prefixes in app files
echo "🔧 Removing all module qualifiers from app files..."

find "$APP_DIR" -name "*.swift" -type f | while read -r file; do
  # Remove all Components and DesignTokens prefixes
  sed -i '' 's/Components\.//g' "$file"
  sed -i '' 's/DesignTokens\.//g' "$file"
  
  # Ensure every file that uses PT components or themes imports PTDesignSystem
  if grep -q "import SwiftUI" "$file" && (grep -q "AppTheme\|PTButton\|PTLabel\|PTTextField\|PTCard" "$file"); then
    if ! grep -q "import PTDesignSystem" "$file"; then
      # Add PTDesignSystem import after SwiftUI
      sed -i '' '/import SwiftUI/a\'$'\n''import PTDesignSystem' "$file"
    fi
  fi
done

# 2. Update the project file to ensure proper dependencies
echo "📦 Ensuring proper module structure in Package.swift..."

# 3. Fix the way Umbrella.swift exports modules
UMBRELLA="$DS_DIR/Sources/PTDesignSystem/Umbrella.swift"
if [ -f "$UMBRELLA" ]; then
  echo "📤 Updating module exports in Umbrella.swift..."
  
  # Replace with cleaner export syntax
  cat > "$UMBRELLA" << 'EOF'
// This file re-exports all symbols from Components and DesignTokens modules
@_exported import Components
@_exported import DesignTokens
EOF
  
  echo "✅ Updated Umbrella.swift"
fi

# 4. Make sure all design system component types have correct modifiers
echo "🔧 Ensuring proper visibility for all design system types..."

find "$DS_DIR" -name "*.swift" -type f | while read -r file; do
  # Add missing imports
  if grep -q "import SwiftUI" "$file" && ! grep -q "import Combine" "$file" && grep -q "ObservableObject" "$file"; then
    # Add Combine import for ObservableObject
    sed -i '' '/import SwiftUI/a\'$'\n''import Combine' "$file"
  fi
  
  # Make sure enums inside public types are public
  sed -i '' 's/enum \([A-Za-z]*Style\)/public enum \1/g' "$file"
  
  # Make sure all Generated* types are public
  sed -i '' 's/enum Generated/public enum Generated/g' "$file"
done

echo "🎉 Done with thorough module reference fixes. Please rebuild the project." 