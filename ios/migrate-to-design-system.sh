#!/bin/bash

# Script to migrate from app-specific components to design system components
# This ensures the PTDesignSystem is the source of truth

echo "🔄 Migrating app to use PTDesignSystem components..."

# Directory to process
APP_DIR="ptchampion"
SHARED_DIR="$APP_DIR/Views/Shared"

# Create a backup directory
BACKUP_DIR="$APP_DIR/Views/Shared_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# List of components that exist in both app and design system
DUPLICATE_COMPONENTS=(
  "PTButton.swift"
  "PTTextField.swift"
  "PTLabel.swift"
  "PTCard.swift"
  "PTSeparator.swift"
)

# Backup app-specific components
echo "📦 Backing up app-specific components..."
for component in "${DUPLICATE_COMPONENTS[@]}"; do
  if [ -f "$SHARED_DIR/$component" ]; then
    echo "Backing up $component"
    cp "$SHARED_DIR/$component" "$BACKUP_DIR/$component"
  fi
done

# Check if we need to mark any files as duplicate rather than removing them
echo "🔍 Analyzing app components for significant differences from design system..."
for component in "${DUPLICATE_COMPONENTS[@]}"; do
  if [ -f "$SHARED_DIR/$component" ]; then
    # Get component name without extension for use in comments
    component_name="${component%.swift}"
    
    # Add a comment at the top of the file indicating it's a duplicate
    echo "Marking $component as duplicate"
    sed -i '' "1s/^/\/\/ DUPLICATE: This is an app-specific version of $component_name. The PTDesignSystem version should be used instead.\n\/\/ Kept for reference only, not for use.\n\n/" "$SHARED_DIR/$component"
    
    # Rename the file to indicate it's a duplicate (but keep for reference)
    mv "$SHARED_DIR/$component" "$SHARED_DIR/$component_name.duplicate.swift"
    echo "✅ Renamed $component to ${component_name}.duplicate.swift"
  fi
done

# Ensure all files importing PTDesignSystem correctly
echo "🔄 Updating imports to ensure design system is correctly referenced..."

for file in $(find "$APP_DIR" -name "*.swift" -type f); do
  # Skip duplicate files we just created
  if [[ "$file" == *".duplicate.swift" ]]; then
    continue
  fi
  
  # Make sure all files referencing components from design system import PTDesignSystem
  if grep -q "PT[A-Za-z]\+" "$file" && ! grep -q "import PTDesignSystem" "$file"; then
    echo "Adding PTDesignSystem import to $file"
    sed -i '' '1s/^/import SwiftUI\nimport PTDesignSystem\n/' "$file"
  fi
done

echo "🎉 Done migrating to design system components. Please build the project to catch any remaining issues." 