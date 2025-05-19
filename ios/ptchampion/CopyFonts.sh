#!/bin/sh

# Script for copying fonts to the app bundle, with error checking and verbose output

# Create destination directories if they don't exist
mkdir -p "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
mkdir -p "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/Fonts"

# Font source directory
FONTS_DIR="${SRCROOT}/ptchampion/Resources/Fonts"
# Main app bundle destination
DEST_DIR="${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
# Fonts subdirectory in app bundle
FONTS_DEST_DIR="${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/Fonts"

echo "================================================"
echo "Font copying started"
echo "Copying fonts from ${FONTS_DIR} to:"
echo " - ${DEST_DIR} (root)"
echo " - ${FONTS_DEST_DIR} (fonts dir)"
echo "================================================"

# First check if the source directory exists
if [ ! -d "${FONTS_DIR}" ]; then
    echo "ERROR: Source fonts directory does not exist: ${FONTS_DIR}"
    echo "Creating the directory..."
    mkdir -p "${FONTS_DIR}"
    
    # Check if font files are present after directory creation
    FONT_COUNT=$(ls -1 "${FONTS_DIR}"/*.ttf 2>/dev/null | wc -l)
    if [ $FONT_COUNT -eq 0 ]; then
        echo "WARNING: No TTF fonts found in ${FONTS_DIR}"
        echo "You may need to run the fix-fonts.sh script"
    fi
fi

# List fonts to be copied
echo "Fonts to be copied:"
ls -la "${FONTS_DIR}"/*.ttf "${FONTS_DIR}"/*.otf 2>/dev/null || echo "No font files found!"

# Copy all TTF font files to both locations with error handling
echo "Copying TTF fonts to app bundle root..."
for font in "${FONTS_DIR}"/*.ttf; do
    if [ -f "$font" ]; then
        echo "Copying $(basename "$font")"
        cp "$font" "${DEST_DIR}/" && echo "  ✅ Copied to root" || echo "  ❌ Failed to copy to root"
        cp "$font" "${FONTS_DEST_DIR}/" && echo "  ✅ Copied to Fonts/ dir" || echo "  ❌ Failed to copy to Fonts/ dir"
    fi
done

# Copy all OTF font files to both locations with error handling
echo "Copying OTF fonts to app bundle root..."
for font in "${FONTS_DIR}"/*.otf; do
    if [ -f "$font" ]; then
        echo "Copying $(basename "$font")"
        cp "$font" "${DEST_DIR}/" && echo "  ✅ Copied to root" || echo "  ❌ Failed to copy to root"
        cp "$font" "${FONTS_DEST_DIR}/" && echo "  ✅ Copied to Fonts/ dir" || echo "  ❌ Failed to copy to Fonts/ dir"
    fi
done

# Verify files were copied correctly
echo "================================================"
echo "Fonts copied to app bundle. Verifying:"
echo "Root directory:"
ls -la "${DEST_DIR}"/*.ttf "${DEST_DIR}"/*.otf 2>/dev/null || echo "No font files found in root!"
echo "Fonts subdirectory:"
ls -la "${FONTS_DEST_DIR}"/*.ttf "${FONTS_DEST_DIR}"/*.otf 2>/dev/null || echo "No font files found in Fonts subdirectory!"
echo "================================================"

exit 0 