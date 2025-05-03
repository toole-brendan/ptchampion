#!/bin/bash

# Install the generated token files to the web project
# Usage: ./install-web.sh

# Build the tokens first
npm run build

# CSS variables file
SOURCE_CSS="build/web/variables.css"
TARGET_CSS="../web/src/components/ui/theme.css"

# Create target directory if it doesn't exist
mkdir -p "$(dirname "$TARGET_CSS")"

# Copy the CSS file
echo "Copying CSS file to $TARGET_CSS..."
cp "$SOURCE_CSS" "$TARGET_CSS"

echo "✅ Tokens successfully installed to web project."
echo "Remember to import the theme.css file in your main CSS file." 