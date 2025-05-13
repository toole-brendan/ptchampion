#!/usr/bin/env bash
# batch_fix_specific_file.sh - Focused tool to clean up a single Swift file
#
# Usage:
#   bash batch_fix_specific_file.sh path/to/your/file.swift
#
# This will:
# 1. Create a backup of the file
# 2. Apply all known replacements to the single file
# 3. Show a diff of what was changed

set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Error: Please specify a Swift file to process"
  echo "Usage: bash $0 path/to/your/file.swift"
  exit 1
fi

FILE="$1"

if [ ! -f "$FILE" ]; then
  echo "Error: File '$FILE' doesn't exist"
  exit 1
fi

# Create backup with timestamp
BACKUP="${FILE}.bak.$(date +%Y%m%d_%H%M%S)"
cp "$FILE" "$BACKUP"
echo "✅ Created backup at $BACKUP"

# Apply replacements to the file
echo "🔄 Processing $FILE..."

# Typography replacements
sed -i '' -E \
  -e 's/\.font\(\.headline\)/\.heading4()/g' \
  -e 's/\.font\(\.headline\.weight\(\.bold\)\)/\.heading4Bold()/g' \
  -e 's/\.font\(\.footnote\)/\.caption()/g' \
  -e 's/\.font\(\.body\)/\.body()/g' \
  -e 's/\.font\(\.body\.weight\(\.semibold\)\)/\.bodySemibold()/g' \
  -e 's/\.font\(\.body\.weight\(\.bold\)\)/\.bodyBold()/g' \
  -e 's/\.font\(\.subheadline\)/\.small()/g' \
  -e 's/\.font\(\.caption\)/\.caption()/g' \
  -e 's/AppTheme\.GeneratedTypography\.caption\(\)/\.caption()/g' \
  -e 's/AppTheme\.GeneratedTypography\.heading\(size: AppTheme\.GeneratedTypography\.heading1\)/\.heading1()/g' \
  -e 's/AppTheme\.GeneratedTypography\.heading\(size: AppTheme\.GeneratedTypography\.heading2\)/\.heading2()/g' \
  -e 's/AppTheme\.GeneratedTypography\.heading\(size: AppTheme\.GeneratedTypography\.heading3\)/\.heading3()/g' \
  -e 's/AppTheme\.GeneratedTypography\.heading\(size: AppTheme\.GeneratedTypography\.heading4\)/\.heading4()/g' \
  -e 's/AppTheme\.GeneratedTypography\.body\(\)/\.body()/g' \
  -e 's/AppTheme\.GeneratedTypography\.bodyBold\(\)/\.bodyBold()/g' \
  -e 's/AppTheme\.GeneratedTypography\.bodySemibold\(\)/\.bodySemibold()/g' \
  -e 's/AppTheme\.GeneratedTypography\.caption\(\)/\.caption()/g' \
  "$FILE"

# Color replacements
sed -i '' -E \
  -e 's/AppTheme\.GeneratedColors\.textPrimary/Color.textPrimary/g' \
  -e 's/AppTheme\.GeneratedColors\.textSecondary/Color.textSecondary/g' \
  -e 's/AppTheme\.GeneratedColors\.textTertiary/Color.textTertiary/g' \
  -e 's/AppTheme\.GeneratedColors\.cardBackground/Color.cardBackground/g' \
  -e 's/AppTheme\.GeneratedColors\.brassGold/Color.brassGold/g' \
  -e 's/AppTheme\.GeneratedColors\.background/Color.background/g' \
  -e 's/AppTheme\.GeneratedColors\.iconSecondary/Color.iconSecondary/g' \
  -e 's/AppTheme\.GeneratedColors\.iconPrimary/Color.iconPrimary/g' \
  -e 's/AppTheme\.GeneratedColors\.cream/Color.cream/g' \
  -e 's/AppTheme\.GeneratedColors\.creamDark/Color.creamDark/g' \
  -e 's/AppTheme\.GeneratedColors\.deepOps/Color.deepOps/g' \
  -e 's/AppTheme\.GeneratedColors\.armyTan/Color.armyTan/g' \
  -e 's/AppTheme\.GeneratedColors\.oliveMist/Color.oliveMist/g' \
  -e 's/AppTheme\.GeneratedColors\.commandBlack/Color.commandBlack/g' \
  -e 's/AppTheme\.GeneratedColors\.tacticalGray/Color.tacticalGray/g' \
  -e 's/AppTheme\.GeneratedColors\.hunterGreen/Color.hunterGreen/g' \
  "$FILE"

# Spacing replacements
sed -i '' -E \
  -e 's/AppTheme\.GeneratedSpacing\.contentPadding/Spacing.contentPadding/g' \
  -e 's/AppTheme\.GeneratedSpacing\.itemSpacing/Spacing.itemSpacing/g' \
  -e 's/AppTheme\.GeneratedSpacing\.cardGap/Spacing.cardGap/g' \
  -e 's/AppTheme\.GeneratedSpacing\.medium/Spacing.medium/g' \
  -e 's/AppTheme\.GeneratedSpacing\.small/Spacing.small/g' \
  -e 's/AppTheme\.GeneratedSpacing\.large/Spacing.large/g' \
  -e 's/AppTheme\.GeneratedSpacing\.extraSmall/Spacing.extraSmall/g' \
  -e 's/AppTheme\.GeneratedSpacing\.extraLarge/Spacing.extraLarge/g' \
  "$FILE"

# Radius replacements
sed -i '' -E \
  -e 's/AppTheme\.GeneratedRadius\.medium/CornerRadius.medium/g' \
  -e 's/AppTheme\.GeneratedRadius\.button/CornerRadius.button/g' \
  -e 's/AppTheme\.GeneratedRadius\.small/CornerRadius.small/g' \
  -e 's/AppTheme\.GeneratedRadius\.large/CornerRadius.large/g' \
  "$FILE"

# Tag PTCard references to make manual changes easier
sed -i '' -E 's/PTCard\(/\/\/ TODO: Replace PTCard with .card() → manual review\nVStack(/' "$FILE"

# Show differences
echo
echo "📄 Changes made to $FILE:"
diff -u "$BACKUP" "$FILE" || true

# Count remaining AppTheme references
REMAINING_APPTHEME=$(grep -c "AppTheme" "$FILE" || echo 0)
REMAINING_PTCARD=$(grep -c "PTCard" "$FILE" || echo 0)

echo
echo "Cleanup status for $FILE:"
echo "• AppTheme references remaining: $REMAINING_APPTHEME"
echo "• PTCard references remaining: $REMAINING_PTCARD"

if [ "$REMAINING_APPTHEME" -eq 0 ] && [ "$REMAINING_PTCARD" -eq 0 ]; then
  echo "✅ File is fully migrated!"
else
  echo "⚠️  Manual work still needed - check the diff above"
fi 