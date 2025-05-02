import Foundation

// Protocol defining the interface for secure token storage
protocol KeychainServiceProtocol {
    // Core methods
    func saveToken(_ token: String) throws
    func loadToken() throws -> String?
    func deleteToken() throws
    
    // Authentication methods used by AuthViewModel
    func getAccessToken() -> String?
    func saveAccessToken(_ token: String)
    func saveRefreshToken(_ token: String)
    func saveUserId(_ userId: String)
    func getUserId() -> String?
    func clearAllTokens()
} 