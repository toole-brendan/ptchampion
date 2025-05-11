/// <reference types="cypress" />

describe('Navigation Flow', () => {
  beforeEach(() => {
    // Clear all cookies and localStorage to start fresh
    cy.clearCookies();
    cy.clearLocalStorage();
    
    // Mock the authenticated user
    cy.window().then((window) => {
      window.localStorage.setItem('auth_token', 'fake-jwt-token');
      window.localStorage.setItem('user', JSON.stringify({
        id: 1,
        username: 'testuser',
        email: 'test@example.com',
        fullName: 'Test User',
      }));
    });

    // Intercept API calls that might happen on page load
    cy.intercept('GET', '**/user/profile', {
      statusCode: 200,
      body: {
        id: 1,
        username: 'testuser',
        email: 'test@example.com',
        fullName: 'Test User',
      }
    }).as('getUserProfile');

    cy.intercept('GET', '**/dashboard/stats', {
      statusCode: 200,
      body: {
        totalWorkouts: 15,
        monthlyWorkouts: 5,
        recentExercises: [
          { name: 'Push-ups', count: 10, date: new Date().toISOString() },
          { name: 'Pull-ups', count: 5, date: new Date().toISOString() }
        ]
      }
    }).as('getDashboardStats');
  });

  it('should navigate from Exercises to specific exercise tracker and then to History', () => {
    // Start at the dashboard
    cy.visit('/dashboard');
    
    // Click on Exercises in the sidebar
    cy.contains('Exercises').click();
    
    // Verify we're on the exercises page
    cy.url().should('include', '/exercises');
    
    // Click on the Push-ups exercise
    cy.contains('Push-ups').click();
    
    // Verify we're on the push-ups exercise page
    cy.url().should('include', '/exercises/pushups');
    cy.contains('Push-ups Exercise').should('be.visible');
    
    // Navigate to history using the sidebar
    cy.contains('History').click();
    
    // Verify we're on the history page
    cy.url().should('include', '/history');
    cy.contains('Workout History').should('be.visible');
  });

  it('should handle the back button correctly after visiting a tracker', () => {
    // Start at the exercises list
    cy.visit('/exercises');
    
    // Click on the Pull-ups exercise
    cy.contains('Pull-ups').click();
    
    // Verify we're on the pull-ups exercise page
    cy.url().should('include', '/exercises/pullups');
    
    // Click the back button
    cy.get('button').contains('Back').click();
    
    // Verify we're back at the exercises page
    cy.url().should('include', '/exercises');
  });

  it('should handle direct navigation to exercise trackers', () => {
    // Directly navigate to the sit-ups tracker
    cy.visit('/exercises/situps');
    
    // Verify correct page loads
    cy.contains('Sit-ups Exercise').should('be.visible');
    
    // Test that sidebar navigation works from here
    cy.contains('Leaderboard').click();
    
    // Verify navigation to leaderboard works
    cy.url().should('include', '/leaderboard');
  });

  it('should redirect from old tracker paths to exercise paths', () => {
    // Try to visit an old tracker URL
    cy.visit('/trackers/pushups');
    
    // Verify redirection to the new URL
    cy.url().should('include', '/exercises/pushups');
    cy.contains('Push-ups Exercise').should('be.visible');
    
    // Try another old URL
    cy.visit('/trackers/running');
    
    // Verify redirection
    cy.url().should('include', '/exercises/running');
    cy.contains('Running Exercise').should('be.visible');
  });
}); 