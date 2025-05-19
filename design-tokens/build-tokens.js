const StyleDictionary = require('style-dictionary');
const config = require('./style-dictionary.config.js');

console.log('▶︎ building design tokens with fixed template');
StyleDictionary.extend(config).buildAllPlatforms();
console.log('✅ build complete');
