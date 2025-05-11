#!/usr/bin/env node

/**
 * This script uses jscodeshift to automatically remove unused variables from TypeScript files.
 * Run with: node scripts/removeUnusedVariables.js
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
const TRANSFORM_PATH = path.join(TEMP_DIR, 'removeUnusedVariables.js');
fs.writeFileSync(TRANSFORM_PATH, `
export default function(fileInfo, api) {
  const j = api.jscodeshift;
  const root = j(fileInfo.source);
  let modified = false;
  
  // Process variable declarations
  function processVariableDeclaration(path, scope) {
    const declarations = path.node.declarations;
    
    if (!declarations || declarations.length === 0) return;
    
    // Track which declarations to keep
    const newDeclarations = [];
    
    declarations.forEach(declaration => {
      // If not a simple identifier (e.g., it's a destructuring), keep it for now
      if (!declaration.id || declaration.id.type !== 'Identifier') {
        newDeclarations.push(declaration);
        return;
      }
      
      const varName = declaration.id.name;
      
      // Check if the variable is used in the scope
      const references = j(scope)
        .find(j.Identifier, { name: varName })
        .filter(idPath => {
          // Filter out the declaration itself
          if (idPath.node === declaration.id) return false;
          
          // If it's in another variable declaration, it's not a usage
          if (idPath.parent.node.type === 'VariableDeclarator' && 
              idPath.parent.node.id === idPath.node) {
            return false;
          }
          
          return true;
        });
      
      if (references.size() > 0) {
        newDeclarations.push(declaration);
      } else {
        console.log(\`Found unused variable: \${varName}\`);
        modified = true;
      }
    });
    
    // If all declarations are unused, remove the entire statement
    if (newDeclarations.length === 0) {
      j(path).remove();
    } 
    // If some declarations are unused, update the declarations list
    else if (newDeclarations.length < declarations.length) {
      path.node.declarations = newDeclarations;
    }
  }
  
  // Process function declarations
  root
    .find(j.FunctionDeclaration)
    .forEach(path => {
      // For each function, find variable declarations inside
      j(path)
        .find(j.VariableDeclaration)
        .forEach(varPath => {
          processVariableDeclaration(varPath, path);
        });
    });
  
  // Process arrow functions
  root
    .find(j.ArrowFunctionExpression)
    .forEach(path => {
      // Only process if the body is a block statement
      if (path.node.body && path.node.body.type === 'BlockStatement') {
        j(path.node.body)
          .find(j.VariableDeclaration)
          .forEach(varPath => {
            processVariableDeclaration(varPath, path.node.body);
          });
      }
    });
  
  // Process class methods
  root
    .find(j.ClassDeclaration)
    .forEach(classPath => {
      j(classPath)
        .find(j.ClassMethod)
        .forEach(methodPath => {
          j(methodPath)
            .find(j.VariableDeclaration)
            .forEach(varPath => {
              processVariableDeclaration(varPath, methodPath.node.body);
            });
        });
    });
  
  // Process top-level variable declarations
  root
    .find(j.Program)
    .forEach(programPath => {
      j(programPath)
        .find(j.VariableDeclaration)
        .filter(path => {
          // Filter to include only top-level declarations
          return path.parent.node.type === 'Program';
        })
        .forEach(varPath => {
          processVariableDeclaration(varPath, programPath);
        });
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
      console.log(`To apply the changes, run the command again with --apply flag`);
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