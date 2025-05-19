#!/bin/bash

# Script to ensure design system components have proper visibility modifiers
# This fixes visibility issues that might cause linker errors

echo "🔄 Fixing visibility modifiers in design system components..."

# Directory to process
DS_DIR="PTDesignSystem"
COMPONENTS_DIR="$DS_DIR/Sources/Components"

# Make sure all component structs are marked public
for file in $COMPONENTS_DIR/*.swift; do
  if grep -q "struct PT" "$file"; then
    echo "Ensuring visibility in $file"
    
    # Make structs public if they aren't already
    sed -i '' 's/struct \(PT[A-Za-z]*\)/public struct \1/g' "$file"
    
    # Make initializers public if they aren't already
    sed -i '' 's/\(func\|init\)(/public \1(/g' "$file"
    
    # Make sure body var is public
    sed -i '' 's/var body:/public var body:/g' "$file"
    
    # Make enums within components public
    sed -i '' 's/enum \([A-Za-z]*\) {/public enum \1 {/g' "$file"
    
    echo "✅ Updated visibility in $file"
  fi
done

# Make sure ThemeManager has proper public modifiers
THEME_MANAGER="$DS_DIR/Sources/DesignTokens/ThemeManager.swift"
if [ -f "$THEME_MANAGER" ]; then
  echo "Ensuring visibility in ThemeManager"
  
  # Make sure all properties are public
  sed -i '' 's/@Published var/@Published public var/g' "$THEME_MANAGER"
  
  # Make sure all methods are public
  sed -i '' 's/func \([A-Za-z]*\)(/public func \1(/g' "$THEME_MANAGER"
  
  echo "✅ Updated visibility in ThemeManager"
fi

echo "🎉 Done fixing visibility modifiers. Please build the project to catch any remaining issues." 