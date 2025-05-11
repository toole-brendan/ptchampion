#!/usr/bin/env node

/**
 * This script fixes conflicting font classes in the codebase.
 * For example, 'font-bold' and 'font-heading' should not be used together
 * as they both set the font-weight property.
 * 
 * Run with: node scripts/fixFontConflicts.js
 */

import { execSync } from 'child_process';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

// Get the directory name in ESM
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Conflicts to fix
const FONT_CONFLICTS = [
  // font-bold + font-heading -> font-heading
  {
    pattern: /className="([^"]*)\s*(font-bold)\s*([^"]*)font-heading([^"]*)"/g,
    replacement: 'className="$1$3font-heading$4"'
  },
  // font-heading + font-bold -> font-heading
  {
    pattern: /className="([^"]*)\s*(font-heading)\s*([^"]*)font-bold([^"]*)"/g,
    replacement: 'className="$1$2$3$4"'
  },
  // font-sans + font-semibold -> font-sans
  {
    pattern: /className="([^"]*)\s*(font-sans)\s*([^"]*)font-semibold([^"]*)"/g,
    replacement: 'className="$1$2$3$4"'
  },
  // font-semibold + font-sans -> font-sans
  {
    pattern: /className="([^"]*)\s*(font-semibold)\s*([^"]*)font-sans([^"]*)"/g,
    replacement: 'className="$1$3font-sans$4"'
  },
  // font-mono + font-bold -> font-mono
  {
    pattern: /className="([^"]*)\s*(font-mono)\s*([^"]*)font-bold([^"]*)"/g,
    replacement: 'className="$1$2$3$4"'
  },
  // font-bold + font-mono -> font-mono
  {
    pattern: /className="([^"]*)\s*(font-bold)\s*([^"]*)font-mono([^"]*)"/g,
    replacement: 'className="$1$3font-mono$4"'
  }
];

// Function to process files recursively
function processDirectory(directory) {
  const files = fs.readdirSync(directory);
  
  for (const file of files) {
    const filePath = path.join(directory, file);
    const stat = fs.statSync(filePath);
    
    if (stat.isDirectory()) {
      processDirectory(filePath);
    } else if (/\.(tsx?|jsx?)$/.test(file)) {
      fixFontConflicts(filePath);
    }
  }
}

// Function to fix font conflicts in a file
function fixFontConflicts(filePath) {
  let content = fs.readFileSync(filePath, 'utf8');
  let modified = false;
  
  for (const conflict of FONT_CONFLICTS) {
    const newContent = content.replace(conflict.pattern, conflict.replacement);
    if (newContent !== content) {
      content = newContent;
      modified = true;
    }
  }
  
  if (modified) {
    fs.writeFileSync(filePath, content);
    console.log(`✅ Fixed font conflicts in ${filePath}`);
  }
}

console.log('Fixing font conflicts in the codebase...');
processDirectory(path.join(__dirname, '../src'));
console.log('Font conflict fixing completed.'); 