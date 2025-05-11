#!/usr/bin/env node

/**
 * This script adds proper typing for common 'any' types in the codebase.
 * While it can't fix all any types (especially complex ones requiring context),
 * it handles common patterns.
 * 
 * Run with: node scripts/fixAnyTypes.js
 */

import { execSync } from 'child_process';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

// Get the directory name in ESM
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Common replacements
const TYPE_REPLACEMENTS = [
  // React event handler any types
  {
    pattern: /(React\.)?(\w+Event)Handler<any>/g,
    replacement: '$1$2Handler<HTMLElement>'
  },
  // Grader any in PullupTrackerViewModel
  {
    pattern: /private grader: any;/g,
    replacement: 'private grader: ReturnType<typeof createGrader>;'
  },
  // Function parameters with any
  {
    pattern: /\(([^)]*): any([^)]*)\)/g,
    replacement: '($1: unknown$2)'
  },
  // Error callbacks with any
  {
    pattern: /(catch|error) *\(\s*(\w+)\s*: any\s*\)/g,
    replacement: '$1 ($2: unknown)'
  },
  // Event handlers with any
  {
    pattern: /((on|handle)\w+)\s*=\s*\(\s*(\w+)\s*:\s*any\s*\)/g,
    replacement: '$1 = ($3: React.MouseEvent<HTMLElement>)'
  },
  // Generic JSX props with any
  {
    pattern: /Props<any>/g,
    replacement: 'Props<unknown>'
  },
  // Component props with any
  {
    pattern: /interface (\w+)Props \{\s*([^}]*): any;/g,
    replacement: 'interface $1Props {\n  $2: unknown;'
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
      fixAnyTypes(filePath);
    }
  }
}

// Function to fix any types in a file
function fixAnyTypes(filePath) {
  let content = fs.readFileSync(filePath, 'utf8');
  let modified = false;
  
  for (const replacement of TYPE_REPLACEMENTS) {
    const newContent = content.replace(replacement.pattern, replacement.replacement);
    if (newContent !== content) {
      content = newContent;
      modified = true;
    }
  }
  
  if (modified) {
    fs.writeFileSync(filePath, content);
    console.log(`✅ Fixed any types in ${filePath}`);
  }
}

// Fix specific files with type issues
function fixSpecificFiles() {
  // Fix PullupTrackerViewModel
  const pullupViewModel = path.join(__dirname, '../src/viewmodels/PullupTrackerViewModel.ts');
  if (fs.existsSync(pullupViewModel)) {
    let content = fs.readFileSync(pullupViewModel, 'utf8');
    content = content.replace(
      /private grader: any;/,
      'private grader: ReturnType<typeof createGrader>;'
    );
    fs.writeFileSync(pullupViewModel, content);
    console.log('✅ Fixed PullupTrackerViewModel typing');
  }
  
  // Fix SitupTrackerViewModel
  const situpViewModel = path.join(__dirname, '../src/viewmodels/SitupTrackerViewModel.ts');
  if (fs.existsSync(situpViewModel)) {
    let content = fs.readFileSync(situpViewModel, 'utf8');
    content = content.replace(
      /private grader: any;/,
      'private grader: ReturnType<typeof createGrader>;'
    );
    fs.writeFileSync(situpViewModel, content);
    console.log('✅ Fixed SitupTrackerViewModel typing');
  }
  
  // Fix d.ts files that require more specific handling
  const mediapieDtsPath = path.join(__dirname, '../src/types/mediapipe.d.ts');
  if (fs.existsSync(mediapieDtsPath)) {
    let content = fs.readFileSync(mediapieDtsPath, 'utf8');
    content = content.replace(/: any/g, ': unknown');
    fs.writeFileSync(mediapieDtsPath, content);
    console.log('✅ Fixed mediapipe.d.ts typing');
  }
}

console.log('Fixing any types in the codebase...');
processDirectory(path.join(__dirname, '../src'));
fixSpecificFiles();
console.log('Type fixing completed.'); 