#!/bin/bash

echo "===== PT Champion Background Modes Fix ====="
echo "This script addresses the persistent background modes provisioning profile error"
echo

# Clean up provisioning profiles and Xcode caches
echo "1. Cleaning environment..."
rm -rf ~/Library/MobileDevice/Provisioning\ Profiles/* 2>/dev/null
rm -rf ~/Library/Developer/Xcode/UserData/Provisioning\ Profiles/* 2>/dev/null
rm -rf ~/Library/Developer/Xcode/DerivedData/ptchampion* 2>/dev/null
rm -rf ~/Library/Caches/com.apple.dt.Xcode/*
killall Xcode 2>/dev/null || echo "Xcode not running"
defaults delete com.apple.dt.Xcode 2>/dev/null
echo "Environment cleaned."

# Calculate the script's directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$SCRIPT_DIR/ptchampion"

# Make sure the entitlements/plist are correct
echo "2. Verifying entitlements..."
cd "$PROJECT_DIR" || { echo "ERROR: Could not change to project directory: $PROJECT_DIR"; exit 1; }
echo "Working in $(pwd)"

# Remove any BackgroundModes key from the entitlements file if it still exists
/usr/libexec/PlistBuddy -c "Delete :com.apple.developer.background-modes" ptchampion.entitlements 2>/dev/null || echo "Background modes already removed from entitlements (good)"

# Check that Info.plist has the UIBackgroundModes key
if ! /usr/libexec/PlistBuddy -c "Print :UIBackgroundModes" ptchampion-Info.plist &>/dev/null; then
  echo "ERROR: UIBackgroundModes not found in Info.plist"
  echo "This should be fixed before continuing"
  exit 1
fi
echo "Entitlements verified."

# Reset signing
echo "3. Reset code signing..."
project_file="ptchampion.xcodeproj/project.pbxproj"
# Toggle to manual and back to automatic to ensure provisioning refresh
perl -i -pe 's/ProvisioningStyle = Automatic;/ProvisioningStyle = Manual;/g' "$project_file"
echo "Changed to manual provisioning temporarily"
sleep 2
perl -i -pe 's/ProvisioningStyle = Manual;/ProvisioningStyle = Automatic;/g' "$project_file"
echo "Restored automatic provisioning"

echo 
echo "===== STEPS TO COMPLETE FIX ====="
echo "1. Open Xcode"
echo "2. Go to Signing & Capabilities"
echo "3. Make sure 'Automatically manage signing' is ON"
echo "4. Go to Product > Clean Build Folder"
echo "5. Restart Xcode"
echo "6. Build the app"
echo
echo "If the error persists:"
echo "1. Open the Apple Developer Portal in a browser"
echo "2. Go to Certificates, Identifiers & Profiles"
echo "3. Delete the App ID for your app"
echo "4. Create a new App ID with the same bundle ID"
echo "5. Enable the required capabilities (HealthKit, etc.)"
echo "6. Do NOT enable background modes in the portal (these should only be in Info.plist)"
echo "7. Download the new profile and double-click to install"
echo "8. Restart Xcode again" 