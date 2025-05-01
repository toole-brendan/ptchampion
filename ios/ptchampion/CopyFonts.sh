#!/bin/sh

# Create destination directory if it doesn't exist
mkdir -p "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"

# Copy font files from Resources/Fonts to the app bundle
FONTS_DIR="${SRCROOT}/ptchampion/Resources/Fonts"
DEST_DIR="${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"

echo "Copying fonts from ${FONTS_DIR} to ${DEST_DIR}"

# Copy all font files
cp "${FONTS_DIR}"/*.ttf "${DEST_DIR}/"
cp "${FONTS_DIR}"/*.otf "${DEST_DIR}/" 2>/dev/null || :

# List the fonts that were copied
echo "Fonts copied to app bundle:"
ls -la "${DEST_DIR}"/*.ttf "${DEST_DIR}"/*.otf 2>/dev/null || :

exit 0 