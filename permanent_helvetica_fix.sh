#!/bin/bash

# This script permanently replaces BebasNeue with Helvetica in the project

echo "Permanently fixing font issues by using Helvetica instead of BebasNeue..."

# 1. Backup the Swift code
SWIFT_FILE="ios/ptchampion/PTChampionApp.swift"
BACKUP_FILE="ios/ptchampion/PTChampionApp.swift.original"

echo "Creating backup of PTChampionApp.swift at $BACKUP_FILE"
cp "$SWIFT_FILE" "$BACKUP_FILE"

# 2. Update Swift code to use system font instead of BebasNeue
echo "Replacing BebasNeue font references with Helvetica system font in code..."
sed -i '' 's/UIFont(name: "BebasNeue-Regular", size: [0-9]*)/UIFont.systemFont(ofSize: 22, weight: .bold)/g' "$SWIFT_FILE"
sed -i '' 's/UIFont(name: "BebasNeue-Bold", size: [0-9]*)/UIFont.systemFont(ofSize: 22, weight: .bold)/g' "$SWIFT_FILE"

# 3. Remove font names from the font registration array in FontManager
echo "Updating FontManager to not try loading BebasNeue fonts..."
sed -i '' '/BebasNeue-Regular/d' "$SWIFT_FILE"
sed -i '' '/BebasNeue-Bold/d' "$SWIFT_FILE"

# 4. Update the Info.plist template for fonts
INFO_TEMPLATE="ios/ptchampion/FontDeclaration.plist"
echo "Creating an updated Info.plist template for fonts..."

cat > "$INFO_TEMPLATE" << EOL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>UIAppFonts</key>
    <array>
        <string>Montserrat-Regular.ttf</string>
        <string>Montserrat-Bold.ttf</string>
        <string>Montserrat-SemiBold.ttf</string>
        <string>RobotoMono-Bold.ttf</string>
        <string>RobotoMono-Medium.ttf</string>
    </array>
</dict>
</plist>
EOL

echo "Font declaration template created. Please add these entries to your Info.plist in Xcode."

# 5. Remove the broken BebasNeue font files from the project
echo "Removing broken BebasNeue font files..."
rm -f "ios/ptchampion/Resources/Fonts/BebasNeue-Bold.ttf"
rm -f "ios/ptchampion/Resources/Fonts/BebasNeue-Regular.ttf"

echo ""
echo "Permanent Helvetica fix applied to the project code."
echo ""
echo "NEXT STEPS:"
echo "1. Open your Xcode project"
echo "2. Edit Info.plist to remove BebasNeue font entries (use the template in $INFO_TEMPLATE)"
echo "3. In Build Phases, remove BebasNeue fonts from the 'Copy Bundle Resources' phase"
echo "4. Clean and build your project"
echo ""
echo "This fix replaces BebasNeue with the system Helvetica font." 