#!/bin/bash

echo "🔧 Starting SPM and CocoaPods fix script..."
echo "Current directory: $(pwd)"
echo ""

# 1. Fix the Swift tools version in Package.swift if needed
if grep -q "swift-tools-version:5.9" "PTDesignSystem/Package.swift"; then
  echo "⚠️ Found Swift 5.9 tools version, downgrading to 5.8 for compatibility with Xcode 14..."
  sed -i '' 's/swift-tools-version:5.9/swift-tools-version:5.8/' "PTDesignSystem/Package.swift"
  echo "✅ Updated Swift tools version to 5.8"
else
  echo "✅ Swift tools version already compatible"
fi

# 2. Update the Podfile to include GoogleSignIn if needed
if ! grep -q "GoogleSignIn" "ptchampion/Podfile"; then
  echo "📦 Adding GoogleSignIn to Podfile..."
  sed -i '' '/pod '"'"'MediaPipeTasksVision'"'"'/a\\  pod '"'"'GoogleSignIn'"'"', '"'"'~> 7.0.0'"'"'' "ptchampion/Podfile"
  echo "✅ Added GoogleSignIn to Podfile"
else
  echo "✅ GoogleSignIn already in Podfile"
fi

# 3. Update the workspace to include the PTDesignSystem package
echo "📦 Updating workspace to include PTDesignSystem package..."
cat > "ptchampion/ptchampion.xcworkspace/contents.xcworkspacedata" << EOF
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

# 4. Install pod dependencies
echo "📦 Installing CocoaPods dependencies..."
cd ptchampion
pod install
cd ..

echo "✅ Package integration fixes completed successfully!"
echo ""
echo "Next steps:"
echo "1. Open the workspace in Xcode: open ptchampion/ptchampion.xcworkspace"
echo "2. In Xcode, go to your app target > General > Frameworks, Libraries, and Embedded Content"
echo "3. Click the + button and add PTDesignSystem, Components, and DesignTokens libraries"
echo "4. Clean the project (Cmd+Shift+K) and rebuild"
echo "" 