import Foundation

// Protocol defining the interface for secure token storage
protocol KeychainServiceProtocol {
    // Core methods
    func saveToken(_ token: String) throws
    func loadToken() throws -> String?
    func deleteToken() throws
    
    // Additional helpers required by UnifiedNetworkService
    func getToken() throws -> String?          // thin wrapper around loadToken()
    func getRefreshToken() throws -> String?   // may return nil
    func deleteRefreshToken() throws
    
    // Authentication methods used by AuthViewModel
    func getAccessToken() -> String?
    func saveAccessToken(_ token: String)
    func saveRefreshToken(_ token: String)
    func saveUserID(_ userId: String)
    func getUserID() -> String?
    func clearAllTokens()
} 