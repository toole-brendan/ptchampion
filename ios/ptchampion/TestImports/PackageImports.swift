import Foundation
import GoogleSignIn
import GoogleSignInSwift
import DesignTokens
import Components
import PTDesignSystem

// This file ensures all package products are properly imported
// It will not be included in the final app
func testImports() {
    // GoogleSignIn test
    let config = GIDConfiguration(clientID: "test_client_id")
    print("GoogleSignIn config: \(config)")
    
    // Design system test - just reference some types
    let _ = AppTheme.shared
}
