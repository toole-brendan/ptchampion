#!/bin/bash
# Script to fix the duplicate font copying issue in PT Champion Xcode project and ensure fonts are properly bundled

PROJECT_FILE="/Users/brendantoole/projects/ptchampion/ios/ptchampion/ptchampion.xcodeproj/project.pbxproj"
BACKUP_FILE="/Users/brendantoole/projects/ptchampion/ios/ptchampion/ptchampion.xcodeproj/project.pbxproj.fonts-backup"
FONTS_DIR="/Users/brendantoole/projects/ptchampion/ios/ptchampion/Resources/Fonts"
TARGET_FONTS_DIR="/Users/brendantoole/projects/ptchampion/ios/ptchampion/Resources/Fonts"

# Backup the project file
echo "Creating backup of project.pbxproj to $BACKUP_FILE"
cp "$PROJECT_FILE" "$BACKUP_FILE"

# Method 1: Remove the Copy Fonts script phase but keep the fonts in Copy Bundle Resources
echo "Removing the Copy Fonts script phase..."
sed -i '' '/BF90A[0-9]*[0-9] \/\* Copy Fonts \*\/ = {/,/};/d' "$PROJECT_FILE"

# Remove references to the Copy Fonts script phase from the buildPhases array
sed -i '' 's/BF90A[0-9]*[0-9] \/\* Copy Fonts \*\/,//g' "$PROJECT_FILE"

# Ensure Fonts directory exists
echo "Ensuring Fonts directory exists at $TARGET_FONTS_DIR"
mkdir -p "$TARGET_FONTS_DIR"

# Check if font files exist and have proper content
echo "Checking font files in $FONTS_DIR"
for font in "BebasNeue-Bold.ttf" "Montserrat-Regular.ttf" "Montserrat-Bold.ttf" "Montserrat-SemiBold.ttf" "RobotoMono-Bold.ttf" "RobotoMono-Medium.ttf"; do
    font_path="$FONTS_DIR/$font"
    file_size=$(stat -f%z "$font_path" 2>/dev/null || echo "0")
    
    if [ ! -f "$font_path" ] || [ "$file_size" -lt 10000 ]; then
        echo "⚠️ Font file $font is missing or too small (size: $file_size bytes). Downloading from Google Fonts..."
        
        # Download fonts from Google Fonts based on font name
        case "$font" in
            "BebasNeue-Bold.ttf")
                curl -L "https://fonts.google.com/download?family=Bebas%20Neue" -o /tmp/bebas-neue.zip
                unzip -o /tmp/bebas-neue.zip -d /tmp/bebas-neue
                find /tmp/bebas-neue -name "*.ttf" -exec cp {} "$TARGET_FONTS_DIR/$font" \;
                ;;
            "Montserrat-Regular.ttf"|"Montserrat-Bold.ttf"|"Montserrat-SemiBold.ttf")
                # Only download once for all Montserrat variants
                if [ ! -f /tmp/montserrat.zip ]; then
                    curl -L "https://fonts.google.com/download?family=Montserrat" -o /tmp/montserrat.zip
                    unzip -o /tmp/montserrat.zip -d /tmp/montserrat
                fi
                font_variant=$(echo "$font" | sed 's/\.ttf//')
                find /tmp/montserrat -name "$font_variant.ttf" -exec cp {} "$TARGET_FONTS_DIR/$font" \;
                ;;
            "RobotoMono-Bold.ttf"|"RobotoMono-Medium.ttf")
                # Only download once for all RobotoMono variants
                if [ ! -f /tmp/roboto-mono.zip ]; then
                    curl -L "https://fonts.google.com/download?family=Roboto%20Mono" -o /tmp/roboto-mono.zip
                    unzip -o /tmp/roboto-mono.zip -d /tmp/roboto-mono
                fi
                font_variant=$(echo "$font" | sed 's/\.ttf//')
                find /tmp/roboto-mono -name "$font_variant.ttf" -exec cp {} "$TARGET_FONTS_DIR/$font" \;
                ;;
        esac
    else
        echo "✅ Font file $font exists and has size $file_size bytes"
    fi
done

# List all font files in the directory
echo "Fonts in $TARGET_FONTS_DIR after fix:"
ls -la "$TARGET_FONTS_DIR"

echo "Done. Now try building the project again."
echo "If you still encounter issues, restore the backup with: cp $BACKUP_FILE $PROJECT_FILE" 