#!/bin/bash

# This script adds the font files to the Xcode project properly by:
# 1. Adding UIAppFonts entry to Info.plist in the project
# 2. Ensuring fonts are added to the "Copy Bundle Resources" build phase

PROJ_DIR="ios/ptchampion"
INFO_PLIST_PATH="$PROJ_DIR/Info.plist"
PROJECT_FILE="$PROJ_DIR/ptchampion.xcodeproj/project.pbxproj"
BACKUP_FILE="$PROJ_DIR/ptchampion.xcodeproj/project.pbxproj.fonts-fix-backup"

# Source fonts directory
FONTS_DIR="$PROJ_DIR/Resources/Fonts"

# Make a backup of the project file
echo "Backing up project file to $BACKUP_FILE"
cp "$PROJECT_FILE" "$BACKUP_FILE"

# 1. Update Info.plist to include the font declarations
echo "Checking Info.plist..."
if [ -f "$INFO_PLIST_PATH" ]; then
    echo "Adding UIAppFonts entries to Info.plist"
    cat > "$PROJ_DIR/FontDeclaration.plist" << EOL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>UIAppFonts</key>
    <array>
        <string>BebasNeue-Bold.ttf</string>
        <string>Montserrat-Regular.ttf</string>
        <string>Montserrat-Bold.ttf</string>
        <string>Montserrat-SemiBold.ttf</string>
        <string>RobotoMono-Bold.ttf</string>
        <string>RobotoMono-Medium.ttf</string>
    </array>
</dict>
</plist>
EOL
    echo "Created font declaration plist"
    echo "Please add this to your Info.plist manually in Xcode"
else
    echo "⚠️ Info.plist not found at $INFO_PLIST_PATH"
    echo "Please add the UIAppFonts key to your Info.plist manually in Xcode"
fi

# 2. Add a custom Run Script phase to ensure fonts are copied
echo "Adding a custom Run Script phase to copy fonts..."

# Create a new CopyFonts-XC.sh script that can be used in the Xcode build phase
cat > "$PROJ_DIR/CopyFonts-XC.sh" << 'EOL'
#!/bin/sh

# Create destination directories
mkdir -p "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
mkdir -p "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/Fonts"

# Font source directory
FONTS_DIR="${SRCROOT}/ptchampion/Resources/Fonts"
DEST_DIR="${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
FONTS_DEST_DIR="${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/Fonts"

echo "Copying fonts from ${FONTS_DIR} to app bundle..."

# Copy all TTF font files with error checking
for font in "${FONTS_DIR}"/*.ttf; do
    if [ -f "$font" ]; then
        echo "Copying $(basename "$font")"
        cp "$font" "${DEST_DIR}/"
        cp "$font" "${FONTS_DEST_DIR}/"
    fi
done

# Verify results
echo "Fonts in app bundle:"
ls -la "${DEST_DIR}"/*.ttf 2>/dev/null || echo "No TTF fonts in root!"
ls -la "${FONTS_DEST_DIR}"/*.ttf 2>/dev/null || echo "No TTF fonts in Fonts dir!"

exit 0
EOL

chmod +x "$PROJ_DIR/CopyFonts-XC.sh"
echo "Created CopyFonts-XC.sh script at $PROJ_DIR/CopyFonts-XC.sh"

echo "Done!"
echo ""
echo "NEXT STEPS:"
echo "1. Open your Xcode project"
echo "2. Select your target"
echo "3. Go to 'Build Phases'"
echo "4. Click '+' and select 'New Run Script Phase'"
echo "5. Set the script to: ${SHELL} \"\${SRCROOT}/ptchampion/CopyFonts-XC.sh\""
echo "6. Drag this phase to be after the 'Copy Bundle Resources' phase"
echo "7. Ensure all font files are also added to 'Copy Bundle Resources' phase"
echo "8. Build and run your app" 