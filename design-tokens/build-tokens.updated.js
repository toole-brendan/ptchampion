const StyleDictionary = require('style-dictionary');
const config = require('./style-dictionary.config.updated.js');
const fs = require('fs');
const path = require('path');

// Process JSON files with nested structure
StyleDictionary.registerParser({
  pattern: /\.json$/,
  parse: ({ contents, filePath }) => {
    const json = JSON.parse(contents);
    const tokens = {};

    // Process colors
    if (json.colors) {
      // Add base colors
      if (json.colors.base) {
        tokens.color = { base: {} };
        Object.entries(json.colors.base).forEach(([name, def]) => {
          tokens.color.base[name] = {
            type: "color",
            value: def.value,
            ...(def.alpha && { alpha: def.alpha })
          };
        });
      }
      
      // Add semantic colors
      if (json.colors.semantic) {
        if (!tokens.color) tokens.color = {};
        tokens.color.semantic = {};
        
        // Process regular semantic colors
        Object.entries(json.colors.semantic).forEach(([name, def]) => {
          if (name !== 'text') {
            tokens.color.semantic[name] = {
              type: "color",
              value: def.value,
              ...(def.alpha && { alpha: def.alpha })
            };
          }
        });
        
        // Process text semantic colors separately
        if (json.colors.semantic.text) {
          tokens.color.semantic.text = {};
          Object.entries(json.colors.semantic.text).forEach(([textType, def]) => {
            tokens.color.semantic.text[textType] = {
              type: "color",
              value: def.value,
              ...(def.alpha && { alpha: def.alpha })
            };
          });
        }
      }
      
      // Add dark mode colors
      if (json.colors.dark) {
        if (!tokens.color) tokens.color = {};
        tokens.color.dark = {};
        Object.entries(json.colors.dark).forEach(([name, def]) => {
          tokens.color.dark[name] = {
            type: "color",
            value: def.value,
            ...(def.alpha && { alpha: def.alpha })
          };
        });
      }
    }
    
    // Process typography
    if (json.typography) {
      tokens.typography = {};
      
      // Process font sizes
      if (json.typography.size) {
        tokens.typography.size = {};
        Object.entries(json.typography.size).forEach(([name, def]) => {
          tokens.typography.size[name] = {
            type: "size",
            value: def.value
          };
        });
      }
      
      // Process font families
      if (json.typography.family) {
        tokens.typography.family = {};
        Object.entries(json.typography.family).forEach(([name, def]) => {
          tokens.typography.family[name] = {
            type: "fontFamily",
            value: def.value
          };
        });
      }
    }
    
    // Process spacing
    if (json.spacing) {
      tokens.spacing = {};
      Object.entries(json.spacing).forEach(([name, def]) => {
        tokens.spacing[name] = {
          type: "spacing",
          value: def.value
        };
      });
    }
    
    // Process radius
    if (json.radius) {
      tokens.radius = {};
      Object.entries(json.radius).forEach(([name, def]) => {
        tokens.radius[name] = {
          type: "borderRadius",
          value: def.value
        };
      });
    }
    
    // Process shadows
    if (json.shadow) {
      tokens.shadow = {};
      Object.entries(json.shadow).forEach(([shadowName, props]) => {
        tokens.shadow[shadowName] = {};
        Object.entries(props).forEach(([propName, def]) => {
          tokens.shadow[shadowName][propName] = {
            type: propName === 'color' ? 'color' : 'size',
            value: def.value
          };
        });
      });
    }
    
    // Process border widths
    if (json['border-width']) {
      tokens['border-width'] = {};
      Object.entries(json['border-width']).forEach(([name, def]) => {
        tokens['border-width'][name] = {
          type: "borderWidth",
          value: def.value
        };
      });
    }
    
    return tokens;
  }
});

// Register the configuration and build all platforms
StyleDictionary.extend(config).buildAllPlatforms();

console.log('✅ Design tokens built successfully!'); 