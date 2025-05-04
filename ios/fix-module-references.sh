#!/bin/bash

# Script to fix module references in Swift files
# This removes explicit module qualifiers that are causing linker errors

echo "🔄 Fixing module references in Swift files..."

# Directory to process
APP_DIR="ptchampion"
DS_DIR="PTDesignSystem"

# Fix module references in app files
echo "🔧 Removing explicit module qualifiers in app files..."

find "$APP_DIR" -name "*.swift" -type f | while read -r file; do
  echo "  Checking $file"
  
  # Remove Components. prefix from all component references
  sed -i '' 's/Components\.PT/PT/g' "$file"
  
  # Remove DesignTokens. prefix from AppTheme references
  sed -i '' 's/DesignTokens\.AppTheme/AppTheme/g' "$file"
  
  # Remove DesignTokens. prefix from ThemeManager references
  sed -i '' 's/DesignTokens\.ThemeManager/ThemeManager/g' "$file"
done

# Fix module references in design system files
echo "🔧 Ensuring proper visibility in design system files..."

# Make sure all component struct and functions in design system are marked public
find "$DS_DIR/Sources/Components" -name "*.swift" -type f | while read -r file; do
  echo "  Making types public in $file"
  
  # Make struct declarations public
  sed -i '' 's/struct \(PT[A-Za-z]*\)/public struct \1/g' "$file"
  
  # Make enum declarations public
  sed -i '' 's/enum \([A-Za-z]*\)/public enum \1/g' "$file"
  
  # Make init methods public
  sed -i '' 's/\(init(.*)\)/public \1/g' "$file"
  
  # Make computed properties public
  sed -i '' 's/var body:/public var body:/g' "$file"
done

# Update ThemeManager to ensure it has proper public modifiers
THEME_MANAGER="$DS_DIR/Sources/DesignTokens/ThemeManager.swift"
if [ -f "$THEME_MANAGER" ]; then
  echo "  Updating visibility in ThemeManager.swift"
  
  # Make sure class is public
  sed -i '' 's/final class ThemeManager/public final class ThemeManager/g' "$THEME_MANAGER"
  
  # Make sure properties are public
  sed -i '' 's/@Published var/@Published public var/g' "$THEME_MANAGER"
  
  # Make sure functions are public
  sed -i '' 's/func \([A-Za-z]*\)/public func \1/g' "$THEME_MANAGER"
fi

# Update AppTheme to ensure it has proper public modifiers
APPTHEME="$DS_DIR/Sources/DesignTokens/AppTheme.swift"
if [ -f "$APPTHEME" ]; then
  echo "  Updating visibility in AppTheme.swift"
  
  # Make sure struct is public
  sed -i '' 's/struct AppTheme/public struct AppTheme/g' "$APPTHEME"
  
  # Make sure nested types and extensions are public
  sed -i '' 's/extension View/public extension View/g' "$APPTHEME"
  sed -i '' 's/enum \([A-Za-z]*\)/public enum \1/g' "$APPTHEME"
fi

# Update Generated AppTheme to ensure it has proper public modifiers
APPTHEME_GEN="$DS_DIR/Sources/DesignTokens/Generated/AppTheme+Generated.swift"
if [ -f "$APPTHEME_GEN" ]; then
  echo "  Updating visibility in AppTheme+Generated.swift"
  
  # Make sure all static properties are public
  sed -i '' 's/static let/public static let/g' "$APPTHEME_GEN"
  sed -i '' 's/static var/public static var/g' "$APPTHEME_GEN"
  
  # Make sure all static functions are public
  sed -i '' 's/static func/public static func/g' "$APPTHEME_GEN"
fi

echo "🎉 Done fixing module references. Please build the project to catch any remaining issues." 