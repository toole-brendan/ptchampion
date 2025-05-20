#!/bin/bash

echo "Verifying GoogleSignIn integration..."

# Check if package is in Package.resolved
cd /Users/brendantoole/projects/ptchampion
if grep -q "GoogleSignIn-iOS" ios/ptchampion/ptchampion.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved 2>/dev/null; then
  echo "✅ GoogleSignIn-iOS found in Package.resolved"
else
  echo "❌ GoogleSignIn-iOS not found in Package.resolved"
fi

# Clean the project
echo "Cleaning project..."
xcodebuild -workspace ptchampion.xcworkspace -scheme ptchampion clean

# Build the project
echo "Building project..."
xcodebuild -workspace ptchampion.xcworkspace -scheme ptchampion build | grep -i "googlesignin"

echo "Verification complete. If the build succeeded, GoogleSignIn-iOS has been successfully integrated." 