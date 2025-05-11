#!/usr/bin/env node

/**
 * This script uses jscodeshift to automatically remove unused imports from TypeScript files.
 * Run with: node scripts/removeUnusedImports.js
 */

import { execSync } from 'child_process';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

// Get the directory name in ESM
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Create a temporary directory for the transform file
const TEMP_DIR = path.join(__dirname, 'temp');
if (!fs.existsSync(TEMP_DIR)) {
  fs.mkdirSync(TEMP_DIR);
}

// Create the jscodeshift transform file
const TRANSFORM_PATH = path.join(TEMP_DIR, 'removeUnusedImports.js');
fs.writeFileSync(TRANSFORM_PATH, `
export default function(fileInfo, api) {
  const j = api.jscodeshift;
  const root = j(fileInfo.source);
  let modified = false;

  // Find all import declarations
  root
    .find(j.ImportDeclaration)
    .forEach(path => {
      const importPath = path.node;
      // Check each specifier to see if it's used
      const unusedSpecifiers = [];
      let newSpecifiers = [];
      
      if (importPath.specifiers) {
        importPath.specifiers.forEach(specifier => {
          // Skip default imports for now as they're trickier to check
          if (specifier.type === 'ImportDefaultSpecifier') {
            newSpecifiers.push(specifier);
            return;
          }
          
          // For named imports, check if they're used
          if (specifier.type === 'ImportSpecifier') {
            const name = specifier.local.name;
            // Find all references to this imported name
            const references = root
              .find(j.Identifier, { name })
              .filter(idPath => {
                // Exclude the import declaration itself
                return idPath.parent.parent.node !== importPath;
              });
            
            // If we can't find any references, it's unused
            if (references.length === 0) {
              unusedSpecifiers.push(name);
              modified = true;
            } else {
              newSpecifiers.push(specifier);
            }
          } else {
            // Namespace imports
            newSpecifiers.push(specifier);
          }
        });
        
        // If all specifiers are unused, remove the entire import
        if (newSpecifiers.length === 0) {
          j(path).remove();
          modified = true;
        } 
        // If only some specifiers are unused, update the import
        else if (newSpecifiers.length < importPath.specifiers.length) {
          importPath.specifiers = newSpecifiers;
          modified = true;
        }
      }
    });

  return modified ? root.toSource() : null;
}
`);

// Function to process all TypeScript files recursively
function processDirectory(directory, dry = true) {
  try {
    const dryFlag = dry ? '--dry' : '';
    const command = `npx jscodeshift --extensions=ts,tsx --parser=tsx -t ${TRANSFORM_PATH} ${directory} ${dryFlag}`;
    console.log(`Running jscodeshift on ${directory}...`);
    execSync(command, { stdio: 'inherit' });
    
    if (dry) {
      console.log(`To apply the changes, run the command again with dry=false parameter`);
    } else {
      console.log(`✅ Applied changes to files`);
    }
  } catch (error) {
    console.error('Error running jscodeshift:', error);
  }
}

// Main
try {
  const args = process.argv.slice(2);
  const targetDir = args[0] || 'src';
  const dry = args.includes('--apply') ? false : true;
  
  processDirectory(targetDir, dry);
} finally {
  // Clean up the temp directory
  fs.unlinkSync(TRANSFORM_PATH);
  fs.rmdirSync(TEMP_DIR);
} 