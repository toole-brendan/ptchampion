#!/bin/bash

# Script to ensure all component style enums are properly public
# This is necessary for proper exposure of design system components

echo "🔄 Fixing component style enums in design system..."

# Directory to process
DS_DIR="PTDesignSystem"
COMPONENTS_DIR="$DS_DIR/Sources/Components"

# First, fix PTButton style enum
BUTTON_FILE="$COMPONENTS_DIR/PTButton.swift"
if [ -f "$BUTTON_FILE" ]; then
  echo "  Fixing PTButton styles..."
  # Make sure the ButtonStyle enum is public
  sed -i '' 's/enum ButtonStyle/public enum ButtonStyle/g' "$BUTTON_FILE"
  # Make sure all cases are accessible
  sed -i '' 's/case primary/public case primary/g' "$BUTTON_FILE"
  sed -i '' 's/case secondary/public case secondary/g' "$BUTTON_FILE"
  sed -i '' 's/case destructive/public case destructive/g' "$BUTTON_FILE"
fi

# Next, fix PTLabel style enum
LABEL_FILE="$COMPONENTS_DIR/PTLabel.swift"
if [ -f "$LABEL_FILE" ]; then
  echo "  Fixing PTLabel styles..."
  # Make sure the LabelStyle enum is public
  sed -i '' 's/enum LabelStyle/public enum LabelStyle/g' "$LABEL_FILE"
  # Make sure all cases are accessible
  sed -i '' 's/case heading/public case heading/g' "$LABEL_FILE"
  sed -i '' 's/case subheading/public case subheading/g' "$LABEL_FILE"
  sed -i '' 's/case body/public case body/g' "$LABEL_FILE"
  sed -i '' 's/case caption/public case caption/g' "$LABEL_FILE"
fi

echo "🎉 Done fixing component style enums. Please rebuild the project." 