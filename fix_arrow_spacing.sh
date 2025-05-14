#!/bin/bash

# Determine project root as the directory where this script resides
PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_ROOT"

# Function: remove spaces between '-' and '>' in arrow operator '->'
# Example: '- >'  or '-   >'  will become '->'
# We'll also preserve any trailing spacing after the operator for readability.

fix_arrow_spacing() {
  local file="$1"
  # Use perl for in-place editing, more robust than sed on mac with regex capture.
  perl -0777 -pi -e 's/-\s*>/->/g' "$file"
}

export -f fix_arrow_spacing

# Find all Swift files and apply the fix
find ios -name "*.swift" -type f -exec bash -c 'fix_arrow_spacing "$0"' {} \+

echo "Fixed spaced arrow operators (->) across Swift files." 