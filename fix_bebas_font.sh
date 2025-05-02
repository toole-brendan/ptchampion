#!/bin/bash

# Download a fresh copy of BebasNeue-Bold font from a reliable source
echo "Downloading a fresh copy of BebasNeue-Bold font..."

# Direct download from Google Fonts API
curl -L "https://fonts.googleapis.com/css2?family=Bebas+Neue&display=swap" -o bebas.css

# Extract the font URL from the CSS
FONT_URL=$(grep -o "https://[^)]*woff2" bebas.css | head -1)

if [ -n "$FONT_URL" ]; then
    echo "Font URL found: $FONT_URL"
    curl -L "$FONT_URL" -o bebas_neue.woff2
    
    # Convert woff2 to ttf using fonttools
    echo "Converting woff2 to ttf..."
    pip3 install fonttools brotli
    python3 -m fontTools.ttLib -o bebas_neue.ttf bebas_neue.woff2
else
    echo "Font URL not found, using alternative method..."
    # Direct download from a reliable source
    curl -L "https://github.com/dharmatype/Bebas-Neue/raw/master/fonts/BebasNeue(2019)family/ttfs/BebasNeue-Regular.ttf" -o bebas_neue.ttf
fi

# Check if file was downloaded successfully
if [ -f "bebas_neue.ttf" ]; then
    echo "Font downloaded successfully"
    
    # Replace the corrupted font file
    cp bebas_neue.ttf ios/ptchampion/Resources/Fonts/BebasNeue-Bold.ttf
    echo "Replaced BebasNeue-Bold.ttf with the new file"
    
    # Copy to the simulator as well
    DEVICE_ID="1F2C8C66-4443-4CC7-AF7D-F7768218DD13"
    APP_BUNDLE_ID="13608BF5-37C5-41FA-95A1-E38E75EDBA05"
    SIM_APP_PATH=~/Library/Developer/CoreSimulator/Devices/$DEVICE_ID/data/Containers/Bundle/Application/$APP_BUNDLE_ID/ptchampion.app
    
    if [ -d "$SIM_APP_PATH" ]; then
        cp bebas_neue.ttf "$SIM_APP_PATH/BebasNeue-Bold.ttf"
        mkdir -p "$SIM_APP_PATH/Fonts"
        cp bebas_neue.ttf "$SIM_APP_PATH/Fonts/BebasNeue-Bold.ttf"
        echo "Copied to simulator app bundle"
    else
        echo "Simulator app bundle not found at: $SIM_APP_PATH"
    fi
    
    echo "Done! Now restart the app in the simulator."
else
    echo "Failed to download the font"
fi

# Clean up
rm -f bebas.css bebas_neue.woff2 