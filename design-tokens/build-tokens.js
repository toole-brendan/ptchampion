const StyleDictionary = require('style-dictionary');
const config = require('./style-dictionary.config.js');

// Register the configuration and build all platforms
StyleDictionary.extend(config).buildAllPlatforms();

console.log('✅ Design tokens built successfully!'); 