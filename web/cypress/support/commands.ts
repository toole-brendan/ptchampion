// ***********************************************
// This creates custom commands and overrides existing commands.
// ***********************************************

// For more comprehensive examples of custom commands, visit:
// https://on.cypress.io/custom-commands

// Login command to quickly log in without UI
Cypress.Commands.add('login', (username = 'testuser', password = 'password123') => {
  cy.intercept('POST', `${Cypress.env('apiUrl')}/auth/login`, {
    statusCode: 200,
    body: {
      token: 'fake-jwt-token',
      user: {
        id: 1,
        username,
        email: `${username}@example.com`,
        fullName: 'Test User',
      },
    },
  }).as('loginRequest');

  // Set auth token and user in localStorage to simulate login
  cy.window().then((window) => {
    window.localStorage.setItem('auth_token', 'fake-jwt-token');
    window.localStorage.setItem('user', JSON.stringify({
      id: 1,
      username,
      email: `${username}@example.com`,
      fullName: 'Test User',
    }));
  });

  // Visit the dashboard page (assumes redirects work correctly)
  cy.visit('/dashboard');
});

// Navigate to the app with dark mode enabled
Cypress.Commands.add('visitWithDarkMode', (path = '/') => {
  // Set dark mode in localStorage
  cy.window().then((window) => {
    window.localStorage.setItem('theme', 'dark');
  });
  cy.visit(path);
});

// Seed the database with test data via API
Cypress.Commands.add('seedTestData', (fixtures = []) => {
  // Assuming there's a test-only API endpoint for seeding data
  cy.request({
    method: 'POST',
    url: `${Cypress.env('apiUrl')}/test/seed-data`,
    body: { fixtures },
  });
});

// Take a Percy snapshot with a unique name
Cypress.Commands.add('visualSnapshot', (name) => {
  // Only run visual testing if Percy is enabled
  if (Cypress.env('PERCY_TOKEN')) {
    cy.percySnapshot(name);
  }
});

declare global {
  namespace Cypress {
    interface Chainable {
      login(username?: string, password?: string): Chainable<JQuery<HTMLElement>>;
      visitWithDarkMode(path?: string): Chainable<Window>;
      seedTestData(fixtures?: any[]): Chainable<Response<any>>;
      visualSnapshot(name: string): Chainable<void>;
    }
  }
} 