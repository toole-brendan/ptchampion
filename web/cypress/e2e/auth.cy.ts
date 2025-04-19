/// <reference types="cypress" />

describe('Authentication Flow', () => {
  beforeEach(() => {
    // Clear all cookies and localStorage to start fresh
    cy.clearCookies();
    cy.clearLocalStorage();
  });

  it('should allow user to login with valid credentials', () => {
    // Setup intercept for login request
    cy.intercept('POST', `${Cypress.env('apiUrl')}/auth/login`, {
      statusCode: 200,
      body: {
        token: 'fake-jwt-token',
        user: {
          id: 1,
          username: 'testuser',
          email: 'test@example.com',
          fullName: 'Test User',
        },
      },
    }).as('loginRequest');

    // Visit the login page
    cy.visit('/login');

    // Fill in login form
    cy.get('input[name="username"]').type('testuser');
    cy.get('input[name="password"]').type('password123');

    // Submit form
    cy.get('button[type="submit"]').click();

    // Wait for the login request to complete
    cy.wait('@loginRequest');

    // Verify redirect to dashboard after successful login
    cy.url().should('include', '/dashboard');

    // Verify user info is displayed
    cy.contains('Welcome, Test User').should('be.visible');
  });

  it('should display error message for invalid credentials', () => {
    // Setup intercept for failed login
    cy.intercept('POST', `${Cypress.env('apiUrl')}/auth/login`, {
      statusCode: 401,
      body: {
        message: 'Invalid username or password',
      },
    }).as('failedLoginRequest');

    // Visit the login page
    cy.visit('/login');

    // Fill in login form with invalid credentials
    cy.get('input[name="username"]').type('wronguser');
    cy.get('input[name="password"]').type('wrongpassword');

    // Submit form
    cy.get('button[type="submit"]').click();

    // Wait for the login request to complete
    cy.wait('@failedLoginRequest');

    // Verify URL hasn't changed
    cy.url().should('include', '/login');

    // Verify error message is displayed
    cy.contains('Invalid username or password').should('be.visible');
  });

  it('should allow user registration with valid data', () => {
    // Setup intercept for registration
    cy.intercept('POST', `${Cypress.env('apiUrl')}/auth/register`, {
      statusCode: 201,
      body: {
        token: 'fake-jwt-token',
        user: {
          id: 1,
          username: 'newuser',
          email: 'new@example.com',
          fullName: 'New User',
        },
      },
    }).as('registerRequest');

    // Visit the registration page
    cy.visit('/register');

    // Fill in registration form
    cy.get('input[name="username"]').type('newuser');
    cy.get('input[name="email"]').type('new@example.com');
    cy.get('input[name="fullName"]').type('New User');
    cy.get('input[name="password"]').type('securepassword');
    cy.get('input[name="confirmPassword"]').type('securepassword');

    // Submit form
    cy.get('button[type="submit"]').click();

    // Wait for the registration request to complete
    cy.wait('@registerRequest');

    // Verify redirect to dashboard after successful registration
    cy.url().should('include', '/dashboard');

    // Verify user info is displayed
    cy.contains('Welcome, New User').should('be.visible');
  });

  it('should allow user to logout', () => {
    // Login first (using local storage to simulate logged in state)
    cy.window().then((window) => {
      window.localStorage.setItem('auth_token', 'fake-jwt-token');
      window.localStorage.setItem('user', JSON.stringify({
        id: 1,
        username: 'testuser',
        email: 'test@example.com',
        fullName: 'Test User',
      }));
    });

    // Visit the dashboard
    cy.visit('/dashboard');

    // Verify we're logged in
    cy.contains('Welcome, Test User').should('be.visible');

    // Click logout button
    cy.get('[data-testid="logout-button"]').click();

    // Verify redirect to login page
    cy.url().should('include', '/login');

    // Verify localStorage is cleared
    cy.window().its('localStorage.auth_token').should('be.undefined');
  });
}); 