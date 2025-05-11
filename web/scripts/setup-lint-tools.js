#!/usr/bin/env node

/**
 * This script installs the necessary dependencies for our linting tools.
 * Run with: node scripts/setup-lint-tools.js
 */

import { execSync } from 'child_process';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

// Get the directory name in ESM
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Create the scripts directory if it doesn't exist
const scriptsDir = __dirname;
if (!fs.existsSync(scriptsDir)) {
  fs.mkdirSync(scriptsDir, { recursive: true });
}

console.log('Installing dependencies for lint tools...');

try {
  // Install jscodeshift for code transformation
  execSync('npm install --save-dev jscodeshift @types/jscodeshift', { 
    stdio: 'inherit',
    cwd: path.join(__dirname, '..')
  });
  console.log('✅ Installed jscodeshift');
  
  // Make our scripts executable
  const scripts = [
    'removeUnusedImports.js',
    'removeUnusedVariables.js',
    'fixTailwindClasses.js',
    'fixFontConflicts.js',
    'fixAnyTypes.js',
    'fixTsComments.js'
  ];
  
  scripts.forEach(script => {
    const scriptPath = path.join(scriptsDir, script);
    if (fs.existsSync(scriptPath)) {
      fs.chmodSync(scriptPath, '755');
      console.log(`✅ Made ${script} executable`);
    } else {
      console.warn(`⚠️ Script not found: ${script}`);
    }
  });
  
  console.log('\nSetup complete! You can now run:');
  console.log('  npm run lint:fix-all    # Fix linting issues automatically');
  console.log('  ./scripts/removeUnusedImports.js    # Remove unused imports');
  console.log('  ./scripts/removeUnusedVariables.js  # Remove unused variables');
  
} catch (error) {
  console.error('Error setting up lint tools:', error);
} 