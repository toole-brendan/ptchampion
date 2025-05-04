#!/bin/bash

# Script to fix imports in design system components
# This ensures all components import the correct modules

echo "🔄 Fixing imports in design system components..."

# Directory to process
DS_DIR="PTDesignSystem"
COMPONENTS_DIR="$DS_DIR/Sources/Components"
DESIGN_TOKENS_DIR="$DS_DIR/Sources/DesignTokens"

# Make sure components import DesignTokens
for file in $COMPONENTS_DIR/*.swift; do
  if ! grep -q "import DesignTokens" "$file"; then
    echo "Adding DesignTokens import to $file"
    sed -i '' '1s/^/import DesignTokens\n/' "$file"
    echo "✅ Added DesignTokens import to $file"
  else
    echo "⏭️  Skipping $file (already has import)"
  fi
done

# Make sure DesignTokens import SwiftUI
for file in $DESIGN_TOKENS_DIR/*.swift; do
  if ! grep -q "import SwiftUI" "$file"; then
    echo "Adding SwiftUI import to $file"
    sed -i '' '1s/^/import SwiftUI\n/' "$file"
    echo "✅ Added SwiftUI import to $file"
  else
    echo "⏭️  Skipping $file (already has import)"
  fi
done

# Make sure components have public initializers
for file in $COMPONENTS_DIR/*.swift; do
  echo "Making initializers public in $file"
  # Find initializers that aren't marked public and add public modifier
  sed -i '' 's/init(/public init(/g' "$file"
  echo "✅ Updated initializers in $file"
done

echo "🎉 Done fixing imports. Please build the project to catch any remaining issues." 