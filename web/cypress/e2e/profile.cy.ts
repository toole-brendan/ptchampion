describe('Profile Page', () => {
  beforeEach(() => {
    // Use existing login command instead of loginWithMockUser
    cy.login('testuser', 'password123');
    
    // Clear localStorage for settings to ensure consistent test state
    window.localStorage.removeItem('pt_app_settings');
  });

  it('should display user information correctly', () => {
    cy.visit('/profile');
    
    // Check if profile form is populated with user data
    cy.get('input[name="username"]').should('have.value', 'testuser');
    cy.get('input[name="display_name"]').should('have.value', 'Test User');
    
    // Check page structure
    cy.contains('h1', 'Profile & Settings').should('be.visible');
    cy.contains('Edit Profile').should('be.visible');
    cy.contains('App Settings').should('be.visible');
    cy.contains('Account Actions').should('be.visible');
  });

  it('should update profile information successfully', () => {
    cy.visit('/profile');
    
    // Update display name
    cy.get('input[name="display_name"]')
      .clear()
      .type('Updated Name');
    
    // Submit form
    cy.contains('button', 'Save Changes').click();
    
    // Check for success message
    cy.contains('Profile updated successfully').should('be.visible');
    
    // Reload to verify persistence
    cy.reload();
    cy.get('input[name="display_name"]').should('have.value', 'Updated Name');
  });

  it('should toggle and persist geolocation setting', () => {
    // Mock geolocation permission
    cy.window().then((win) => {
      cy.stub(win.navigator.geolocation, 'getCurrentPosition').callsFake((success) => {
        return success({ 
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
    
    cy.visit('/profile');
    
    // Toggle geolocation on
    cy.get('#geolocation-switch').click({ force: true });
    
    // Verify toast appears
    cy.contains('Location Access Granted').should('be.visible');
    
    // Reload and verify persistence
    cy.reload();
    cy.get('#geolocation-switch').should('be.checked');
  });

  it('should navigate to Settings page', () => {
    cy.visit('/profile');
    
    // Click on More Settings button
    cy.contains('button', 'More Settings').click();
    
    // Verify navigation to settings page
    cy.url().should('include', '/settings');
    cy.contains('h1', 'Settings').should('be.visible');
    cy.contains('General Settings').should('be.visible');
    cy.contains('About & Legal').should('be.visible');
  });

  it('should log out user successfully', () => {
    cy.visit('/profile');
    
    // Click logout button
    cy.contains('button', 'Logout').click();
    
    // Verify redirect to login page
    cy.url().should('include', '/login');
  });

  it('should show delete account confirmation dialog', () => {
    cy.visit('/profile');
    
    // Click delete account button
    cy.contains('button', 'Delete Account').click();
    
    // Verify dialog appears
    cy.contains('Delete Your Account?').should('be.visible');
    cy.contains('This will permanently remove your account').should('be.visible');
    
    // Cancel deletion
    cy.contains('button', 'Cancel').click();
    
    // Verify dialog closed
    cy.contains('Delete Your Account?').should('not.exist');
  });
});
