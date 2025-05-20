import XCTest
import SwiftUI
import ViewInspector
@testable import Components

extension PTButton: Inspectable {}

final class ButtonTests: XCTestCase {
    func testButtonTitle() throws {
        let sut = PTButton("Test Button") {}
        let text = try sut.inspect().find(text: "Test Button")
        XCTAssertEqual(try text.string(), "Test Button")
    }
    
    func testButtonAction() throws {
        var actionPerformed = false
        let sut = PTButton("Action Button") {
            actionPerformed = true
        }
        
        try sut.inspect().find(button: "Action Button").tap()
        XCTAssertTrue(actionPerformed)
    }
}

// Note: For this test to compile, you would need to add the ViewInspector
// package as a dependency in Package.swift. This is just a demonstration
// of how you would write tests for the components. 