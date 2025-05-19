# Design Tokens Pipeline: Xcode Setup Instructions

The design tokens are now automatically generated from the project root's `design-tokens.json` file into Swift code. Follow these instructions to properly integrate them into your Xcode project:

## 1. Add Generated Files to Xcode

1. Open your Xcode project
2. Right-click on the project navigator and choose "Add Files to 'ptchampion'..."
3. Navigate to and select the `Generated` folder containing `GeneratedTheme.swift`
4. Make sure "Copy items if needed" is unchecked
5. Make sure your target is selected
6. Click "Add"

## 2. Set Up a Build Phase to Generate Tokens

1. Select your project in the Project Navigator
2. Select your app target
3. Go to the "Build Phases" tab
4. Click the "+" at the top and select "New Run Script Phase"
5. Drag this new phase to be above "Compile Sources"
6. Name it "Generate Design Tokens"
7. Add this script:

```bash
# Run the design tokens generation script
cd "${SRCROOT}/../"
./scripts/sync-design-tokens.sh
```

8. In the "Input Files" section, add:
```
$(SRCROOT)/../design-tokens.json
```

9. In the "Output Files" section, add:
```
$(SRCROOT)/ptchampion/Generated/GeneratedTheme.swift
```

## 3. Update Color Assets

1. Open your Asset Catalog (`Assets.xcassets`)
2. Create a "Colors" folder if you don't have one
3. Add color assets for each base color used in your design tokens
4. Make sure the names match exactly what's in the GeneratedTheme.swift file (without dashes, lowercase)
5. Set appropriate colors for both light and dark mode

## 4. Configure Swift Imports

If you're getting "No such module" errors when trying to import components:

1. Make sure your `AppTheme.swift` file properly imports the generated theme:
   ```swift
   @_exported import struct SwiftUI.Color
   // The GeneratedTheme.swift file is imported via the build system
   ```

## 5. Test the Integration

1. Build your project (⌘B)
2. Verify that there are no build errors related to the design tokens
3. Test a component that uses `AppTheme.GeneratedColors` or other generated values

## Troubleshooting

If you encounter issues:

- Check that the `design-tokens.json` file exists at the project root
- Verify that the script has executable permissions: `chmod +x scripts/sync-design-tokens.sh`
- Run the script manually from the command line to see any errors
- Check that your color asset names match exactly what's in the generated code
- Make sure the fonts referenced in the tokens file are correctly added to your project

## Making Changes to Design Tokens

1. Edit the root `design-tokens.json` file
2. The build phase will automatically regenerate the Swift code
3. If you need to manually regenerate, run: `./scripts/sync-design-tokens.sh` from the project root 