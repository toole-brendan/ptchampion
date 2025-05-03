# PT Champion Design Tokens

This directory contains the single source of truth for design tokens used across all PT Champion platforms.

## Structure

- `design-tokens.json` - The main design token file in JSON format
- `style-dictionary.config.js` - Configuration for generating platform-specific token files
- `build/` - Generated output files (should be gitignored)
  - `ios/` - Swift files and color assets for iOS
  - `web/` - CSS and Tailwind config files for web

## Usage

### Setup

```bash
# Install dependencies
cd design-tokens
npm install
```

### Building Tokens

```bash
# Generate all platform tokens
npm run build

# Watch for changes and rebuild
npm run build:watch

# Clean build artifacts
npm run clean
```

### Installing Tokens

#### iOS

```bash
# Install to iOS project
./install-ios.sh
```

This will copy the generated color assets to `ios/ptchampion/Assets.xcassets/` and the Swift file to `ios/ptchampion/Theme/AppTheme+Generated.swift`.

#### Web

```bash
# Install to web project
./install-web.sh
```

This will copy the generated CSS variables to `web/src/components/ui/theme.css`.

### Updating Tokens

1. Edit `design-tokens.json` with your changes
2. Run `npm run build` to regenerate all platform tokens
3. Run the appropriate install script to copy the tokens to your platform project
4. Commit your changes

## Integration

### iOS

The generated files include:

- `build/ios/AppTheme+Generated.swift` - Swift extensions for the AppTheme
- `build/ios/Colors.xcassets` - Asset catalog with color sets

To use in your iOS project:
1. Run `./install-ios.sh` to copy the generated files to your iOS project
2. Import the AppTheme extensions in your existing theme file
3. Update your code to use the generated properties

### Web

The generated files include:

- `build/web/variables.css` - CSS custom properties

To use in your web project:
1. Run `./install-web.sh` to copy the CSS file to your web project
2. Import the theme.css file in your main stylesheet or entry point
3. Use the CSS variables in your styles

## Guidelines

- Always edit `design-tokens.json` directly, never edit generated files
- Use semantic names for tokens whenever possible
- Keep platform-specific overrides to a minimum
- Add documentation comments for non-obvious tokens

## CI/CD Integration

This project includes a GitHub Action workflow that:

1. Validates the design token JSON format
2. Builds all platform tokens
3. Verifies that the generated files are up-to-date
4. Optionally commits updated tokens on main branch 