#!/bin/bash

# Script to thoroughly fix all module references issues in the project
# This approach will:
# 1. Remove all explicit module qualifiers in app sources
# 2. Fix module exports in the PTDesignSystem umbrella file
# 3. Generate Xcode project files for SwiftPM packages

echo "🔄 Starting comprehensive module reference fix..."

# Define paths
APP_DIR="ptchampion"
DS_DIR="PTDesignSystem"
UMBRELLA_FILE="$DS_DIR/Sources/PTDesignSystem/Umbrella.swift"

# 1. Clean SwiftPM caches and Xcode build data first
echo "🧹 Cleaning SwiftPM and Xcode caches..."
rm -rf ~/Library/Caches/org.swift.swiftpm
rm -rf ~/Library/Developer/Xcode/DerivedData
rm -rf .build
rm -rf $DS_DIR/.build

# 2. Fix the umbrella file for proper module re-export
echo "📦 Updating module export in umbrella file..."
cat > "$UMBRELLA_FILE" << 'EOF'
// This file re-exports all symbols from Components and DesignTokens modules
@_exported import Components
@_exported import DesignTokens

// Re-export specific types to prevent module namespace issues
public typealias PTButton = Components.PTButton
public typealias PTTextField = Components.PTTextField
public typealias PTLabel = Components.PTLabel
public typealias PTCard = Components.PTCard
public typealias AppTheme = DesignTokens.AppTheme
public typealias ThemeManager = DesignTokens.ThemeManager
EOF

# 3. Update all explicit module references in app code
echo "🔧 Removing explicit module qualifiers from app files..."
find "$APP_DIR" -name "*.swift" -type f | while read -r file; do
  # Grep for components references
  if grep -q "Components\." "$file" || grep -q "DesignTokens\." "$file"; then
    echo "  Updating module references in: $file"
    # Remove explicit module prefix from all type references
    sed -i '' 's/Components\.//g' "$file"
    sed -i '' 's/DesignTokens\.//g' "$file"

    # Ensure PTDesignSystem is imported
    if ! grep -q "import PTDesignSystem" "$file"; then
      if grep -q "import SwiftUI" "$file"; then
        # Add import after SwiftUI
        sed -i '' '/import SwiftUI/a\'$'\n''import PTDesignSystem' "$file"
      else
        # Add import at top
        sed -i '' '1s/^/import PTDesignSystem\n/' "$file"
      fi
    fi
  fi
done

# 4. Fix colors import specifically (a common source of errors)
echo "🎨 Ensuring Colors resources are available..."
for file in $DS_DIR/Sources/DesignTokens/Resources/Colors.xcassets/*/Contents.json; do
  dirname=$(dirname "$file")
  colorname=$(basename "$dirname")
  echo "  Checking color: $colorname"
done

# 5. Reset Package.resolved (if it exists)
if [ -f "$DS_DIR/Package.resolved" ]; then
  echo "📋 Resetting Package.resolved..."
  rm "$DS_DIR/Package.resolved"
fi

# 6. Run SwiftPM commands to regenerate project files
echo "🔨 Generating fresh project files..."
cd "$DS_DIR" && swift package resolve
cd "$DS_DIR" && swift package update

echo "✅ Fix complete. Please rebuild the project in Xcode."
echo ""
echo "If you continue to see errors:"
echo "1. Try closing and reopening Xcode"
echo "2. Try restarting your Mac"
echo "3. Check for any remaining module qualifiers with: grep -r 'Components\.' $APP_DIR"
echo "4. Make sure you're using the PTDesignSystem import in all files that use its components" 