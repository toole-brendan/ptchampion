import XCTest
@testable import PTChampion

final class LoginUITests: XCTestCase {
    
    let app = XCUIApplication()
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        
        // Configure app launch arguments/environment
        app.launchArguments = ["UITesting"]
        app.launchEnvironment = ["ENV": "TEST"]
        
        // Launch app before each test
        app.launch()
    }
    
    override func tearDownWithError() throws {
        // Terminate the app after each test
        app.terminate()
    }
    
    func testLoginScreenElements() throws {
        // Verify login screen has all required elements
        
        XCTAssertTrue(app.staticTexts["Welcome to PT Champion"].exists)
        XCTAssertTrue(app.textFields["Username"].exists)
        XCTAssertTrue(app.secureTextFields["Password"].exists)
        XCTAssertTrue(app.buttons["Log In"].exists)
        XCTAssertTrue(app.buttons["Sign Up"].exists)
        XCTAssertTrue(app.buttons["Forgot Password?"].exists)
    }
    
    func testSuccessfulLogin() throws {
        // Test successful login flow
        
        // Enter credentials
        let usernameField = app.textFields["Username"]
        usernameField.tap()
        usernameField.typeText("testuser")
        
        let passwordField = app.secureTextFields["Password"]
        passwordField.tap()
        passwordField.typeText("password123")
        
        // Tap login button
        app.buttons["Log In"].tap()
        
        // Verify dashboard is shown after successful login (timeout: 5 seconds)
        let dashboardTitle = app.staticTexts["Dashboard"]
        XCTAssertTrue(dashboardTitle.waitForExistence(timeout: 5))
        
        // Verify user name is displayed
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "Welcome, Test User")).element.exists)
    }
    
    func testFailedLogin() throws {
        // Test failed login with invalid credentials
        
        // Enter invalid credentials
        let usernameField = app.textFields["Username"]
        usernameField.tap()
        usernameField.typeText("wronguser")
        
        let passwordField = app.secureTextFields["Password"]
        passwordField.tap()
        passwordField.typeText("wrongpassword")
        
        // Tap login button
        app.buttons["Log In"].tap()
        
        // Verify error message is shown
        let errorMessage = app.staticTexts["Invalid username or password"]
        XCTAssertTrue(errorMessage.waitForExistence(timeout: 5))
        
        // Verify we're still on the login screen
        XCTAssertTrue(app.buttons["Log In"].exists)
    }
    
    func testNavigationToSignUp() throws {
        // Test navigation to sign up screen
        
        // Tap sign up button
        app.buttons["Sign Up"].tap()
        
        // Verify sign up screen is shown
        XCTAssertTrue(app.staticTexts["Create an Account"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.textFields["Full Name"].exists)
        XCTAssertTrue(app.textFields["Email"].exists)
        XCTAssertTrue(app.textFields["Username"].exists)
        XCTAssertTrue(app.secureTextFields["Password"].exists)
        XCTAssertTrue(app.secureTextFields["Confirm Password"].exists)
        XCTAssertTrue(app.buttons["Create Account"].exists)
    }
    
    func testNavigationToForgotPassword() throws {
        // Test navigation to forgot password screen
        
        // Tap forgot password button
        app.buttons["Forgot Password?"].tap()
        
        // Verify forgot password screen is shown
        XCTAssertTrue(app.staticTexts["Reset Password"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.textFields["Email"].exists)
        XCTAssertTrue(app.buttons["Send Reset Link"].exists)
    }
} 