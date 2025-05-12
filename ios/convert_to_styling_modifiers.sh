#!/bin/bash
# Script to search and replace old styling patterns with new modifiers
set -euo pipefail

PROJECT_DIR="$(pwd)/ios/ptchampion"
VIEWS_DIR="${PROJECT_DIR}/Views"
REPORT_FILE="${PROJECT_DIR}/styling_migration_report.txt"

echo "PT Champion Styling Migration Tool" > $REPORT_FILE
echo "===================================" >> $REPORT_FILE
echo "" >> $REPORT_FILE
echo "Running on $(date)" >> $REPORT_FILE
echo "" >> $REPORT_FILE

# Function to count matches
count_matches() {
    local pattern="$1"
    local count=$(grep -r "$pattern" "$VIEWS_DIR" --include="*.swift" | wc -l)
    echo $count
}

# Report initial stats
echo "Initial stats:" >> $REPORT_FILE
echo "- Font system calls: $(count_matches ".font(.system")" >> $REPORT_FILE
echo "- Color hex literals: $(count_matches "Color(hex:")" >> $REPORT_FILE
echo "- AppTheme typography: $(count_matches "AppTheme.GeneratedTypography")" >> $REPORT_FILE
echo "- Card modifiers needed: $(count_matches "PTCard")" >> $REPORT_FILE
echo "" >> $REPORT_FILE

# Create backup
echo "Creating backup of Views directory..." >> $REPORT_FILE
BACKUP_DIR="${PROJECT_DIR}/Views_backup_$(date +%Y%m%d_%H%M%S)"
cp -r "$VIEWS_DIR" "$BACKUP_DIR"
echo "Backup created at $BACKUP_DIR" >> $REPORT_FILE
echo "" >> $REPORT_FILE

echo "Performing replacements..." >> $REPORT_FILE

# FONT REPLACEMENTS
# System headings to typography headings
find "$VIEWS_DIR" -name "*.swift" -exec sed -i '' -E \
    -e 's/\.font\(\.title\.weight\(\.bold\)\)/\.heading1()/g' \
    -e 's/\.font\(\.title\.weight\(\.semibold\)\)/\.heading1()/g' \
    -e 's/\.font\(\.title2\.weight\(\.bold\)\)/\.heading2()/g' \
    -e 's/\.font\(\.title2\.weight\(\.semibold\)\)/\.heading2()/g' \
    -e 's/\.font\(\.title3\.weight\(\.bold\)\)/\.heading3()/g' \
    -e 's/\.font\(\.title3\.weight\(\.semibold\)\)/\.heading3()/g' \
    -e 's/\.font\(\.headline\)/\.heading4()/g' \
    -e 's/\.font\(\.headline\.weight\(\.bold\)\)/\.heading4()/g' \
    {} \;

# System body/text styles to typography styles
find "$VIEWS_DIR" -name "*.swift" -exec sed -i '' -E \
    -e 's/\.font\(\.body\)/\.body()/g' \
    -e 's/\.font\(\.body\.weight\(\.semibold\)\)/\.bodySemibold()/g' \
    -e 's/\.font\(\.body\.weight\(\.bold\)\)/\.bodyBold()/g' \
    -e 's/\.font\(\.subheadline\)/\.small()/g' \
    -e 's/\.font\(\.subheadline\.weight\(\.semibold\)\)/\.smallSemibold()/g' \
    -e 's/\.font\(\.footnote\)/\.caption()/g' \
    -e 's/\.font\(\.caption\)/\.caption()/g' \
    {} \;

# AppTheme.GeneratedTypography conversions
find "$VIEWS_DIR" -name "*.swift" -exec sed -i '' -E \
    -e 's/\.font\(AppTheme\.GeneratedTypography\.heading\(size: AppTheme\.GeneratedTypography\.heading1\)\)/\.heading1()/g' \
    -e 's/\.font\(AppTheme\.GeneratedTypography\.heading\(size: AppTheme\.GeneratedTypography\.heading2\)\)/\.heading2()/g' \
    -e 's/\.font\(AppTheme\.GeneratedTypography\.heading\(size: AppTheme\.GeneratedTypography\.heading3\)\)/\.heading3()/g' \
    -e 's/\.font\(AppTheme\.GeneratedTypography\.heading\(size: AppTheme\.GeneratedTypography\.heading4\)\)/\.heading4()/g' \
    -e 's/\.font\(AppTheme\.GeneratedTypography\.body\(\)\)/\.body()/g' \
    -e 's/\.font\(AppTheme\.GeneratedTypography\.body\(size: nil\)\)/\.body()/g' \
    -e 's/\.font\(AppTheme\.GeneratedTypography\.bodyBold\(\)\)/\.bodyBold()/g' \
    -e 's/\.font\(AppTheme\.GeneratedTypography\.bodyBold\(size: nil\)\)/\.bodyBold()/g' \
    -e 's/\.font\(AppTheme\.GeneratedTypography\.bodySemibold\(\)\)/\.bodySemibold()/g' \
    -e 's/\.font\(AppTheme\.GeneratedTypography\.bodySemibold\(size: nil\)\)/\.bodySemibold()/g' \
    -e 's/\.font\(AppTheme\.GeneratedTypography\.body\(size: AppTheme\.GeneratedTypography\.small\)\)/\.small()/g' \
    -e 's/\.font\(AppTheme\.GeneratedTypography\.caption\(\)\)/\.caption()/g' \
    -e 's/\.font\(AppTheme\.GeneratedTypography\.caption\(size: nil\)\)/\.caption()/g' \
    {} \;

# Replace explicit sizes with appropriate typography - now handles both 16 and 16.0 format 
find "$VIEWS_DIR" -name "*.swift" -exec sed -i '' -E \
    -e 's/\.font\(\.system\(size: (32|32\.0)(,|\))/\.heading1()/g' \
    -e 's/\.font\(\.system\(size: (24|24\.0)(,|\))/\.heading2()/g' \
    -e 's/\.font\(\.system\(size: (20|20\.0)(,|\))/\.heading3()/g' \
    -e 's/\.font\(\.system\(size: (18|18\.0)(,|\))/\.heading4()/g' \
    -e 's/\.font\(\.system\(size: (16|16\.0)(,|\))/\.body()/g' \
    -e 's/\.font\(\.system\(size: (14|14\.0)(,|\))/\.small()/g' \
    -e 's/\.font\(\.system\(size: (12|12\.0)(,|\))/\.caption()/g' \
    {} \;

# COLOR REPLACEMENTS
# Hard-coded colors to semantic colors
find "$VIEWS_DIR" -name "*.swift" -exec sed -i '' -E \
    -e 's/Color\(hex: "F4F1E6"\)/Color.cream/g' \
    -e 's/Color\(hex: "EDE9DB"\)/Color.creamDark/g' \
    -e 's/Color\(hex: "1E241E"\)/Color.deepOps/g' \
    -e 's/Color\(hex: "BFA24D"\)/Color.brassGold/g' \
    -e 's/Color\(hex: "E0D4A6"\)/Color.armyTan/g' \
    -e 's/Color\(hex: "C9CCA6"\)/Color.oliveMist/g' \
    -e 's/Color\(hex: "1E1E1E"\)/Color.commandBlack/g' \
    -e 's/Color\(hex: "4E5A48"\)/Color.tacticalGray/g' \
    -e 's/Color\(hex: "355E3B"\)/Color.hunterGreen/g' \
    {} \;

# SAFER PTCard REPLACEMENTS - First tag occurrences, then we'll handle them manually
echo "Tagging PTCard usages for manual review..." >> $REPORT_FILE
find "$VIEWS_DIR" -name "*.swift" -exec grep -l "PTCard" {} \; > /tmp/ptcard_files.txt

# Count how many files need PTCard replacements
PTCARD_FILE_COUNT=$(wc -l < /tmp/ptcard_files.txt | tr -d ' ')
echo "Found $PTCARD_FILE_COUNT files with PTCard usage" >> $REPORT_FILE

# Add TODO comments to each file with PTCard usages
if [ "$PTCARD_FILE_COUNT" -gt 0 ]; then
    while read -r file; do
        echo "Adding TODO markers to $file" >> $REPORT_FILE
        sed -i '' -E 's/PTCard\(/\/\/ TODO: Replace PTCard with .card() modifier\nVStack\(/g' "$file"
        sed -i '' -E 's/PTCard \{/\/\/ TODO: Replace PTCard with .card() modifier\nVStack \{/g' "$file"
    done < /tmp/ptcard_files.txt
fi

# SAFER CONTAINER APPROACH
# Rather than trying to auto-add container() to ScrollView, just tag main views for manual modification
MAIN_VIEWS=(
    "DashboardView.swift"
    "ProfileView.swift"
    "WorkoutHistoryView.swift"
    "LeaderboardView.swift"
    "SettingsView.swift"
)

for view in "${MAIN_VIEWS[@]}"; do
    if [ -f "$VIEWS_DIR/$view" ]; then
        echo "Adding TODO comment for .container() in $view" >> $REPORT_FILE
        # Insert a comment at the top of the file to remind about adding .container()
        sed -i '' '1s/^/\/\/ TODO: Add .container() modifier to the root content view\n/' "$VIEWS_DIR/$view"
    fi
done

# Report final stats
echo "" >> $REPORT_FILE
echo "Final stats:" >> $REPORT_FILE
echo "- Font system calls remaining: $(count_matches ".font(.system")" >> $REPORT_FILE
echo "- Color hex literals remaining: $(count_matches "Color(hex:")" >> $REPORT_FILE
echo "- AppTheme typography remaining: $(count_matches "AppTheme.GeneratedTypography")" >> $REPORT_FILE
echo "" >> $REPORT_FILE
echo "Migration completed on $(date)" >> $REPORT_FILE
echo "Please review changes carefully before committing." >> $REPORT_FILE
echo "Manual updates needed:" >> $REPORT_FILE
echo "1. Review all files with 'TODO: Replace PTCard' comments and add .card() modifier" >> $REPORT_FILE
echo "2. Review all files with 'TODO: Add .container()' comments to add container() to root views" >> $REPORT_FILE
echo "3. Run the app to test styling in both light/dark mode" >> $REPORT_FILE
echo "4. Review and fix any compile errors" >> $REPORT_FILE

echo "Script completed. See $REPORT_FILE for details."

# Fix for the chmod on this script - removed as it's not needed after the initial run
# Correct path would be: chmod +x "$(dirname "$0")/$(basename "$0")" 