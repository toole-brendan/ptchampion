#!/bin/bash

# This script uses a system font to replace the problematic BebasNeue font

# Get the app bundle ID (use the latest one from logs)
DEVICE_ID="1F2C8C66-4443-4CC7-AF7D-F7768218DD13"
APP_BUNDLE_ID="6776A9D9-1FBC-4239-82CF-3696318A8CDC"
SIMULATOR_APP_PATH=~/Library/Developer/CoreSimulator/Devices/$DEVICE_ID/data/Containers/Bundle/Application/$APP_BUNDLE_ID/ptchampion.app

echo "Target app bundle: $SIMULATOR_APP_PATH"

# Create a temporary directory for font conversion
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR" || exit 1

# Use a system font that's guaranteed to work (San Francisco)
echo "Copying system font as a replacement..."
cp /System/Library/Fonts/SFCompact.ttf ./bebas.ttf 2>/dev/null || \
cp /System/Library/Fonts/SFCompactDisplay.ttf ./bebas.ttf 2>/dev/null || \
cp /System/Library/Fonts/Helvetica.ttc ./bebas.ttf 2>/dev/null || \
cp /System/Library/Fonts/HelveticaNeue.ttc ./bebas.ttf 2>/dev/null || \
cp /System/Library/Fonts/Arial.ttf ./bebas.ttf 2>/dev/null

# If none of the above worked, try another approach
if [ ! -f ./bebas.ttf ] || [ ! -s ./bebas.ttf ]; then
    echo "Using Montserrat font as a substitute..."
    cp "$SIMULATOR_APP_PATH/Montserrat-Bold.ttf" ./bebas.ttf
fi

# Verify we have a font to use
if [ ! -f ./bebas.ttf ] || [ ! -s ./bebas.ttf ]; then
    echo "❌ Couldn't find a suitable font. Creating a dummy font file..."
    # Create a dummy file that's just a copy of any available font
    find /System/Library/Fonts -name "*.ttf" -o -name "*.ttc" | head -1 | xargs -I{} cp {} ./bebas.ttf
fi

# Add both filenames to the app bundle to handle all cases
echo "Copying font to app bundle with both Bold and Regular names..."
cp ./bebas.ttf "$SIMULATOR_APP_PATH/BebasNeue-Bold.ttf"
cp ./bebas.ttf "$SIMULATOR_APP_PATH/BebasNeue-Regular.ttf"

# Make sure Fonts directory exists
mkdir -p "$SIMULATOR_APP_PATH/Fonts"
cp ./bebas.ttf "$SIMULATOR_APP_PATH/Fonts/BebasNeue-Bold.ttf"
cp ./bebas.ttf "$SIMULATOR_APP_PATH/Fonts/BebasNeue-Regular.ttf"

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
ls -l "$SIMULATOR_APP_PATH/BebasNeue-Bold.ttf"
ls -l "$SIMULATOR_APP_PATH/BebasNeue-Regular.ttf"
ls -l "$SIMULATOR_APP_PATH/Fonts/BebasNeue-Bold.ttf"
ls -l "$SIMULATOR_APP_PATH/Fonts/BebasNeue-Regular.ttf"

# Clean up
cd - > /dev/null
rm -rf "$TEMP_DIR"

echo "Done! Now restart your app and test if fonts load properly."
echo "Note: This fix uses a system font as a substitute for Bebas Neue to ensure the app works."
echo "For a permanent fix, you'll need to update your Xcode project with proper font files." 