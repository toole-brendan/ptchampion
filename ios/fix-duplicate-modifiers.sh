#!/bin/bash

# Script to fix duplicate public modifiers in the design system files
# This is needed after running the fix-module-references.sh script

echo "🔄 Fixing duplicate public modifiers in design system files..."

# Fix AppTheme+Generated.swift
APPTHEME_GEN="PTDesignSystem/Sources/DesignTokens/Generated/AppTheme+Generated.swift"
if [ -f "$APPTHEME_GEN" ]; then
  echo "  Fixing duplicate modifiers in AppTheme+Generated.swift"
  
  # Replace 'public public' with just 'public'
  sed -i '' 's/public public/public/g' "$APPTHEME_GEN"
  
  # Make sure all enum declarations within AppTheme are public
  sed -i '' 's/enum Generated/public enum Generated/g' "$APPTHEME_GEN"
  
  echo "  ✅ Fixed duplicate modifiers in AppTheme+Generated.swift"
fi

# Check for any other files with duplicate public modifiers
echo "🔍 Checking for other files with duplicate modifiers..."

# Find all Swift files in PTDesignSystem and fix any duplicate public modifiers
find "PTDesignSystem" -name "*.swift" -type f | while read -r file; do
  if grep -q "public public" "$file"; then
    echo "  Fixing duplicate modifiers in $file"
    sed -i '' 's/public public/public/g' "$file"
    echo "  ✅ Fixed duplicate modifiers in $file"
  fi
done

echo "🎉 Done fixing duplicate modifiers. Please build the project to verify the fixes." 