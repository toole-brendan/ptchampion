#!/bin/bash
# Script to fix WorkoutChartView.swift syntax issues
# This should be run from the repository root

set -e # Exit on error

echo "========== PT Champion – Chart Syntax Cleanup =========="
echo "$(date)"
echo

# List of files to fix
fix_files=(
  "ios/ptchampion/Views/History/WorkoutChartView.swift"
  "ios/ptchampion/Views/History/WorkoutStreaksView.swift"
  "ios/ptchampion/Views/History/WorkoutHistoryView.swift"
  "ios/ptchampion/Views/ComponentGalleryView.swift"
  "ios/ptchampion/Views/Leaderboards/LeaderboardRowPlaceholder.swift"
  "ios/ptchampion/Views/Leaderboards/LeaderboardRowView.swift"
)

for file in "${fix_files[@]}"; do
  echo "🔍 Processing $file..."
  
  # Replace the whole file with a fixed version - manual approach only for the problematic files
  # Create a temporary file
  temp_file="${file}.tmp"
  
  # Use grep to find and keep instances of "PTCard" in the file
  grep -n "PTCard" "$file" > "${temp_file}_ptcard_lines"
  
  # If the file has PTCard references
  if [ -s "${temp_file}_ptcard_lines" ]; then
    # Read the file line by line
    line_number=0
    while IFS= read -r line; do
      line_number=$((line_number + 1))
      
      # Replace TODO comments and PTCard with VStack and .card()
      if [[ "$line" == *"TODO: Replace PTCard"* ]]; then
        # Skip the TODO line
        continue
      elif [[ "$line" == *"PTCard"* ]]; then
        # Replace PTCard() with VStack {} and add .card()
        echo "$line" | sed 's/PTCard/VStack/' >> "$temp_file"
      elif grep -q "^${line_number}:" "${temp_file}_ptcard_lines"; then
        # We're on a line referenced in the PTCard lines file, so add .card()
        # after VStack and before the content
        echo "$line.card()" >> "$temp_file"
      else
        # Keep the line as is
        echo "$line" >> "$temp_file"
      fi
    done < "$file"
    
    # Remove multiple .card() modifiers that may have been added
    sed -i '' 's/\.card()\.card()/\.card()/g' "$temp_file"
    
    # Fix syntax errors
    sed -i '' 's/militaryMonospaced(size: \.body()/militaryMonospaced(size: Spacing.body)/g' "$temp_file"
    sed -i '' 's/\.small(weight: \.medium))/\.small(weight: .medium)/g' "$temp_file"
    sed -i '' 's/\.body(weight: \.medium))/\.body(weight: .medium)/g' "$temp_file"
    sed -i '' 's/\.font(\.system(size: 36)/\.font(.system(size: 36))/g' "$temp_file"
    sed -i '' 's/\.symbolSize(CGSize(width: 8, height: 8)/\.symbolSize(CGSize(width: 8, height: 8))/g' "$temp_file"
    sed -i '' 's/\.opacity(0.3)/\.opacity(0.3))/g' "$temp_file"
    sed -i '' 's/format: \.dateTime\.month()\.day()/format: .dateTime.month().day())/g' "$temp_file"
    
    # Move the file back
    mv "$temp_file" "$file"
  fi
  
  # Remove temporary files
  rm -f "${temp_file}_ptcard_lines"
  
  echo "✅ Fixed $file"
done

echo
echo "🎉 Chart syntax cleanup completed!"
echo "Run the migration script to check the final status:"
echo "bash ios/complete_styling_migration.sh" 