#!/bin/bash

# This script updates Info.plist and removes BebasNeue fonts from Build Phases

echo "Automating remaining steps to fix BebasNeue font issues..."

# Find Info.plist file
INFO_PLIST_PATH=$(find ios -name "Info.plist" | grep -v "build" | head -1)
if [ -z "$INFO_PLIST_PATH" ]; then
  echo "❌ Could not find Info.plist in ios directory"
  exit 1
fi

echo "Found Info.plist at: $INFO_PLIST_PATH"

# Backup Info.plist
BACKUP_PLIST="${INFO_PLIST_PATH}.backup"
echo "Creating backup of Info.plist at $BACKUP_PLIST"
cp "$INFO_PLIST_PATH" "$BACKUP_PLIST"

# Update Info.plist with template from FontDeclaration.plist
TEMPLATE_PLIST="ios/ptchampion/FontDeclaration.plist"
if [ ! -f "$TEMPLATE_PLIST" ]; then
  echo "❌ Font declaration template not found at $TEMPLATE_PLIST"
  exit 1
fi

echo "Updating UIAppFonts in Info.plist..."

# Convert to XML for editing
TEMP_PLIST=$(mktemp)
plutil -convert xml1 "$INFO_PLIST_PATH" -o "$TEMP_PLIST"

# Extract the font array from FontDeclaration.plist
FONT_ARRAY=$(sed -n '/<key>UIAppFonts<\/key>/,/<\/array>/p' "$TEMPLATE_PLIST")

# Remove existing UIAppFonts entry if it exists
sed -i '' '/<key>UIAppFonts<\/key>/,/<\/array>/d' "$TEMP_PLIST"

# Add the new font array before the end of the dict
sed -i '' 's|</dict>|'"$FONT_ARRAY"'</dict>|' "$TEMP_PLIST"

# Convert back to binary and save
plutil -convert binary1 "$TEMP_PLIST" -o "$INFO_PLIST_PATH"
rm "$TEMP_PLIST"

echo "✅ Info.plist updated successfully"

# Now edit the Build Phases in project.pbxproj to remove BebasNeue fonts
PROJECT_FILE="ios/ptchampion/ptchampion.xcodeproj/project.pbxproj"
BACKUP_PROJECT="${PROJECT_FILE}.build_phases_backup"

if [ ! -f "$PROJECT_FILE" ]; then
  echo "❌ Could not find project.pbxproj"
  exit 1
fi

echo "Creating backup of project.pbxproj at $BACKUP_PROJECT"
cp "$PROJECT_FILE" "$BACKUP_PROJECT"

echo "Removing BebasNeue fonts from Copy Bundle Resources phase..."

# This is a bit tricky - we need to find and remove references to BebasNeue font files
# First, find file references for BebasNeue fonts
BEBAS_REFS=$(grep -n "BebasNeue-.*\.ttf" "$PROJECT_FILE" | cut -d: -f1)

if [ -z "$BEBAS_REFS" ]; then
  echo "No BebasNeue font references found in project file."
else
  # For each reference line, get the identifier and remove it from PBXBuildFile and PBXResourcesBuildPhase
  for LINE in $BEBAS_REFS; do
    # Extract the file identifier
    CONTEXT=$(sed -n "$((LINE-5)),$((LINE+5))p" "$PROJECT_FILE")
    FILE_ID=$(echo "$CONTEXT" | grep -o "[A-F0-9]\{24\} /\* BebasNeue-.*\.ttf \*/" | cut -d' ' -f1)
    
    if [ -n "$FILE_ID" ]; then
      echo "Removing font reference with ID: $FILE_ID"
      
      # Remove from PBXBuildFile section
      sed -i '' "/$FILE_ID \/\* BebasNeue-.*\.ttf in Resources \*\/ = {/,/};/d" "$PROJECT_FILE"
      
      # Remove from PBXResourcesBuildPhase section (resources build phase)
      sed -i '' "s/$FILE_ID \/\* BebasNeue-.*\.ttf in Resources \*\/,//g" "$PROJECT_FILE"
    fi
  done
  
  echo "✅ Removed BebasNeue font references from build phases"
fi

echo ""
echo "All steps completed successfully!"
echo ""
echo "Changes made:"
echo "1. Updated Info.plist to include only working fonts"
echo "2. Removed BebasNeue fonts from Copy Bundle Resources phase"
echo ""
echo "You can now clean and build your project with:"
echo "xcodebuild clean -project ios/ptchampion/ptchampion.xcodeproj -scheme ptchampion"
echo ""
echo "To restore from backups if needed:"
echo "cp $BACKUP_PLIST $INFO_PLIST_PATH"
echo "cp $BACKUP_PROJECT $PROJECT_FILE" 