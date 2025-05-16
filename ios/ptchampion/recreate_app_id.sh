#!/bin/bash

# Set variables
BUNDLE_ID="com.toole.ptchampion.new"
TEAM_ID="6DKP9BK9LF"
APP_NAME="PT Champion Dev"

# Update Info.plist to use new bundle ID
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier ${BUNDLE_ID}" SupportingFiles/Info.plist

# Find and update the project.pbxproj file
PROJECT_FILE="ptchampion.xcodeproj/project.pbxproj"

# Make a backup
cp "$PROJECT_FILE" "${PROJECT_FILE}.bak"

# Update bundle identifier in project file
sed -i '' "s/PRODUCT_BUNDLE_IDENTIFIER = \"com.toole.ptchampion\";/PRODUCT_BUNDLE_IDENTIFIER = \"${BUNDLE_ID}\";/g" "$PROJECT_FILE"

# Update product name
sed -i '' "s/PRODUCT_NAME = \"ptchampion\";/PRODUCT_NAME = \"${APP_NAME}\";/g" "$PROJECT_FILE"

# Use a different display name to clearly differentiate
/usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName ${APP_NAME}" SupportingFiles/Info.plist

echo "App ID changed to ${BUNDLE_ID}"
echo "Original project file backed up to ${PROJECT_FILE}.bak"
echo "Now open Xcode, the app will have a new bundle ID and Xcode should create a new provisioning profile." 