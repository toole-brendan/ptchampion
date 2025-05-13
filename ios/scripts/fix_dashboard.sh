#!/bin/bash
# Script to add the container() modifier to DashboardView.swift
# This should be run from the repository root

set -e # Exit on error

echo "========== PT Champion – DashboardView Cleanup =========="
echo "$(date)"
echo

# Target file
dashboard_file="ios/ptchampion/Views/Dashboard/DashboardView.swift"

echo "🔍 Adding .container() to $dashboard_file..."

# Check if the file exists
if [ ! -f "$dashboard_file" ]; then
  echo "Error: File $dashboard_file does not exist"
  exit 1
fi

# Add .container() after navigationBarTitleDisplayMode if not already present
if grep -q "navigationBarTitleDisplayMode" "$dashboard_file" && ! grep -q "\.container()" "$dashboard_file"; then
  sed -i '' '/navigationBarTitleDisplayMode/ s/$/.container()/g' "$dashboard_file"
  echo "✅ Added .container() to $dashboard_file"
else
  echo "ℹ️ File may already have .container() modifier or doesn't have navigationBarTitleDisplayMode"
fi

# Remove the TODO comment if it exists
sed -i '' 's/\/\/ TODO: Add container\(\) modifier here/\/\/ FIXED: Added container() modifier/g' "$dashboard_file"

echo
echo "🎉 DashboardView cleanup completed!"
echo "Run the migration script to check the final status:"
echo "bash ios/complete_styling_migration.sh" 