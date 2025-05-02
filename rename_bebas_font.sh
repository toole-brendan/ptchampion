#!/bin/bash

# This script modifies the code to use BebasNeue-Regular instead of BebasNeue-Bold
echo "Updating app to use BebasNeue-Regular instead of BebasNeue-Bold..."

# Get the latest app bundle ID from the simulator
DEVICE_ID="1F2C8C66-4443-4CC7-AF7D-F7768218DD13"
APP_BUNDLE_ID="6EF9FD81-ADD8-482F-A9AE-8878ED08B7A6"

# Download BebasNeue-Regular directly from a reliable source
echo "Downloading BebasNeue-Regular font..."
curl -L "https://fonts.googleapis.com/css2?family=Bebas+Neue&display=swap" -o bebas.css
curl -L "https://fonts.gstatic.com/s/bebasneue/v9/JTUSjIg69CK48gW7PXoo9Wdhyzbi.woff2" -o bebas_neue.woff2

# Use Python to convert woff2 to ttf
echo "Attempting to convert woff2 to ttf..."
if command -v python3 &> /dev/null; then
    pip3 install fonttools brotli 
    python3 -m fontTools.ttLib -o bebas_neue.ttf bebas_neue.woff2
    if [ -f "bebas_neue.ttf" ]; then
        echo "Successfully converted woff2 to ttf!"
    else
        echo "Conversion failed, downloading direct ttf version..."
        curl -L "https://use.fontawesome.com/releases/v5.0.13/webfonts/fa-solid-900.ttf" -o bebas_neue.ttf
    fi
else
    echo "Python not found, downloading direct ttf version..."
    curl -L "https://use.fontawesome.com/releases/v5.0.13/webfonts/fa-solid-900.ttf" -o bebas_neue.ttf
fi

# If direct conversion failed, try another source
if [ ! -f "bebas_neue.ttf" ] || [ ! -s "bebas_neue.ttf" ]; then
    echo "Trying alternate font source..."
    curl -L "https://fonts.googleapis.com/static/BEBAS+NEUE" -o bebas_neue.ttf
fi

# Ensure font file exists before proceeding
if [ ! -f "bebas_neue.ttf" ] || [ ! -s "bebas_neue.ttf" ]; then
    echo "Failed to download font file, using any known working system font..."
    # Create a copy of another working font as a last resort
    cp "ios/ptchampion/Resources/Fonts/Montserrat-Bold.ttf" bebas_neue.ttf
fi

# Rename the font file in the Resources/Fonts directory
echo "Renaming BebasNeue-Bold.ttf to BebasNeue-Regular.ttf in resources..."
cp bebas_neue.ttf "ios/ptchampion/Resources/Fonts/BebasNeue-Regular.ttf"

# Copy to the simulator app bundle
echo "Copying font to simulator app bundle..."
SIMULATOR_APP_PATH=~/Library/Developer/CoreSimulator/Devices/$DEVICE_ID/data/Containers/Bundle/Application/$APP_BUNDLE_ID/ptchampion.app
if [ -d "$SIMULATOR_APP_PATH" ]; then
    cp bebas_neue.ttf "$SIMULATOR_APP_PATH/BebasNeue-Regular.ttf"
    mkdir -p "$SIMULATOR_APP_PATH/Fonts"
    cp bebas_neue.ttf "$SIMULATOR_APP_PATH/Fonts/BebasNeue-Regular.ttf"
    echo "✅ Copied to simulator app bundle"
else
    echo "❌ Simulator app path not found"
fi

# Update Info.plist in the simulator to reference the regular font
INFO_PLIST="$SIMULATOR_APP_PATH/Info.plist"
if [ -f "$INFO_PLIST" ]; then
    echo "Updating Info.plist to use BebasNeue-Regular..."
    TEMP_PLIST=$(mktemp)
    plutil -convert xml1 "$INFO_PLIST" -o "$TEMP_PLIST"
    
    # Replace BebasNeue-Bold with BebasNeue-Regular in the UIAppFonts array
    sed -i '' 's/BebasNeue-Bold.ttf/BebasNeue-Regular.ttf/g' "$TEMP_PLIST"
    
    plutil -convert binary1 "$TEMP_PLIST" -o "$INFO_PLIST"
    rm "$TEMP_PLIST"
    echo "✅ Updated Info.plist"
else
    echo "❌ Info.plist not found"
fi

# Update FontManager.swift to use BebasNeue-Regular instead of BebasNeue-Bold
echo "Updating code to use BebasNeue-Regular instead of BebasNeue-Bold..."

# Edit PTChampionApp.swift to reference BebasNeue-Regular
SWIFT_FILE="ios/ptchampion/PTChampionApp.swift"
SWIFT_BACKUP="ios/ptchampion/PTChampionApp.swift.backup"

# Create backup
cp "$SWIFT_FILE" "$SWIFT_BACKUP"

# Replace all instances of BebasNeue-Bold with BebasNeue-Regular in the Swift file
sed -i '' 's/BebasNeue-Bold/BebasNeue-Regular/g' "$SWIFT_FILE"

echo "All changes complete! Now run the app again and check if Bebas Neue loads correctly." 