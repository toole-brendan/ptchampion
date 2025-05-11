#!/usr/bin/env node

/**
 * This script helps fix common Tailwind CSS class issues:
 * 1. Class ordering
 * 2. Shorthand replacements (h-5 w-5 -> size-5)
 * 3. Opacity changes (ring-opacity-50 -> ring/50)
 * 
 * Run with: node scripts/fixTailwindClasses.js
 */

import { execSync } from 'child_process';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

// Get the directory name in ESM
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Function to run tailwind class ordering fix
function fixClassOrdering() {
  console.log('Fixing Tailwind class ordering issues...');
  try {
    // The --fix flag of ESLint will fix the class ordering
    const command = 'npx eslint "src/**/*.{ts,tsx}" --fix --quiet --rule "tailwindcss/classnames-order: error"';
    execSync(command, { stdio: 'inherit' });
    console.log('✅ Tailwind class ordering fixed');
  } catch (error) {
    console.error('Error running class ordering fix:', error);
  }
}

// Function to fix height/width shorthand
function fixSizeShorthand() {
  console.log('Fixing h-/w- to size- shorthand...');
  try {
    // Create a temporary regex replacement script
    const tempScript = path.join(__dirname, 'temp-size-replace.js');
    fs.writeFileSync(tempScript, `
      import fs from 'fs';
      import path from 'path';
      import { fileURLToPath } from 'url';
      
      const __filename = fileURLToPath(import.meta.url);
      const __dirname = path.dirname(__filename);
      
      function processFile(filePath) {
        const content = fs.readFileSync(filePath, 'utf8');
        
        // Regex to match 'h-X w-X' or 'w-X h-X' patterns in className props
        // This is a simplification; a proper implementation would use a parser
        const sizePattern = /className=\\{?["']([^"']*(?:\\bh-(\\d+|\\[\\d+px\\]) w-\\2|\\bw-(\\d+|\\[\\d+px\\]) h-\\3)[^"']*)["']\\}?/g;
        
        let match;
        let modified = false;
        let newContent = content;
        
        while ((match = sizePattern.exec(content)) !== null) {
          const fullMatch = match[0];
          const classString = match[1];
          
          // Get the size from either h-X or w-X
          const sizeMatch = classString.match(/\\b(?:h|w)-(\\d+|\\[\\d+px\\])/);
          if (sizeMatch && sizeMatch[1]) {
            const size = sizeMatch[1];
            
            // Replace both h-X and w-X with size-X
            const heightRe = new RegExp("\\\\bh-" + size + "\\\\b");
            const widthRe = new RegExp("\\\\bw-" + size + "\\\\b");
            
            const newClassString = classString
              .replace(heightRe, "")
              .replace(widthRe, "size-" + size)
              .replace(/\\s+/g, " ")
              .trim();
            
            const newFullMatch = fullMatch.replace(classString, newClassString);
            newContent = newContent.replace(fullMatch, newFullMatch);
            modified = true;
          }
        }
        
        if (modified) {
          fs.writeFileSync(filePath, newContent, 'utf8');
          console.log(\`✅ Fixed size shorthand in \${filePath}\`);
        }
      }
      
      function walkDir(dir) {
        const files = fs.readdirSync(dir);
        
        files.forEach(file => {
          const filePath = path.join(dir, file);
          const stat = fs.statSync(filePath);
          
          if (stat.isDirectory()) {
            walkDir(filePath);
          } else if (/\\.(tsx?|jsx?)$/.test(file)) {
            processFile(filePath);
          }
        });
      }
      
      walkDir('src');
    `);
    
    // Run the script
    execSync(`node ${tempScript}`, { stdio: 'inherit' });
    
    // Cleanup
    fs.unlinkSync(tempScript);
    console.log('✅ Size shorthand fixes applied');
  } catch (error) {
    console.error('Error fixing size shorthand:', error);
  }
}

// Function to fix opacity syntax
function fixOpacitySyntax() {
  console.log('Fixing opacity syntax (ring-opacity-50 -> ring/50)...');
  try {
    // Create a temporary regex replacement script
    const tempScript = path.join(__dirname, 'temp-opacity-replace.js');
    fs.writeFileSync(tempScript, `
      import fs from 'fs';
      import path from 'path';
      import { fileURLToPath } from 'url';
      
      const __filename = fileURLToPath(import.meta.url);
      const __dirname = path.dirname(__filename);
      
      function processFile(filePath) {
        const content = fs.readFileSync(filePath, 'utf8');
        
        // Regex to match old opacity syntax
        const opacityPattern = /(?<=className=\\{?["'][^"']*)\\b([a-zA-Z\\-]+)-opacity-(\\d+)(?=[^"']*["']\\}?)/g;
        
        let modified = false;
        let newContent = content.replace(opacityPattern, (match, prop, value) => {
          modified = true;
          return \`\${prop}/\${value}\`;
        });
        
        if (modified) {
          fs.writeFileSync(filePath, newContent, 'utf8');
          console.log(\`✅ Fixed opacity syntax in \${filePath}\`);
        }
      }
      
      function walkDir(dir) {
        const files = fs.readdirSync(dir);
        
        files.forEach(file => {
          const filePath = path.join(dir, file);
          const stat = fs.statSync(filePath);
          
          if (stat.isDirectory()) {
            walkDir(filePath);
          } else if (/\\.(tsx?|jsx?)$/.test(file)) {
            processFile(filePath);
          }
        });
      }
      
      walkDir('src');
    `);
    
    // Run the script
    execSync(`node ${tempScript}`, { stdio: 'inherit' });
    
    // Cleanup
    fs.unlinkSync(tempScript);
    console.log('✅ Opacity syntax fixes applied');
  } catch (error) {
    console.error('Error fixing opacity syntax:', error);
  }
}

// Run all fixers
console.log('Starting Tailwind CSS class fixes...');
fixClassOrdering();
fixSizeShorthand();
fixOpacitySyntax();
console.log('All Tailwind CSS fixes applied.'); 