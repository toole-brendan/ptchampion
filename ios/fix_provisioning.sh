#!/bin/bash

echo "===== PT Champion Provisioning Fix Tool ====="
echo "This script will try multiple approaches to fix the background modes provisioning issue."
echo

# Clean up environment
echo "1. Cleaning environment..."
rm -rf ~/Library/MobileDevice/Provisioning\ Profiles/* 2>/dev/null
rm -rf ~/Library/Developer/Xcode/UserData/Provisioning\ Profiles/* 2>/dev/null
rm -rf ~/Library/Developer/Xcode/DerivedData
rm -rf ~/Library/Caches/com.apple.dt.Xcode
xcrun simctl shutdown all
xcrun simctl erase all
killall Xcode 2>/dev/null || echo "Xcode not running"
mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles
echo "Environment cleaned."

# Approach 1: Use updated entitlements
echo "2. Updating entitlements file..."
cd ptchampion
cp full_entitlements.entitlements ptchampion.entitlements
echo "Entitlements updated to include all background modes."

# Approach 2: Try manual signing
echo "3. Would you like to try manual signing? (y/n)"
read -p "> " choice
if [[ "$choice" == "y" ]]; then
  cd ..
  ./manually_sign.sh
  echo "Manual signing configured."
else
  echo "Skipping manual signing."
fi

# Approach 3: Try creating a new app ID
echo "4. Would you like to try creating a new app ID? (y/n)"
echo "   (This will change your app's bundle identifier, requiring a new provisioning profile)"
read -p "> " choice
if [[ "$choice" == "y" ]]; then
  cd ptchampion
  ./recreate_app_id.sh
  echo "App ID recreated."
else
  echo "Skipping app ID recreation."
fi

echo 
echo "===== WHAT TO DO NEXT ====="
echo "1. Open Xcode"
echo "2. Go to Signing & Capabilities"
echo "3. Toggle 'Automatically manage signing' OFF and then ON again"
echo "4. Select your development team"
echo "5. Close and reopen Xcode if the error persists"
echo "6. If still having issues, try the build.sh script in ptchampion folder"
echo
echo "If nothing works, you may need to:"
echo "1. Sign out of your Apple ID in Xcode and sign back in"
echo "2. Create a brand new app with a new identifier"
echo "3. Contact Apple Developer Support" 