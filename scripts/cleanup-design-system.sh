#!/bin/bash

# This script cleans up redundant styling files from the main app
# to ensure we're only using the Swift Package for design system

echo "🧹 Cleaning up redundant styling files from main app..."

# Path variables
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
MAIN_APP_DIR="$PROJECT_ROOT/ios/ptchampion"

# List of directories and files to be removed
REMOVE_LIST=(
  "$MAIN_APP_DIR/Generated"
  "$MAIN_APP_DIR/Theme"
  "$MAIN_APP_DIR/Theme.swift"
  "$MAIN_APP_DIR/Utils/Theme.swift"
  "$MAIN_APP_DIR/Utils/LegacyTheme.swift"
  "$MAIN_APP_DIR/Utils/GenerateTheme.swift"
  "$MAIN_APP_DIR/design-tokens.json"
)

# Remove each item if it exists
for item in "${REMOVE_LIST[@]}"; do
  if [ -e "$item" ]; then
    echo "🗑️  Removing $item"
    rm -rf "$item"
  fi
done

echo "✅ Cleanup complete!"
echo
echo "⚠️  IMPORTANT: You may need to update imports in your Swift files."
echo "   Replace 'import ...Theme...' with 'import PTDesignSystem'"
echo "   or more specific imports like 'import DesignTokens' and 'import Components'" 