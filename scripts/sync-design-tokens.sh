#!/bin/bash

# This script extracts design tokens from Tailwind config and generates iOS Swift code

echo "🎨 Syncing design tokens from web to iOS..."

# Path variables
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
WEB_DIR="$PROJECT_ROOT/web"
IOS_DIR="$PROJECT_ROOT/ios/ptchampion"
TOKENS_JSON="$IOS_DIR/design-tokens.json"

# Check if the web directory exists
if [ ! -d "$WEB_DIR" ]; then
  echo "❌ Error: Web directory not found at $WEB_DIR"
  exit 1
fi

# Extract colors from Tailwind config
echo "📌 Extracting design tokens from Tailwind config..."
cd "$WEB_DIR" || exit 1

# If you have npx installed, uncomment this to extract tokens directly
# npx tailwindcss --config ./tailwind.config.js --list-config | jq '.theme.colors' > "$TOKENS_JSON"

# If you can't extract directly from Tailwind, the tokens.json in ios/ptchampion is a fallback

# Run the iOS token generation script
echo "📱 Generating Swift code from design tokens..."
cd "$IOS_DIR" || exit 1

# Make sure the generator script is executable
chmod +x "$IOS_DIR/Utils/GenerateTheme.swift"

# Run the generator
"$IOS_DIR/Utils/GenerateTheme.swift"

echo "✅ Design token sync complete!" 