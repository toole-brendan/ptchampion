// ***********************************************************
// This support file is processed and loaded automatically before your test files.
// This is a great place to put global configuration and behavior that modifies Cypress.
// ***********************************************************

// Import commands.js using ES2015 syntax:
import './commands';

// Cypress config
Cypress.on('uncaught:exception', (err, runnable) => {
  // returning false here prevents Cypress from failing the test
  return false;
});

// Add better error reporting to console when tests fail
Cypress.on('fail', (error, runnable) => {
  // Print additional debugging output to console
  console.error('Test failed:', {
    title: runnable.title,
    error: error.message,
    stack: error.stack,
  });
  throw error; // still throw the error
}); 