#!/bin/bash

# This script directly fixes the Bebas Neue font by downloading a known working font
# and adding it with both names to the simulator app bundle

# Get the app bundle ID (use the latest one from logs)
DEVICE_ID="1F2C8C66-4443-4CC7-AF7D-F7768218DD13"
APP_BUNDLE_ID="6776A9D9-1FBC-4239-82CF-3696318A8CDC"
SIMULATOR_APP_PATH=~/Library/Developer/CoreSimulator/Devices/$DEVICE_ID/data/Containers/Bundle/Application/$APP_BUNDLE_ID/ptchampion.app

echo "Target app bundle: $SIMULATOR_APP_PATH"

# Download Avenir font (a system font that is guaranteed to work) to use as a placeholder
echo "Downloading a reliable font..."
curl -L "https://raw.githubusercontent.com/terryum/Avenir-Next-for-Powerpoint/master/avenir-next-regular.ttf" -o avenir.ttf

# Check file exists and has size
if [ -f "avenir.ttf" ] && [ -s "avenir.ttf" ]; then
    echo "✅ Font downloaded successfully"
else
    echo "❌ Failed to download font, using Helvetica from system"
    cp /System/Library/Fonts/Helvetica.ttc avenir.ttf
fi

# Add both filenames to the app bundle to handle all cases
echo "Copying font to app bundle with both Bold and Regular names..."
cp avenir.ttf "$SIMULATOR_APP_PATH/BebasNeue-Bold.ttf"
cp avenir.ttf "$SIMULATOR_APP_PATH/BebasNeue-Regular.ttf"

# Make sure Fonts directory exists
mkdir -p "$SIMULATOR_APP_PATH/Fonts"
cp avenir.ttf "$SIMULATOR_APP_PATH/Fonts/BebasNeue-Bold.ttf"
cp avenir.ttf "$SIMULATOR_APP_PATH/Fonts/BebasNeue-Regular.ttf"

# Modify the Info.plist to include both font names
INFO_PLIST="$SIMULATOR_APP_PATH/Info.plist"
if [ -f "$INFO_PLIST" ]; then
    echo "Updating Info.plist..."
    TEMP_PLIST=$(mktemp)
    plutil -convert xml1 "$INFO_PLIST" -o "$TEMP_PLIST"
    
    # Check if UIAppFonts exists and add both font names if needed
    if ! grep -q "UIAppFonts" "$TEMP_PLIST"; then
        echo "Adding UIAppFonts key with both font names..."
        sed -i '' 's|</dict>|    <key>UIAppFonts</key>\
    <array>\
        <string>BebasNeue-Bold.ttf</string>\
        <string>BebasNeue-Regular.ttf</string>\
        <string>Montserrat-Regular.ttf</string>\
        <string>Montserrat-Bold.ttf</string>\
        <string>Montserrat-SemiBold.ttf</string>\
        <string>RobotoMono-Bold.ttf</string>\
        <string>RobotoMono-Medium.ttf</string>\
    </array>\
</dict>|' "$TEMP_PLIST"
    else
        echo "UIAppFonts key already exists, ensuring both font names are included..."
        # Make sure both BebasNeue-Bold.ttf and BebasNeue-Regular.ttf are in the array
        if ! grep -q "BebasNeue-Bold.ttf" "$TEMP_PLIST"; then
            sed -i '' '/<key>UIAppFonts<\/key>/,/<\/array>/ s|<array>|<array>\
        <string>BebasNeue-Bold.ttf</string>|' "$TEMP_PLIST"
        fi
        if ! grep -q "BebasNeue-Regular.ttf" "$TEMP_PLIST"; then
            sed -i '' '/<key>UIAppFonts<\/key>/,/<\/array>/ s|<array>|<array>\
        <string>BebasNeue-Regular.ttf</string>|' "$TEMP_PLIST"
        fi
    fi
    
    plutil -convert binary1 "$TEMP_PLIST" -o "$INFO_PLIST"
    rm "$TEMP_PLIST"
    echo "✅ Updated Info.plist"
else
    echo "❌ Info.plist not found"
fi

# List files in app bundle to verify
echo "App bundle contents after update:"
ls -la "$SIMULATOR_APP_PATH" | grep -i bebas
ls -la "$SIMULATOR_APP_PATH/Fonts" | grep -i bebas

echo "Done! Now restart your app and test if fonts load properly."
echo "Note: This fix uses Avenir font as a substitute for Bebas Neue to ensure the app works."
echo "For a permanent fix, you'll need to update your Xcode project with proper font files." 