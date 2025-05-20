#!/bin/bash

echo "1. Closing Xcode..."
killall Xcode 2>/dev/null || true
sleep 2

echo "2. Going to project directory..."
cd /Users/brendantoole/projects/ptchampion/ios/ptchampion

echo "3. Commenting out the GoogleSignIn pod if present..."
sed -i '' '/pod.*GoogleSignIn/s/^/# /' Podfile

echo "4. Running pod install..."
pod install

echo "5. Checking if we need to fix the Swift Package..."
if ! grep -q "GoogleSignIn-iOS" ptchampion.xcodeproj/project.pbxproj; then
  echo "6. Adding GoogleSignIn-iOS package reference to project..."
  
  # Create simple Swift file that imports GoogleSignIn to force Xcode to add the package
  mkdir -p temp_files
  cat > temp_files/GoogleSignInImporter.swift << 'EOF'
import Foundation
import GoogleSignIn
import GoogleSignInSwift

// This file is a temporary placeholder to ensure GoogleSignIn is imported correctly
func setupGoogleSignIn() {
    let configuration = GIDConfiguration(clientID: "YOUR_CLIENT_ID")
    print("Google Sign-In configuration: \(configuration)")
}
EOF

  echo "7. Opening Xcode with the project (not workspace)..."
  open -a Xcode ptchampion.xcodeproj
  
  echo "8. Instructions to complete in Xcode:"
  echo "   a. In the left sidebar, right-click on the ptchampion project and select 'Add Packages'"
  echo "   b. In the search field, paste: https://github.com/google/GoogleSignIn-iOS"
  echo "   c. Select version 8.0.0"
  echo "   d. Click 'Add Package'"
  echo "   e. Make sure both GoogleSignIn and GoogleSignInSwift are selected"
  echo "   f. Click 'Add Package' again"
  echo "   g. Close Xcode when done"
  
  echo "9. Waiting for you to add the package in Xcode..."
  echo "   Press Enter when you've completed the steps in Xcode..."
  read -p ""
  
  echo "10. Cleaning up temporary files..."
  killall Xcode 2>/dev/null || true
  sleep 2
  rm -rf temp_files
fi

echo "11. Opening the workspace with fixed references..."
open -a Xcode /Users/brendantoole/projects/ptchampion/ptchampion.xcworkspace 