#!/bin/bash

# Script to fix PreviewProvider issues in design system components
# When implementing PreviewProvider in a public module, the 'previews' property must be public

echo "🔄 Fixing PreviewProvider issues in design system components..."

# Directory to process
DS_DIR="PTDesignSystem"
COMPONENTS_DIR="$DS_DIR/Sources/Components"

# Fix preview provider in component files
find "$COMPONENTS_DIR" -name "*.swift" -type f | while read -r file; do
  # Check if the file contains a PreviewProvider
  if grep -q "PreviewProvider" "$file"; then
    echo "  Fixing PreviewProvider in $(basename "$file")"
    
    # Replace 'static var previews' with 'public static var previews'
    sed -i '' 's/static var previews/public static var previews/g' "$file"
    
    echo "  ✅ Fixed PreviewProvider in $(basename "$file")"
  fi
done

echo "🎉 Done fixing PreviewProvider issues. Please build the project to verify the fixes." 