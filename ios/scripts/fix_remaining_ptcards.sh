#!/bin/bash
# Script to fix remaining PTCard references
# This should be run from the repository root

set -e # Exit on error

echo "========== PT Champion – PTCard Cleanup =========="
echo "$(date)"
echo

# List of files with remaining PTCard references (from the migration report)
ptcard_files=(
  "ios/ptchampion/Views/History/WorkoutChartView.swift"
  "ios/ptchampion/Views/History/WorkoutStreaksView.swift"
  "ios/ptchampion/Views/History/WorkoutHistoryView.swift"
  "ios/ptchampion/Views/ComponentGalleryView.swift"
  "ios/ptchampion/Views/Leaderboards/LeaderboardRowPlaceholder.swift"
  "ios/ptchampion/Views/Leaderboards/LeaderboardRowView.swift"
)

# Process each file
for file in "${ptcard_files[@]}"; do
  echo "🔍 Processing $file..."
  
  # Replace the VStack with style with a plain VStack
  sed -i '' -E 's/([ \t]*)\/\/ TODO: Replace PTCard with \.card\(\) → manual review/\1\/\/ FIXED: PTCard replaced/g' "$file"
  sed -i '' -E 's/([ \t]*)VStack\(style: [^)]+\) \{/\1VStack {/g' "$file"
  
  # Add .card() after the closing brace
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
  
  echo "✅ Fixed $file"
done

echo
echo "🎉 PTCard cleanup completed!"
echo "Run the migration script to check the final status:"
echo "bash ios/complete_styling_migration.sh" 