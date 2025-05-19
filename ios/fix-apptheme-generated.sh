#!/bin/bash

# Script to fix duplicate modifiers in AppTheme+Generated.swift
# This script directly edits the file to correct the enum declarations

echo "🔄 Fixing duplicate modifiers in AppTheme+Generated.swift..."

# File to fix
FILE="PTDesignSystem/Sources/DesignTokens/Generated/AppTheme+Generated.swift"

if [ -f "$FILE" ]; then
  echo "  Reading current file content..."
  
  # Create a temporary file for the fixed content
  TMP_FILE=$(mktemp)
  
  # Read the file line by line and fix the problematic lines
  while IFS= read -r line; do
    # Fix lines with "public public enum" or other duplicate modifiers
    if [[ $line == *"public public"* ]]; then
      # Replace duplicate public modifiers
      fixed_line=$(echo "$line" | sed 's/public public/public/g')
      echo "$fixed_line" >> "$TMP_FILE"
    # Fix lines with "public enum Generated" (to make them just "enum Generated")
    elif [[ $line == *"public enum Generated"* ]]; then
      # Remove the public modifier before Generated, as it's inside a public extension
      fixed_line=$(echo "$line" | sed 's/public enum Generated/enum Generated/g')
      echo "$fixed_line" >> "$TMP_FILE"
    else
      # Keep the line as is
      echo "$line" >> "$TMP_FILE"
    fi
  done < "$FILE"
  
  # Replace the original file with the fixed version
  mv "$TMP_FILE" "$FILE"
  
  echo "  ✅ Fixed duplicate modifiers in AppTheme+Generated.swift"
else
  echo "  ❌ File not found: $FILE"
fi

echo "🎉 Done fixing AppTheme+Generated.swift. Please rebuild the project." 