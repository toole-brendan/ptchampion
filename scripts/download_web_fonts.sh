#!/bin/bash

# Script to download Futura PT fonts for iOS app
# This is a placeholder - you'd normally download from your official font source,
# or from Adobe Fonts if you have a license

# Define the destination directory
FONT_DIR="ios/ptchampion/Resources/Fonts"
TEMP_DIR="/tmp/futura_fonts"

# Create directories if they don't exist
mkdir -p "$FONT_DIR"
mkdir -p "$TEMP_DIR"

# Define font files needed
FONTS=(
  "FuturaPT-Book.ttf"
  "FuturaPT-Medium.ttf"
  "FuturaPT-Demi.ttf"
  "FuturaPT-Bold.ttf"
)

# Check if fonts already exist
ALL_FONTS_EXIST=true
for FONT in "${FONTS[@]}"; do
  if [ ! -f "$FONT_DIR/$FONT" ]; then
    ALL_FONTS_EXIST=false
    echo "Missing font: $FONT"
  fi
done

if [ "$ALL_FONTS_EXIST" = true ]; then
  echo "All Futura PT fonts already exist in $FONT_DIR"
  exit 0
fi

echo "Some fonts are missing. Please download Futura PT fonts from your official font source."
echo "For this project, check if they exist in:"
echo "- web/public/fonts/futura"
echo "- downloaded_fonts directory"
echo "- or your Adobe Fonts account if you have a license"

# Copy from web fonts directory if they exist
WEB_FONT_DIR="web/public/fonts/futura"
if [ -d "$WEB_FONT_DIR" ]; then
  echo "Checking web font directory..."
  for FONT in "${FONTS[@]}"; do
    if [ -f "$WEB_FONT_DIR/$FONT" ]; then
      echo "Copying $FONT from web directory"
      cp "$WEB_FONT_DIR/$FONT" "$FONT_DIR/"
    fi
  done
fi

# Check again if we have all fonts
ALL_FONTS_EXIST=true
for FONT in "${FONTS[@]}"; do
  if [ ! -f "$FONT_DIR/$FONT" ]; then
    ALL_FONTS_EXIST=false
    break
  fi
done

if [ "$ALL_FONTS_EXIST" = true ]; then
  echo "All fonts copied successfully!"
  exit 0
else
  echo "Some fonts are still missing. Please add them manually to $FONT_DIR"
  echo "Missing fonts:"
  for FONT in "${FONTS[@]}"; do
    if [ ! -f "$FONT_DIR/$FONT" ]; then
      echo "- $FONT"
    fi
  done
  exit 1
fi 