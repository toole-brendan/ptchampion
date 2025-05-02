#!/bin/bash

# This script removes excessive font registration logging from the app

echo "Cleaning up font-related console output..."

# Back up the original file
SWIFT_FILE="ios/ptchampion/PTChampionApp.swift"
BACKUP_FILE="ios/ptchampion/PTChampionApp.swift.logs_backup"
cp "$SWIFT_FILE" "$BACKUP_FILE"

# Update the FontManager class to be less verbose
echo "Updating FontManager class..."

# 1. Add a verbose flag to control logging
sed -i '' '/private var fontsRegistered = false/a\\
    // Control verbose logging\
    private let verboseLogging = false' "$SWIFT_FILE"

# 2. Replace print statements with conditional logging function
sed -i '' '/class FontManager {/a\\
    // Helper function for conditional logging\
    private func log(_ message: String) {\
        if verboseLogging {\
            print(message)\
        }\
    }' "$SWIFT_FILE"

# 3. Replace all FONT REGISTRATION print statements with the log function
sed -i '' 's/print("FONT REGISTRATION:/self.log("FONT REGISTRATION:/g' "$SWIFT_FILE"

# 4. Modify the printAvailableFonts method to be conditional
sed -i '' '/func printAvailableFonts/,/}/c\\
    func printAvailableFonts() {\
        if verboseLogging {\
            print("FONT REGISTRATION: Available system fonts:")\
            for family in UIFont.familyNames.sorted() {\
                print("Font Family: \\(family)")\
                for name in UIFont.fontNames(forFamilyName: family) {\
                    print("   Font: \\(name)")\
                }\
            }\
        } else {\
            // Just print the custom fonts that were successfully registered\
            print("✅ Font registration complete - successfully registered custom fonts")\
        }\
    }' "$SWIFT_FILE"

# 5. Update the PTChampionApp init method to be less verbose about fonts
sed -i '' 's/print("--- DEBUG: Available Fonts ---")/\/* Skip verbose font listing*\//g' "$SWIFT_FILE"

# 6. Make successful font registration messages more concise
sed -i '' 's/✅ FONT REGISTRATION: Successfully registered font:/✅ Registered:/g' "$SWIFT_FILE"

echo "Font logging cleaned up!"
echo "The app will now show minimal font-related messages in the console."
echo "To restore verbose logging, edit the 'verboseLogging' flag in FontManager class." 