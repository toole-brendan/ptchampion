describe('Leaderboard Page', () => {
  beforeEach(() => {
    // Mock the API response for auth
    cy.intercept('POST', '/api/v1/auth/login', {
      statusCode: 200,
      body: {
        access_token: 'mock-token',
        user: {
          id: 1,
          username: 'testuser',
          first_name: 'Test',
          last_name: 'User',
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString()
        }
      }
    }).as('loginRequest');

    // Mock the global leaderboard API response
    cy.intercept('GET', '/api/v1/leaderboard/overall', {
      statusCode: 200,
      body: [
        {
          user_id: 1,
          username: 'champion',
          first_name: 'Champion',
          last_name: 'User',
          max_grade: 100,
          last_attempt_date: new Date().toISOString()
        },
        {
          user_id: 2,
          username: 'secondplace',
          first_name: 'Second',
          last_name: 'Place',
          max_grade: 90,
          last_attempt_date: new Date().toISOString()
        },
        {
          user_id: 3,
          username: 'thirdplace',
          first_name: 'Third',
          last_name: 'Place',
          max_grade: 80,
          last_attempt_date: new Date().toISOString()
        }
      ]
    }).as('getOverallLeaderboard');

    // Mock other exercise type leaderboards
    cy.intercept('GET', '/api/v1/leaderboard/pushup', {
      statusCode: 200,
      body: [
        {
          user_id: 2,
          username: 'pushupking',
          first_name: 'Push-up',
          last_name: 'King',
          max_grade: 50,
          last_attempt_date: new Date().toISOString()
        }
      ]
    }).as('getPushupLeaderboard');

    // Mock empty leaderboard
    cy.intercept('GET', '/api/v1/leaderboard/pullup', {
      statusCode: 200,
      body: []
    }).as('getEmptyLeaderboard');

    // Mock local leaderboard response
    cy.intercept('GET', '/api/v1/leaderboard/overall?lat=*&lng=*', {
      statusCode: 200,
      body: [
        {
          user_id: 4,
          username: 'localchamp',
          first_name: 'Local',
          last_name: 'Champion',
          max_grade: 95,
          last_attempt_date: new Date().toISOString()
        }
      ]
    }).as('getLocalLeaderboard');

    // Log in
    cy.visit('/login');
    cy.get('input[name="username"]').type('testuser');
    cy.get('input[name="password"]').type('password');
    cy.get('button[type="submit"]').click();
    cy.wait('@loginRequest');

    // Navigate to the leaderboard page
    cy.visit('/leaderboard');
    cy.wait('@getOverallLeaderboard');
  });

  it('displays the leaderboard with correct headers and data', () => {
    // Check page title
    cy.contains('h2', 'Leaderboard').should('be.visible');
    
    // Check filter section
    cy.contains('Exercise Type').should('be.visible');
    cy.contains('Leaderboard Scope').should('be.visible');
    
    // Check table headers
    cy.contains('th', 'Rank').should('be.visible');
    cy.contains('th', 'User').should('be.visible');
    cy.contains('th', 'Score').should('be.visible');
    
    // Check data rows
    cy.contains('Champion User').should('be.visible');
    cy.contains('Second Place').should('be.visible');
    cy.contains('Third Place').should('be.visible');
    
    // Check medals are displayed for top 3
    cy.get('tr').eq(1).find('svg').should('exist'); // First row medal
    cy.get('tr').eq(2).find('svg').should('exist'); // Second row medal
    cy.get('tr').eq(3).find('svg').should('exist'); // Third row medal
  });

  it('allows filtering by exercise type', () => {
    // Select pushups from dropdown
    cy.get('#exercise-filter').click();
    cy.contains('Push-ups').click();
    cy.wait('@getPushupLeaderboard');
    
    // Verify pushup leaderboard is displayed
    cy.contains('Push-up King').should('be.visible');
    cy.contains('50 reps').should('be.visible');
  });

  it('shows empty state when no data is available', () => {
    // Select pullups from dropdown
    cy.get('#exercise-filter').click();
    cy.contains('Pull-ups').click();
    cy.wait('@getEmptyLeaderboard');
    
    // Verify empty state message
    cy.contains('No rankings found for Pull-ups').should('be.visible');
  });

  it('handles local scope selection', () => {
    // Mock geolocation API
    cy.window().then((win) => {
      cy.stub(win.navigator.geolocation, 'getCurrentPosition')
        .callsFake((success) => {
          success({
            coords: {
              latitude: 37.7749,
              longitude: -122.4194,
              accuracy: 10,
              altitude: null,
              altitudeAccuracy: null,
              heading: null,
              speed: null
            },
            timestamp: Date.now()
          });
        });
    });
    
    // Select local scope
    cy.get('#scope-filter').click();
    cy.contains('Local (5 Miles)').click();
    
    // Verify local leaderboard API is called with coordinates
    cy.wait('@getLocalLeaderboard');
    
    // Verify local leaderboard data
    cy.contains('Local Champion').should('be.visible');
  });

  it('shows error message when location permission is denied', () => {
    // Mock geolocation permission denied
    cy.window().then((win) => {
      cy.stub(win.navigator.geolocation, 'getCurrentPosition')
        .callsFake((_success, error) => {
          error({
            code: 1, // Permission denied
            message: 'User denied geolocation',
            PERMISSION_DENIED: 1,
            POSITION_UNAVAILABLE: 2,
            TIMEOUT: 3
          });
        });
    });
    
    // Select local scope
    cy.get('#scope-filter').click();
    cy.contains('Local (5 Miles)').click();
    
    // Verify error message
    cy.contains('Location Error').should('be.visible');
    cy.contains('User denied geolocation').should('be.visible');
    cy.contains('TRY AGAIN').should('be.visible');
  });

  it('handles API errors gracefully', () => {
    // Mock API error
    cy.intercept('GET', '/api/v1/leaderboard/situp', {
      statusCode: 500,
      body: { error: 'Server error' }
    }).as('apiError');
    
    // Select situps
    cy.get('#exercise-filter').click();
    cy.contains('Sit-ups').click();
    cy.wait('@apiError');
    
    // Verify error is displayed
    cy.contains('Error loading leaderboard').should('be.visible');
    cy.contains('RETRY').should('be.visible');
    
    // Test retry functionality
    cy.intercept('GET', '/api/v1/leaderboard/situp', {
      statusCode: 200,
      body: [] // Empty response on retry
    }).as('retryRequest');
    
    cy.contains('RETRY').click();
    cy.wait('@retryRequest');
    
    // Verify empty state after successful retry
    cy.contains('No rankings found for Sit-ups').should('be.visible');
  });
}); 