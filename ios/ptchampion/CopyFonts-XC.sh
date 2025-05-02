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
