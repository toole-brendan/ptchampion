const StyleDictionary = require('style-dictionary');

/**
 * Configuration for generating web design tokens from the shared token source
 * This outputs CSS variables that match the iOS AppTheme naming conventions
 */
module.exports = {
  source: ['tokens/**/*.json'],
  platforms: {
    web: {
      transformGroup: 'web',
      buildPath: 'build/web/',
      files: [
        {
          destination: 'variables.css',
          format: 'css/variables',
          options: {
            showFileHeader: true,
            selector: ':root'
          }
        }
      ],
      transforms: ['name/cti/kebab']
    },
    // Add dark mode variables
    webDark: {
      transformGroup: 'web',
      buildPath: 'build/web/',
      files: [
        {
          destination: 'variables-dark.css',
          format: 'css/variables',
          options: {
            showFileHeader: true,
            selector: '.dark'
          }
        }
      ],
      transforms: ['name/cti/kebab']
    }
  }
};

// Register custom transform for snake_case to camelCase conversion if needed
StyleDictionary.registerTransform({
  name: 'name/swift-to-css',
  type: 'name',
  transformer: (token) => {
    // Convert SwiftUI naming conventions to CSS variable naming
    return token.name.replace(/([a-z0-9])([A-Z])/g, '$1-$2').toLowerCase();
  }
});

// Run the build
StyleDictionary.extend(module.exports).buildAllPlatforms(); 