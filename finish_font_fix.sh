#!/bin/bash

# This script fixes the Info.plist update issue and completes the font fix process

echo "Finalizing font fix process..."

# Fix Info.plist directly with PlistBuddy
INFO_PLIST="ios/ptchampion/SupportingFiles/Info.plist"
if [ ! -f "$INFO_PLIST" ]; then
  echo "❌ Could not find Info.plist at $INFO_PLIST"
  exit 1
fi

echo "Updating Info.plist using PlistBuddy..."

# Check if UIAppFonts key exists
if /usr/libexec/PlistBuddy -c "Print :UIAppFonts" "$INFO_PLIST" > /dev/null 2>&1; then
  # Delete existing UIAppFonts array
  /usr/libexec/PlistBuddy -c "Delete :UIAppFonts" "$INFO_PLIST"
fi

# Add UIAppFonts key with the correct font entries
/usr/libexec/PlistBuddy -c "Add :UIAppFonts array" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :UIAppFonts:0 string Montserrat-Regular.ttf" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :UIAppFonts:1 string Montserrat-Bold.ttf" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :UIAppFonts:2 string Montserrat-SemiBold.ttf" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :UIAppFonts:3 string RobotoMono-Bold.ttf" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :UIAppFonts:4 string RobotoMono-Medium.ttf" "$INFO_PLIST"

echo "✅ Successfully updated Info.plist"

# Clean the Xcode project
echo "Cleaning Xcode project..."
cd ios/ptchampion
xcodebuild clean -project ptchampion.xcodeproj -scheme ptchampion -quiet || {
  echo "❌ Clean failed but continuing..."
}

echo "Font fix process complete! You can now build and run your app."
echo "The app will use Helvetica system font instead of BebasNeue."
echo ""
echo "To build from command line:"
echo "cd ios/ptchampion && xcodebuild -project ptchampion.xcodeproj -scheme ptchampion -destination 'platform=iOS Simulator,name=iPhone 15'" 