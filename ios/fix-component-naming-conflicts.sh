#!/bin/bash

# Script to rename duplicate component files in the app that conflict with design system components
# This ensures the design system is the source of truth

echo "🔄 Renaming conflicting component files in app to avoid naming conflicts with design system..."

# Directory to process
APP_DIR="ptchampion"
SHARED_DIR="$APP_DIR/Views/Shared"

# Create a backup directory
BACKUP_DIR="${SHARED_DIR}_bak"
mkdir -p "$BACKUP_DIR"

# List of components in the app that conflict with design system
COMPONENTS=(
  "PTButton.swift"
  "PTTextField.swift"
  "PTLabel.swift"
  "PTCard.swift"
)

# Rename the conflicting components
for component in "${COMPONENTS[@]}"; do
  if [ -f "$SHARED_DIR/$component" ]; then
    echo "Processing $component..."
    # Back up the file
    cp "$SHARED_DIR/$component" "$BACKUP_DIR/$component"
    
    # Create an App prefix version - we'll rename the conflicting class inside
    new_name="App${component}"
    mv "$SHARED_DIR/$component" "$SHARED_DIR/$new_name"
    
    # Replace all occurrences of the class name in the file itself
    component_name="${component%.swift}"
    sed -i '' "s/struct $component_name/struct App$component_name/g" "$SHARED_DIR/$new_name"
    
    echo "✅ Renamed $component to $new_name"
  else
    echo "⚠️ Warning: $component not found in shared directory"
  fi
done

# Search for usages of the renamed components in the app code and update them
echo "🔄 Updating references to renamed components..."

for component in "${COMPONENTS[@]}"; do
  component_name="${component%.swift}"
  app_component_name="App$component_name"
  
  # Find all Swift files that reference the component name
  for file in $(grep -l "import PTDesignSystem.*$component_name" $APP_DIR/**/*.swift); do
    if [[ "$file" != "$SHARED_DIR/App$component" ]]; then
      echo "Updating references in $file"
      # Update references but only those with the specific pattern that indicates
      # we're using our app's component, not the design system one
      sed -i '' "s/$component_name(/$app_component_name(/g" "$file"
    fi
  done
done

echo "🎉 Done renaming conflicting components. Please build the project to catch any remaining issues." 