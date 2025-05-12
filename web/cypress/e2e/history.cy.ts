describe('History Page', () => {
  beforeEach(() => {
    // Mock the token to bypass authentication
    cy.window().then((win) => {
      win.localStorage.setItem('pt_champion_token', 'mock-token');
      win.localStorage.setItem('pt_champion_user', JSON.stringify({
        id: 1, 
        username: 'testuser', 
        display_name: 'Test User'
      }));
    });

    // Mock API responses
    cy.intercept('GET', '**/exercises*', {
      statusCode: 200,
      body: {
        items: [
          {
            id: 123,
            user_id: 1,
            exercise_id: 1,
            exercise_type: 'Push-ups',
            exercise_name: 'Push-ups',
            reps: 30,
            time_in_seconds: 120,
            grade: 85,
            created_at: '2023-07-15T14:30:00Z',
          },
          {
            id: 456,
            user_id: 1,
            exercise_id: 4,
            exercise_type: 'Running',
            exercise_name: 'Running',
            distance: 5000, // 5km in meters
            time_in_seconds: 1800, // 30 minutes
            grade: 92,
            created_at: '2023-07-16T08:15:00Z',
          }
        ],
        total_count: 2,
        page: 1,
        page_size: 20
      }
    }).as('getExercises');

    cy.intercept('GET', '**/exercises/123', {
      statusCode: 200,
      body: {
        id: 123,
        user_id: 1,
        exercise_id: 1,
        exercise_type: 'Push-ups',
        exercise_name: 'Push-ups',
        reps: 30,
        time_in_seconds: 120,
        grade: 85,
        created_at: '2023-07-15T14:30:00Z',
      }
    }).as('getExerciseDetail');

    // Visit the history page
    cy.visit('/history');
  });

  it('should load workout history page', () => {
    // Wait for the page to load
    cy.wait('@getExercises');
    
    // Check page title
    cy.contains('Training History').should('be.visible');
    
    // Check summary stats
    cy.contains('TOTAL WORKOUTS').should('be.visible');
    cy.contains('TOTAL TIME').should('be.visible');
    cy.contains('TOTAL REPS').should('be.visible');
  });

  it('should display workout cards', () => {
    cy.wait('@getExercises');
    
    // Check if both workout cards are displayed
    cy.contains('Push-ups').should('be.visible');
    cy.contains('Running').should('be.visible');
    
    // Check if the metrics are displayed
    cy.contains('30').should('be.visible');
    cy.contains('5.00 km').should('be.visible');
  });

  it('should navigate to detail page when a workout card is clicked', () => {
    cy.wait('@getExercises');
    
    // Click on the first workout card
    cy.contains('Push-ups').click();
    
    // Wait for the detail API call
    cy.wait('@getExerciseDetail');
    
    // Check we're on the detail page
    cy.url().should('include', '/history/123');
    cy.contains('Workout Details').should('be.visible');
    
    // Check form score is displayed
    cy.contains('Form Score').should('be.visible');
    cy.contains('85%').should('be.visible');
    
    // Check back button works
    cy.contains('Back to History').click();
    cy.url().should('include', '/history');
    cy.url().should('not.include', '/123');
  });

  it('should filter workouts by exercise type', () => {
    cy.wait('@getExercises');
    
    // Open the exercise type filter
    cy.get('select, [role=combobox]').contains('All Exercises').click({force: true});
    
    // Select Push-ups
    cy.contains('Push-ups').click({force: true});
    
    // Check only Push-ups workout is displayed
    cy.contains('Push-ups').should('be.visible');
    cy.contains('Running').should('not.exist');
  });

  it('should show share button on detail page', () => {
    cy.wait('@getExercises');
    
    // Navigate to detail page
    cy.contains('Push-ups').click();
    cy.wait('@getExerciseDetail');
    
    // Check share button exists
    cy.contains('Share').should('be.visible');
    
    // Mock navigator.share or clipboard
    cy.window().then((win) => {
      cy.stub(win.navigator.clipboard, 'writeText').resolves();
    });
    
    // Click share button
    cy.contains('Share').click();
    
    // Verify copy to clipboard was called
    cy.window().then((win) => {
      expect(win.navigator.clipboard.writeText).to.be.called;
    });
  });
}); 