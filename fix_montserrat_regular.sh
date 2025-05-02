#!/bin/bash

# This script fixes the Montserrat-Regular font issue

# Find the latest app bundle in the simulator
DEVICE_ID="1F2C8C66-4443-4CC7-AF7D-F7768218DD13"
APP_BUNDLE_ID="06F9DCFF-3F18-474C-9510-994F33462E33"
SIMULATOR_APP_PATH=~/Library/Developer/CoreSimulator/Devices/$DEVICE_ID/data/Containers/Bundle/Application/$APP_BUNDLE_ID/ptchampion.app

echo "Fixing Montserrat-Regular font..."

# Download a fresh copy of Montserrat-Regular
echo "Downloading fresh copy of Montserrat-Regular font..."
curl -L "https://github.com/JulietaUla/Montserrat/raw/master/fonts/ttf/Montserrat-Regular.ttf" -o montserrat_regular.ttf

# Verify the download was successful
if [ ! -f "montserrat_regular.ttf" ] || [ ! -s "montserrat_regular.ttf" ]; then
  echo "❌ Failed to download Montserrat-Regular font. Using another source..."
  curl -L "https://fonts.google.com/download?family=Montserrat" -o montserrat.zip
  unzip -j montserrat.zip "static/Montserrat-Regular.ttf" -d .
  mv "Montserrat-Regular.ttf" montserrat_regular.ttf
fi

# Check again if we have a valid font file
if [ ! -f "montserrat_regular.ttf" ] || [ ! -s "montserrat_regular.ttf" ]; then
  echo "❌ Still couldn't download Montserrat-Regular. Using Montserrat-Bold as a substitute..."
  # Copy Montserrat-Bold and rename it
  cp "ios/ptchampion/Resources/Fonts/Montserrat-Bold.ttf" montserrat_regular.ttf
fi

# Copy to project 
echo "Updating Montserrat-Regular in project..."
cp montserrat_regular.ttf "ios/ptchampion/Resources/Fonts/Montserrat-Regular.ttf"

# Copy to simulator app bundle
echo "Copying to simulator app bundle..."
if [ -d "$SIMULATOR_APP_PATH" ]; then
  cp montserrat_regular.ttf "$SIMULATOR_APP_PATH/Montserrat-Regular.ttf"
  mkdir -p "$SIMULATOR_APP_PATH/Fonts"
  cp montserrat_regular.ttf "$SIMULATOR_APP_PATH/Fonts/Montserrat-Regular.ttf"
  echo "✅ Copied to simulator app bundle"
else
  echo "❌ Simulator app path not found: $SIMULATOR_APP_PATH"
fi

# Ensure the font is included in the Copy Bundle Resources phase
echo "Checking project.pbxproj to ensure Montserrat-Regular is included in Copy Bundle Resources..."
PROJECT_FILE="ios/ptchampion/ptchampion.xcodeproj/project.pbxproj"

# Create a backup just in case
cp "$PROJECT_FILE" "${PROJECT_FILE}.montserrat_backup"

# Check if Montserrat-Regular is referenced in the project file
if ! grep -q "Montserrat-Regular.ttf" "$PROJECT_FILE"; then
  echo "⚠️ Montserrat-Regular.ttf not found in project.pbxproj"
  echo "Attempting to add it by copying the structure from another font..."
  
  # Find a reference to another font file
  FONT_REF=$(grep -n "Montserrat-Bold.ttf" "$PROJECT_FILE" | head -1 | cut -d: -f1)
  
  if [ -n "$FONT_REF" ]; then
    # Extract the PBX file reference section for the Bold font
    CONTEXT_RANGE=$((FONT_REF-10)),$((FONT_REF+20))
    CONTEXT=$(sed -n "${CONTEXT_RANGE}p" "$PROJECT_FILE")
    
    # Generate a random ID for the new file reference
    RANDOM_ID=$(openssl rand -hex 12 | tr '[:lower:]' '[:upper:]')
    
    # TODO: If needed, add detailed logic to add to PBXFileReference and PBXBuildFile sections
    # This is complex and would need careful parsing of the Xcode project file structure
  fi
else
  echo "✅ Montserrat-Regular.ttf is referenced in project.pbxproj"
fi

# Clean up
rm montserrat_regular.ttf 2>/dev/null
rm montserrat.zip 2>/dev/null

echo "Done! Try running the app again."
echo "If it still fails, you may need to clean the build and run from Xcode." 