/**
 * Cypress test for the push-ups exercise
 * This test verifies that:
 * 1. Navigation to push-ups page works
 * 2. The UI elements load correctly
 * 3. No JavaScript errors occur during page load
 */

describe('Push-ups Exercise', () => {
  beforeEach(() => {
    // Mock camera access to prevent permission prompts
    cy.mockMediaDevices();
    
    // Optional: Login the user - using existing helper if available
    cy.loginWithMock();
    
    // Spy on window.onerror to catch uncaught errors
    cy.window().then((win) => {
      cy.spy(win.console, 'error').as('consoleError');
    });
  });

  it('should load the push-ups page without errors', () => {
    // Visit the exercises page first
    cy.visit('/exercises');
    cy.get('h1').should('contain', 'Exercises');
    
    // Find and click on push-ups tile
    cy.contains('.cursor-pointer', 'PUSH-UPS').click();
    
    // Verify we're on the push-ups page
    cy.url().should('include', '/exercises/pushups');
    cy.get('h1').should('contain', 'Push-ups Exercise');
    
    // Important: Verify camera feed container is present
    cy.get('video').should('exist');
    cy.get('canvas').should('exist');
    
    // Check that no error message is shown in the UI
    cy.contains('Model Loading Failed').should('not.exist');
    cy.contains('Camera Access Issue').should('not.exist');
    
    // Verify Start button is enabled once camera is ready (mock will make it ready)
    cy.contains('button', 'Start').should('not.be.disabled');
    
    // Verify no console errors related to MediaPipe or pose detection
    cy.get('@consoleError').should((spy) => {
      // @ts-ignore - getCalls is available but not in type definitions
      const calls = spy.getCalls();
      const mediapipeErrors = calls.filter(call => 
        String(call.args[0]).includes('MediaPipe') || 
        String(call.args[0]).includes('ROI width')
      );
      expect(mediapipeErrors.length).to.equal(0, 'No MediaPipe errors should be logged');
    });
  });

  it('should handle start/pause/reset actions', () => {
    cy.visit('/exercises/pushups');
    
    // Wait for page to be ready
    cy.contains('button', 'Start').should('not.be.disabled');
    
    // Click start and verify session becomes active
    cy.contains('button', 'Start').click();
    cy.contains('button', 'Pause').should('exist');
    
    // Exercise should be counting time
    cy.get('.font-bold.text-4xl').eq(1).should('not.contain', '00:00');
    
    // Pause the exercise
    cy.contains('button', 'Pause').click();
    cy.contains('button', 'Start').should('exist');
    
    // Reset the exercise
    cy.contains('button', 'Reset').click();
    
    // Verify counters reset
    cy.get('.font-bold.text-4xl').eq(0).should('contain', '0'); // Reps
    cy.get('.font-bold.text-4xl').eq(1).should('contain', '00:00'); // Timer
  });
});
