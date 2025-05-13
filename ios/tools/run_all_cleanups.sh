#!/bin/bash
# Master script to run all styling cleanup processes
# This should be run from the repository root

set -e # Exit on error

echo "========== PT Champion – Complete Styling Cleanup =========="
echo "$(date)"
echo

# Make sure we're in the right directory
if [ ! -d "ios" ]; then
  echo "Error: This script must be run from the repository root"
  exit 1
fi

# Make the script executable
chmod +x ios/scripts/regex_cleanup.sh

# Step 1: Run the regex-based cleanup
echo "🔄 Running regex-based cleanup..."
bash ios/scripts/regex_cleanup.sh

# Step 2: Run the migration script to check the final status
echo
echo "🔄 Running the migration script to check status..."
bash ios/complete_styling_migration.sh

echo
echo "🎉 Cleanup processes completed!"
echo "Review any remaining issues manually and create a cleanup commit." 