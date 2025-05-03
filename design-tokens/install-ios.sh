#!/bin/bash
set -e

# Install iOS generated files from design-tokens
echo "Installing design tokens for iOS..."

# Create directories if they don't exist
mkdir -p ../ios/ptchampion/Generated
mkdir -p ../ios/ptchampion/Assets.xcassets/GeneratedColors

# Copy the files
cp -r build/ios/AppTheme+Generated.swift ../ios/ptchampion/Generated/
cp -r build/ios/Colors.xcassets/* ../ios/ptchampion/Assets.xcassets/GeneratedColors/

echo "✅ iOS design tokens installed successfully!" 