import SwiftUI
import PTDesignSystem
import XCTest
@testable import PTChampion

final class UserModelTests: XCTestCase {
    
    var sut: User!
    
    override func setUp() {
        super.setUp()
        // Initialize a standard user for testing
        sut = User(
            id: 1,
            username: "testuser",
            email: "test@example.com",
            fullName: "Test User",
            createdAt: Date(),
            profileImageURL: nil
        )
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func testUserInitialization() {
        // Test that the user is correctly initialized with provided values
        XCTAssertEqual(sut.id, 1)
        XCTAssertEqual(sut.username, "testuser")
        XCTAssertEqual(sut.email, "test@example.com")
        XCTAssertEqual(sut.fullName, "Test User")
        XCTAssertNil(sut.profileImageURL)
    }
    
    func testUserEquality() {
        // Create a user with the same ID but different details
        let sameIdUser = User(
            id: 1,
            username: "differentuser",
            email: "different@example.com",
            fullName: "Different User",
            createdAt: Date(),
            profileImageURL: nil
        )
        
        // Create a user with different ID but same details
        let differentIdUser = User(
            id: 2,
            username: "testuser",
            email: "test@example.com",
            fullName: "Test User",
            createdAt: sut.createdAt,
            profileImageURL: nil
        )
        
        // User equality should be based on ID only
        XCTAssertEqual(sut, sameIdUser)
        XCTAssertNotEqual(sut, differentIdUser)
    }
    
    func testUserDisplayName() {
        // Test with full name present
        XCTAssertEqual(sut.displayName, "Test User")
        
        // Test with empty full name - should use username instead
        let userWithoutFullName = User(
            id: 3,
            username: "noname",
            email: "noname@example.com",
            fullName: "",
            createdAt: Date(),
            profileImageURL: nil
        )
        XCTAssertEqual(userWithoutFullName.displayName, "noname")
    }
    
    func testUserProfileImageAvailability() {
        // User without profile image
        XCTAssertFalse(sut.hasProfileImage)
        
        // User with profile image
        let userWithImage = User(
            id: 4,
            username: "withimage",
            email: "withimage@example.com",
            fullName: "With Image",
            createdAt: Date(),
            profileImageURL: URL(string: "https://example.com/image.jpg")
        )
        XCTAssertTrue(userWithImage.hasProfileImage)
    }
    
    func testUserInitials() {
        // Test standard case - should return "TU" for "Test User"
        XCTAssertEqual(sut.initials, "TU")
        
        // Test with single name
        let singleNameUser = User(
            id: 5,
            username: "single",
            email: "single@example.com",
            fullName: "Single",
            createdAt: Date(),
            profileImageURL: nil
        )
        XCTAssertEqual(singleNameUser.initials, "S")
        
        // Test with multi-part name
        let multiPartNameUser = User(
            id: 6,
            username: "multi",
            email: "multi@example.com",
            fullName: "First Middle Last",
            createdAt: Date(),
            profileImageURL: nil
        )
        XCTAssertEqual(multiPartNameUser.initials, "FL")
    }
} 