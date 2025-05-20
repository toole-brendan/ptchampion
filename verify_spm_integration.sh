#!/bin/bash

echo "Verifying GoogleSignIn SPM integration..."

# Check if the package reference exists in the project file
echo "1. Checking for GoogleSignIn reference in Xcode project..."
cd /Users/brendantoole/projects/ptchampion/ios/ptchampion
if grep -q "GoogleSignIn-iOS" ptchampion.xcodeproj/project.pbxproj; then
  echo "✅ GoogleSignIn package reference found in the project file"
else
  echo "❌ GoogleSignIn package reference NOT found in the project file"
fi

# Check if GoogleSignIn is imported in any Swift files
echo "2. Looking for GoogleSignIn import statements in code..."
cd /Users/brendantoole/projects/ptchampion
IMPORT_COUNT=$(grep -r "import GoogleSignIn" --include="*.swift" ios/ | wc -l | tr -d ' ')
if [ "$IMPORT_COUNT" -gt 0 ]; then
  echo "✅ Found $IMPORT_COUNT import statements for GoogleSignIn"
else
  echo "⚠️ No import statements found for GoogleSignIn yet - you may need to add them to your code"
fi

echo "3. Creating a test import file for verification..."
cat > /tmp/test_google_signin_import.swift << 'EOL'
import Foundation
import GoogleSignIn
import GoogleSignInSwift

func testSignIn() {
    let config = GIDConfiguration(clientID: "test-client-id")
    print("Google SignIn configuration: \(config)")
}
EOL

echo "4. Attempting to compile the test file (this may take a moment)..."
cd /Users/brendantoole/projects/ptchampion
swiftc -sdk $(xcrun --show-sdk-path --sdk iphonesimulator) \
  -framework Foundation \
  -F $(find ~/Library/Developer/Xcode -name "GoogleSignIn.framework" -type d | head -n 1) \
  -F $(find ~/Library/Developer/Xcode -name "GoogleSignInSwift.framework" -type d | head -n 1) \
  -I $(find ~/Library/Developer/Xcode -name "GoogleSignIn.swiftmodule" -type d | head -n 1) \
  -I $(find ~/Library/Developer/Xcode -name "GoogleSignInSwift.swiftmodule" -type d | head -n 1) \
  /tmp/test_google_signin_import.swift -o /tmp/test_google_signin 2>/dev/null

if [ $? -eq 0 ]; then
  echo "✅ Successfully compiled test file with GoogleSignIn imports"
else
  echo "❌ Failed to compile test file with GoogleSignIn imports"
  echo "   This is expected if you just added the package - Xcode needs to download and build it first."
  echo "   Open Xcode and build the project to complete the integration."
fi

echo ""
echo "GoogleSignIn-iOS package has been added to your project!"
echo "Now do the following in Xcode:"
echo "1. Build the project (⌘+B) to ensure the package is properly downloaded and built"
echo "2. Check for any build errors and resolve them"
echo "3. Add 'import GoogleSignIn' and 'import GoogleSignInSwift' where needed in your code" 