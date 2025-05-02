#!/bin/bash

echo "=== Fixing duplicate font copy build phases ==="

# Project file path
PROJECT_FILE="ios/ptchampion/ptchampion.xcodeproj/project.pbxproj"
BACKUP_FILE="ios/ptchampion/ptchampion.xcodeproj/project.pbxproj.duplicate-fix-backup"

# Backup the project file
echo "Creating backup of project.pbxproj to $BACKUP_FILE"
cp "$PROJECT_FILE" "$BACKUP_FILE"

# Method 1: Remove the existing Copy Fonts script phase but keep the fonts in Copy Bundle Resources
echo "Removing the existing 'Copy Fonts' script phase..."
grep -n "Copy Fonts" "$PROJECT_FILE"

# Note: The script phase name might be "Copy Fonts" or something similar
sed -i '' '/\/\* Copy Fonts \*\/ = {/,/};/d' "$PROJECT_FILE"

# Remove references to the Copy Fonts script phase from the buildPhases array
echo "Removing references to 'Copy Fonts' from build phases..."
sed -i '' 's/[A-Z0-9]* \/\* Copy Fonts \*\/,//g' "$PROJECT_FILE"

echo "Done! You can now try building the project again."
echo "If you still have issues, restore the backup with:"
echo "cp $BACKUP_FILE $PROJECT_FILE"
echo ""
echo "Alternatively, in Xcode:"
echo "1. Go to Build Phases"
echo "2. Remove one of the duplicate font copy phases (either the script or the resources)"
echo "3. Make sure only one method is used to copy the fonts" 