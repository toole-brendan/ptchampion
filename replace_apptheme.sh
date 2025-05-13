#!/bin/bash

# Script to replace AppTheme references with modern styling equivalents

echo "Starting AppTheme replacement script..."

# Find all Swift files with AppTheme references
echo "Finding files with AppTheme references..."
FILES=$(grep -r "AppTheme" ios/ptchampion/Views --include="*.swift" -l | sort)

# Processing files
echo "Processing found files:"
for FILE in $FILES; do
  echo "Processing: $FILE"
  
  # Replace common patterns
  # Colors
  sed -i '' 's/AppTheme\.GeneratedColors\.\([a-zA-Z0-9]*\)/Color\.\1/g' "$FILE"
  
  # Radius
  sed -i '' 's/AppTheme\.GeneratedRadius\.\([a-zA-Z0-9]*\)/CornerRadius\.\1/g' "$FILE"
  
  # Typography
  sed -i '' 's/AppTheme\.GeneratedTypography\.tiny/Typography\.caption/g' "$FILE"
  sed -i '' 's/AppTheme\.GeneratedTypography\.small/Typography\.small/g' "$FILE"
  sed -i '' 's/AppTheme\.GeneratedTypography\.body/Typography\.body/g' "$FILE"
  sed -i '' 's/AppTheme\.GeneratedTypography\.heading/Typography\.heading/g' "$FILE"
  sed -i '' 's/AppTheme\.GeneratedTypography\.heading1/Typography\.h1/g' "$FILE"
  sed -i '' 's/AppTheme\.GeneratedTypography\.heading2/Typography\.h2/g' "$FILE"
  sed -i '' 's/AppTheme\.GeneratedTypography\.heading3/Typography\.h3/g' "$FILE"
  sed -i '' 's/AppTheme\.GeneratedTypography\.heading4/Typography\.h4/g' "$FILE"
  
  # Spacing
  sed -i '' 's/AppTheme\.GeneratedSpacing\.\([a-zA-Z0-9]*\)/Spacing\.\1/g' "$FILE"
  
  # Shadows
  sed -i '' 's/AppTheme\.GeneratedShadow\.\([a-zA-Z0-9]*\)/Shadow\.\1/g' "$FILE"
done

echo "Replacement complete. Please verify changes and run tests."

# Log remaining instances that might need manual attention
echo "Checking for any remaining AppTheme references..."
grep -r "AppTheme" ios/ptchampion/Views --include="*.swift" | tee remaining_apptheme.txt

echo "Done. Any remaining AppTheme references are logged in remaining_apptheme.txt" 