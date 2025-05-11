#!/usr/bin/env node

/**
 * This script changes @ts-ignore to @ts-expect-error
 * Run with: node scripts/fixTsComments.js
 */

import { execSync } from 'child_process';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

// Get the directory name in ESM
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Function to process files recursively
function processDirectory(directory) {
  const files = fs.readdirSync(directory);
  
  for (const file of files) {
    const filePath = path.join(directory, file);
    const stat = fs.statSync(filePath);
    
    if (stat.isDirectory()) {
      processDirectory(filePath);
    } else if (/\.(tsx?|jsx?)$/.test(file)) {
      fixTsComments(filePath);
    }
  }
}

// Function to fix TS comments in a file
function fixTsComments(filePath) {
  let content = fs.readFileSync(filePath, 'utf8');
  
  // Replace @ts-ignore with @ts-expect-error
  const newContent = content.replace(/@ts-ignore/g, '@ts-expect-error');
  
  if (newContent !== content) {
    fs.writeFileSync(filePath, newContent);
    console.log(`✅ Fixed TS comments in ${filePath}`);
  }
}

console.log('Fixing TS comments in the codebase...');
processDirectory(path.join(__dirname, '../src'));
console.log('TS comment fixing completed.'); 