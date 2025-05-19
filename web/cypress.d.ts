/// <reference types="cypress" />

// Extend the Cypress namespace to include custom commands
declare namespace Cypress {
  interface Chainable<Subject = any> {
    /**
     * Custom command to quickly log in without UI interaction
     * @param username - The username to log in with (default: 'testuser')
     * @param password - The password to log in with (default: 'password123')
     * @example cy.login()
     * @example cy.login('customuser', 'custompass')
     */
    login(username?: string, password?: string): Chainable<JQuery<HTMLElement>>;

    /**
     * Custom command to navigate to a page with dark mode enabled
     * @param path - The path to navigate to (default: '/')
     * @example cy.visitWithDarkMode('/dashboard')
     */
    visitWithDarkMode(path?: string): Chainable<Window>;

    /**
     * Custom command to seed the test database with fixtures
     * @param fixtures - Array of fixture data to seed
     * @example cy.seedTestData([{ type: 'user', data: { username: 'test' } }])
     */
    seedTestData(fixtures?: any[]): Chainable<Response<any>>;

    /**
     * Custom command to take a Percy visual snapshot
     * @param name - Name for the snapshot
     * @example cy.visualSnapshot('dashboard')
     */
    visualSnapshot(name: string): Chainable<void>;
  }
} 