#!/bin/bash

# Extract simulator device ID and app bundle ID from log
DEVICE_ID="1F2C8C66-4443-4CC7-AF7D-F7768218DD13"
APP_BUNDLE_ID="8C13BDED-0A49-43D1-A32E-5BAA6C7654AD"  # Fixed app bundle ID based on the output

# Source and destination paths
SOURCE_FONTS_DIR="ios/ptchampion/Resources/Fonts"
SIMULATOR_APP_PATH=~/Library/Developer/CoreSimulator/Devices/$DEVICE_ID/data/Containers/Bundle/Application/$APP_BUNDLE_ID/ptchampion.app
DESTINATION_FONTS_DIR="$SIMULATOR_APP_PATH/Fonts"

echo "Source fonts directory: $SOURCE_FONTS_DIR"
echo "Simulator app path: $SIMULATOR_APP_PATH"
echo "Destination fonts directory: $DESTINATION_FONTS_DIR"

# Check if the simulator app directory exists
if [ ! -d "$SIMULATOR_APP_PATH" ]; then
  echo "❌ ERROR: Simulator app directory does not exist: $SIMULATOR_APP_PATH"
  echo "Available applications in simulator:"
  find ~/Library/Developer/CoreSimulator/Devices/$DEVICE_ID/data/Containers/Bundle/Application -maxdepth 2 -type d | grep -v "PlugIns"
  exit 1
fi

# Create destination directory if it doesn't exist
mkdir -p "$DESTINATION_FONTS_DIR"

# Copy fonts to both the app directory root and the Fonts subdirectory
echo "Copying fonts to simulator app bundle..."
for font in "$SOURCE_FONTS_DIR"/*.ttf; do
  if [ -f "$font" ]; then
    echo "Copying $(basename "$font")"
    cp "$font" "$SIMULATOR_APP_PATH/" && echo "  ✅ Copied to app root" || echo "  ❌ Failed to copy to app root"
    cp "$font" "$DESTINATION_FONTS_DIR/" && echo "  ✅ Copied to Fonts/ dir" || echo "  ❌ Failed to copy to Fonts/ dir"
  fi
done

# List the contents to verify
echo "Contents of app bundle after copying:"
ls -la "$SIMULATOR_APP_PATH"
echo "Contents of Fonts directory after copying:"
ls -la "$DESTINATION_FONTS_DIR"

# Modify Info.plist to include font files
INFO_PLIST="$SIMULATOR_APP_PATH/Info.plist"
if [ -f "$INFO_PLIST" ]; then
  echo "Checking Info.plist for UIAppFonts key..."
  if ! plutil -p "$INFO_PLIST" | grep -q "UIAppFonts"; then
    echo "Adding UIAppFonts key to Info.plist..."
    TEMP_PLIST=$(mktemp)
    plutil -convert xml1 "$INFO_PLIST" -o "$TEMP_PLIST"
    
    # Add before last dict end
    sed -i '' 's|</dict>|	<key>UIAppFonts</key>\
	<array>\
		<string>BebasNeue-Bold.ttf</string>\
		<string>Montserrat-Regular.ttf</string>\
		<string>Montserrat-Bold.ttf</string>\
		<string>Montserrat-SemiBold.ttf</string>\
		<string>RobotoMono-Bold.ttf</string>\
		<string>RobotoMono-Medium.ttf</string>\
	</array>\
</dict>|' "$TEMP_PLIST"
    
    plutil -convert binary1 "$TEMP_PLIST" -o "$INFO_PLIST"
    rm "$TEMP_PLIST"
    echo "✅ Updated Info.plist with font declarations"
  else
    echo "Info.plist already contains UIAppFonts key"
  fi
else
  echo "❌ Info.plist not found at $INFO_PLIST"
fi

echo "Now restart your app in the simulator to see if fonts load properly." 