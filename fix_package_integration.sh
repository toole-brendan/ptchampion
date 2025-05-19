#!/bin/bash

# Exit on any error
set -e

WORKSPACE_DIR="$(pwd)/ptchampion"
DESIGN_SYSTEM_PATH="$(pwd)/PTDesignSystem"
XCODE_PROJECT="ptchampion.xcodeproj"
XCODE_WORKSPACE="ptchampion.xcworkspace"

echo "🔄 Fixing Swift Package Manager integration issues..."

# 1. First fix the Swift tools version in Package.swift if needed
if grep -q "swift-tools-version:5.9" "$DESIGN_SYSTEM_PATH/Package.swift"; then
  echo "⚠️ Found Swift 5.9 tools version, downgrading to 5.8 for compatibility with Xcode 14..."
  sed -i '' 's/swift-tools-version:5.9/swift-tools-version:5.8/' "$DESIGN_SYSTEM_PATH/Package.swift"
  echo "✅ Updated Swift tools version to 5.8"
else
  echo "✅ Swift tools version is compatible"
fi

# 2. Update the workspace to include the PTDesignSystem package
echo "📦 Updating workspace to include PTDesignSystem package..."
cat > "$WORKSPACE_DIR/$XCODE_WORKSPACE/contents.xcworkspacedata" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<Workspace
   version = "1.0">
   <FileRef
      location = "group:ptchampion.xcodeproj">
   </FileRef>
   <FileRef
      location = "group:Pods/Pods.xcodeproj">
   </FileRef>
   <FileRef
      location = "group:../PTDesignSystem">
   </FileRef>
</Workspace>
EOF
echo "✅ Updated workspace configuration"

# 3. Install pod dependencies
echo "📦 Installing CocoaPods dependencies..."
cd "$WORKSPACE_DIR"
pod install

echo "✅ Package integration fixes completed successfully!"
echo ""
echo "Next steps:"
echo "1. Open the workspace in Xcode: open ptchampion.xcworkspace"
echo "2. In Xcode, go to your app target > General > Frameworks, Libraries, and Embedded Content"
echo "3. Click the + button and add PTDesignSystem, Components, and DesignTokens libraries"
echo "4. Clean the project (Cmd+Shift+K) and rebuild"
echo "" 