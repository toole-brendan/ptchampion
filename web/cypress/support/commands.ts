/// <reference types="cypress" />
// ***********************************************
// This example commands.ts shows you how to
// create various custom commands and overwrite
// existing commands.
//
// For more comprehensive examples of custom
// commands please read more here:
// https://on.cypress.io/custom-commands
// ***********************************************

// -- This is a parent command --
// Cypress.Commands.add('login', (email, password) => { ... })
//
// -- This is a child command --
// Cypress.Commands.add('drag', { prevSubject: 'element'}, (subject, options) => { ... })
//
// -- This is a dual command --
// Cypress.Commands.add('dismiss', { prevSubject: 'optional'}, (subject, options) => { ... })
//
// -- This will overwrite an existing command --
// Cypress.Commands.overwrite('visit', (originalFn, url, options) => { ... })

// Custom login command
Cypress.Commands.add('login', (username: string, password: string) => {
  cy.session(
    `user-${username}`,
    () => {
      cy.visit('/login');
      cy.get('input[name="username"]').type(username);
      cy.get('input[name="password"]').type(password);
      cy.get('button[type="submit"]').click();
      cy.url().should('include', '/dashboard');
    },
    {
      validate: () => {
        cy.getCookie('auth-token').should('exist');
      },
    }
  );
});

// Mock login command (uses localStorage token)
Cypress.Commands.add('loginWithMock', () => {
  cy.session(
    'mock-user',
    () => {
      // Set a mock token in localStorage
      const mockToken = 'mock-token-for-testing';
      localStorage.setItem('auth-token', mockToken);
      localStorage.setItem('user', JSON.stringify({
        id: '123',
        username: 'testuser',
        name: 'Test User'
      }));
      
      // Visit any page to confirm the token is working
      cy.visit('/');
    },
    {
      validate: () => {
        // Check that the token exists in localStorage
        cy.window().then(win => {
          const token = win.localStorage.getItem('auth-token');
          expect(token).to.exist;
        });
      },
    }
  );
});

// Mock Media Devices for camera access
Cypress.Commands.add('mockMediaDevices', () => {
  cy.window().then(win => {
    // Create a mock video stream
    cy.stub(win.navigator.mediaDevices, 'getUserMedia')
      .callsFake(() => {
        // Create a mock video track
        const mockTrack = {
          id: 'mock-video-track',
          kind: 'video',
          enabled: true,
          stop: cy.stub().as('stopTrack')
        };
        
        // Create a mock stream with the track
        const mockStream = {
          id: 'mock-video-stream',
          active: true,
          getVideoTracks: () => [mockTrack],
          getTracks: () => [mockTrack],
          getAudioTracks: () => []
        };
        
        return Promise.resolve(mockStream);
      });
      
    // Mock HTMLVideoElement methods
    Object.defineProperties(win.HTMLVideoElement.prototype, {
      videoWidth: { get: () => 640 },
      videoHeight: { get: () => 480 },
      readyState: { get: () => 4 } // HAVE_ENOUGH_DATA
    });
  });
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