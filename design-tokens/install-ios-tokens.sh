#!/bin/bash
set -e

# Install iOS generated files into Swift Package
echo "Installing design tokens for iOS..."

# Ensure the destination directories exist
mkdir -p ../ios/PTDesignSystem/Sources/DesignTokens/Generated
mkdir -p ../ios/PTDesignSystem/Sources/DesignTokens/Resources/Colors.xcassets

# Run the style dictionary build with the updated configuration
node build-tokens.updated.js

echo "✅ iOS design tokens installed successfully!" 