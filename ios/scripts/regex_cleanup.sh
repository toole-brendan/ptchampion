#!/bin/bash
# regex_cleanup.sh - Automated styling migration cleanup script
# 
# This script performs regex-based replacements to clean up the iOS styling code
# It should be run from the repository root directory

set -e  # Exit on error

echo "========== PT Champion – Automated Styling Cleanup =========="
echo "$(date)"
echo

# Make sure we're in the right directory
if [ ! -d "ios" ]; then
  echo "Error: This script must be run from the repository root"
  exit 1
fi

# Install sd if not available (uncommment if needed)
# if ! command -v sd &> /dev/null; then
#    echo "Installing sd tool..."
#    brew install sd
# fi

# Check if ripgrep is available
if ! command -v rg &> /dev/null; then
  echo "Error: ripgrep (rg) is required. Install with 'brew install ripgrep'"
  exit 1
fi

# Create scripts directory if it doesn't exist
mkdir -p ios/scripts

echo "🔍 Step 1: Fixing PTCard -> card() conversions..."

# Fix PTCard -> card() conversions in a simplified way
# Find files with PTCard TODO comments
find ios -name "*.swift" -type f -exec grep -l "TODO: Replace PTCard" {} \; | while read file; do
  # Replace the VStack with style with a plain VStack
  sed -i '' -E 's/([ \t]*)\/\/ TODO: Replace PTCard with \.card\(\) → manual review/\1\/\/ FIXED: PTCard replaced/g' "$file"
  sed -i '' -E 's/([ \t]*)VStack\(style: [^)]+\) \{/\1VStack {/g' "$file"
  
  # Add .card() after the closing brace
  # This simplified version assumes a consistent pattern and proper nesting
  grep -n "VStack {" "$file" | while read -r line_info; do
    line_num=$(echo "$line_info" | cut -d: -f1)
    indent=$(grep -o "^[ \t]*" "$file" | sed -n "${line_num}p")
    
    # Find matching closing brace
    brace_line=$(tail -n +$line_num "$file" | grep -n "^${indent}}" | head -1 | cut -d: -f1)
    if [ -n "$brace_line" ]; then
      actual_line=$((line_num + brace_line - 1))
      sed -i '' "${actual_line}s/}/}\n${indent}.card()/g" "$file"
    fi
  done
done

echo "✅ PTCard fixes applied"

echo "🔍 Step 2: Replacing AppTheme references..."

# Process token map to replace AppTheme references
while IFS=, read -r old new || [ -n "$old" ]; do
  if [[ -n $old && -n $new ]]; then  # Skip empty lines
    echo "  • Replacing: $old → $new"
    # Simple, literal replacements without complex regex
    find ios -name "*.swift" -type f -exec sed -i '' "s/$old/$new/g" {} \;
  fi
done < ios/scripts/token-map.csv

echo "✅ AppTheme replacements complete"

# Fix common typography syntax issues
echo "🔍 Step 3: Fixing typography syntax..."

# Fix .body().weight -> .body(weight  
find ios -name "*.swift" -type f -exec sed -i '' 's/\.body() weight:/\.body(weight:/g' {} \;
find ios -name "*.swift" -type f -exec sed -i '' 's/\.small() weight:/\.small(weight:/g' {} \;
find ios -name "*.swift" -type f -exec sed -i '' 's/\.heading1() weight:/\.heading1(weight:/g' {} \;
find ios -name "*.swift" -type f -exec sed -i '' 's/\.heading2() weight:/\.heading2(weight:/g' {} \;
find ios -name "*.swift" -type f -exec sed -i '' 's/\.heading3() weight:/\.heading3(weight:/g' {} \;
find ios -name "*.swift" -type f -exec sed -i '' 's/\.heading4() weight:/\.heading4(weight:/g' {} \;

# Fix for bodySemibold special case
find ios -name "*.swift" -type f -exec sed -i '' 's/AppTheme.GeneratedTypography.bodySemibold(size: [^)]*)/\.bodySemibold()/g' {} \;

# Fix for heading special cases
find ios -name "*.swift" -type f -exec sed -i '' 's/AppTheme.GeneratedTypography.heading(size: AppTheme.GeneratedTypography.heading1)/\.heading1()/g' {} \;
find ios -name "*.swift" -type f -exec sed -i '' 's/AppTheme.GeneratedTypography.heading(size: AppTheme.GeneratedTypography.heading2)/\.heading2()/g' {} \;
find ios -name "*.swift" -type f -exec sed -i '' 's/AppTheme.GeneratedTypography.heading(size: AppTheme.GeneratedTypography.heading3)/\.heading3()/g' {} \;
find ios -name "*.swift" -type f -exec sed -i '' 's/AppTheme.GeneratedTypography.heading(size: AppTheme.GeneratedTypography.heading4)/\.heading4()/g' {} \;

# Fix double parentheses in typography calls
find ios -name "*.swift" -type f -exec sed -i '' 's/\.body())/.body()/g' {} \;
find ios -name "*.swift" -type f -exec sed -i '' 's/\.small())/.small()/g' {} \;
find ios -name "*.swift" -type f -exec sed -i '' 's/\.heading1())/.heading1()/g' {} \;
find ios -name "*.swift" -type f -exec sed -i '' 's/\.heading2())/.heading2()/g' {} \;
find ios -name "*.swift" -type f -exec sed -i '' 's/\.heading3())/.heading3()/g' {} \;
find ios -name "*.swift" -type f -exec sed -i '' 's/\.heading4())/.heading4()/g' {} \;
find ios -name "*.swift" -type f -exec sed -i '' 's/\.caption())/.caption()/g' {} \;

echo "✅ Typography fixes applied"

echo "🔍 Step 4: Adding .container() to main views..."
# Add .container() after navigationBarTitleDisplayMode in main view files
find ios -name "*View.swift" -type f | while read file; do
  # Check if file contains navigationBarTitleDisplayMode but not container()
  if grep -q "navigationBarTitleDisplayMode" "$file" && ! grep -q "\.container()" "$file"; then
    # Add .container() after the navigationBarTitleDisplayMode line
    sed -i '' '/navigationBarTitleDisplayMode/ s/$/.container()/g' "$file"
  fi
done

echo "📝 All regex-based replacements completed"
echo
echo "Run the migration script to see the current status:"
echo "bash ios/complete_styling_migration.sh" 