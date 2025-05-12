/**
 * Workout Summary Component and Flow Tests 
 * Tests the workout complete summary flow
 */

describe('Workout Summary Flow', () => {
  beforeEach(() => {
    // Mock user authentication
    cy.intercept('POST', '/api/auth/login', {
      statusCode: 200,
      body: {
        user: {
          id: '123',
          email: 'test@example.com',
          name: 'Test User',
        },
        token: 'fake-jwt-token',
      },
    }).as('loginRequest');

    // Mock successful exercise save
    cy.intercept('POST', '/api/exercises', {
      statusCode: 200,
      body: {
        id: '456',
        exercise_type: 'PUSHUP',
        reps: 5,
        time_in_seconds: 30,
        grade: 65,
        created_at: new Date().toISOString(),
      },
    }).as('saveExercise');

    // Mock successful exercise deletion
    cy.intercept('DELETE', '/api/exercises/*', {
      statusCode: 200,
      body: { success: true },
    }).as('deleteExercise');

    // Login
    cy.visit('/login');
    cy.get('input[name="email"]').type('test@example.com');
    cy.get('input[name="password"]').type('password');
    cy.get('button[type="submit"]').click();
    cy.wait('@loginRequest');
  });

  it('should show workout summary after completing push-ups', () => {
    // Visit push-ups tracker
    cy.visit('/exercises/pushups');
    cy.url().should('include', '/exercises/pushups');
    
    // Start exercise 
    cy.get('button').contains('Start').click();
    
    // Since we can't directly interact with the video, mock the rep count
    // by triggering the Finish button directly without waiting for reps
    cy.wait(2000); // Wait a bit to simulate exercise time
    
    // Skip to Finish by clicking the button directly
    cy.get('button').contains('Finish').should('exist').click({ force: true });
    
    // Should navigate to workout complete page
    cy.url().should('include', '/complete');
    
    // Verify workout summary elements
    cy.contains('Workout Completed!').should('be.visible');
    cy.contains('Push-ups session').should('be.visible');
    cy.contains('Duration').should('be.visible');
    
    // Test sharing 
    cy.window().then(win => {
      // Mock clipboard API
      cy.stub(win.navigator.clipboard, 'writeText').resolves();
    });
    cy.contains('button', 'Share Workout').click();
    cy.window().its('navigator.clipboard.writeText').should('be.called');
    cy.contains('Copied to Clipboard').should('be.visible');
    
    // Test discard button and confirmation
    cy.contains('button', 'Discard Workout').click();
    cy.contains('Are you sure?').should('be.visible');
    cy.contains('button', 'Cancel').click();
    
    // Test done button
    cy.contains('button', 'Done').click();
    cy.url().should('include', '/dashboard');
  });

  it('should handle workout complete flow when offline', () => {
    // Simulate offline
    cy.intercept('POST', '/api/exercises', {
      forceNetworkError: true
    }).as('failedSave');
    
    // Trigger workout flow
    cy.visit('/exercises/situps');
    cy.get('button').contains('Start').click();
    
    // Wait a bit to simulate exercise time
    cy.wait(2000);
    
    // Skip to Finish by clicking the button directly
    cy.get('button').contains('Finish').should('exist').click({ force: true });
    
    // Should navigate to workout complete page
    cy.url().should('include', '/complete');
    
    // Verify "not saved yet" message
    cy.contains('This workout hasn\'t been saved yet').should('be.visible');
    cy.contains('Will sync when online').should('be.visible');
    
    // Discard the workout (should work even offline)
    cy.contains('button', 'Discard Workout').click();
    cy.contains('button', 'Delete').click();
    
    // Should navigate back to exercises
    cy.url().should('include', '/exercises');
  });
}); 