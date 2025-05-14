#!/bin/bash

# Navigate to the iOS project directory
cd ios/ptchampion

# Function to safely replace color references
replace_color() {
    local old_pattern=$1
    local new_pattern=$2
    
    find . -name "*.swift" -type f -exec sed -i '' "s/$old_pattern/$new_pattern/g" {} +
}

# Replace direct SwiftUI color references with ThemeColor semantic equivalents
replace_color "SwiftUI\.Color\.red" "ThemeColor.error"
replace_color "SwiftUI\.Color\.green" "ThemeColor.success"
replace_color "SwiftUI\.Color\.blue" "ThemeColor.info"
replace_color "Color\.red" "ThemeColor.error"
replace_color "Color\.green" "ThemeColor.success"
replace_color "Color\.blue" "ThemeColor.info"

# Replace any remaining direct color references
replace_color "\.foregroundColor\(\.red\)" ".foregroundColor(ThemeColor.error)"
replace_color "\.foregroundColor\(\.green\)" ".foregroundColor(ThemeColor.success)"
replace_color "\.foregroundColor\(\.blue\)" ".foregroundColor(ThemeColor.info)"

# Replace foregroundStyle references
replace_color "\.foregroundStyle\(\.red\)" ".foregroundStyle(ThemeColor.error)"
replace_color "\.foregroundStyle\(\.green\)" ".foregroundStyle(ThemeColor.success)"
replace_color "\.foregroundStyle\(\.blue\)" ".foregroundStyle(ThemeColor.info)"

echo "Theme color references have been updated." 