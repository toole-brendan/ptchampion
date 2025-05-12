// ***********************************************************
// This example support/e2e.ts is processed and
// loaded automatically before your test files.
//
// This is a great place to put global configuration and
// behavior that modifies Cypress.
//
// You can change the location of this file or turn off
// automatically serving support files with the
// 'supportFile' configuration option.
//
// You can read more here:
// https://on.cypress.io/configuration
// ***********************************************************

// Import commands.js using ES2015 syntax:
import './commands'

// Alternatively you can use CommonJS syntax:
// require('./commands')

// Extend cypress types with our custom commands
declare global {
  namespace Cypress {
    interface Chainable {
      /**
       * Custom command to log in with username and password
       * @example cy.login('username', 'password')
       */
      login(username: string, password: string): Chainable<Element>
      
      /**
       * Custom command to login with a mock user for testing
       * @example cy.loginWithMock()
       */
      loginWithMock(): Chainable<Element>
      
      /**
       * Custom command to mock media devices for camera access
       * @example cy.mockMediaDevices()
       */
      mockMediaDevices(): Chainable<Element>
    }
  }
}

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