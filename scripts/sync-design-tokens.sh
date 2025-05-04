#!/bin/bash

# This script syncs design tokens from project root to iOS PTDesignSystem package

echo "🎨 Syncing design tokens to iOS Design System Package..."

# Path variables
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ROOT_TOKENS_JSON="$PROJECT_ROOT/design-tokens.json"
DESIGN_SYSTEM_DIR="$PROJECT_ROOT/ios/PTDesignSystem"
GEN_DIR="$DESIGN_SYSTEM_DIR/Sources/DesignTokens/Generated"
RESOURCES_DIR="$DESIGN_SYSTEM_DIR/Sources/DesignTokens/Resources"
COLORS_DIR="$RESOURCES_DIR/Colors.xcassets"

# Verify root tokens file exists
if [ ! -f "$ROOT_TOKENS_JSON" ]; then
  echo "❌ Error: Root design tokens file not found at $ROOT_TOKENS_JSON"
  exit 1
fi

# Create directories if they don't exist
mkdir -p "$GEN_DIR"
mkdir -p "$COLORS_DIR"

# Convert design tokens to Swift
echo "📱 Generating Swift code from design tokens..."

# Using Style Dictionary
cd "$PROJECT_ROOT/design-tokens" || exit 1
npx style-dictionary build --config style-dictionary.config.js

echo "✅ Design tokens synced to PTDesignSystem package successfully!" 