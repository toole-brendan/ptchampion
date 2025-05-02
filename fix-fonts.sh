#!/bin/bash
# Script to fix the duplicate font copying issue in PT Champion Xcode project

PROJECT_FILE="/Users/brendantoole/projects/ptchampion/ios/ptchampion/ptchampion.xcodeproj/project.pbxproj"
BACKUP_FILE="/Users/brendantoole/projects/ptchampion/ios/ptchampion/ptchampion.xcodeproj/project.pbxproj.fonts-backup"

# Backup the project file
echo "Creating backup of project.pbxproj to $BACKUP_FILE"
cp "$PROJECT_FILE" "$BACKUP_FILE"

# Method 1: Remove the Copy Fonts script phase but keep the fonts in Copy Bundle Resources
echo "Removing the Copy Fonts script phase..."
sed -i '' '/BF90A[0-9]*[0-9] \/\* Copy Fonts \*\/ = {/,/};/d' "$PROJECT_FILE"

# Remove references to the Copy Fonts script phase from the buildPhases array
sed -i '' 's/BF90A[0-9]*[0-9] \/\* Copy Fonts \*\/,//g' "$PROJECT_FILE"

echo "Done. Now try building the project again."
echo "If you still encounter issues, restore the backup with: cp $BACKUP_FILE $PROJECT_FILE" 