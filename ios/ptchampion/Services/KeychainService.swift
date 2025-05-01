import Foundation
import Security

/// Protocol for KeychainService to allow for easy mocking in tests
protocol KeychainServiceProtocol {
    func saveToken(_ token: String) throws
    func getToken() throws -> String?
    func deleteToken() throws
    
    func saveRefreshToken(_ token: String) throws
    func getRefreshToken() throws -> String?
    func deleteRefreshToken() throws
}

/// Service for securely storing authentication tokens in the keychain
class KeychainService {
    static let shared = KeychainService()
    
    private init() {}
    
    // Keys for storing different tokens
    private let accessTokenKey = "com.ptchampion.accessToken"
    private let refreshTokenKey = "com.ptchampion.refreshToken"
    private let userIdKey = "com.ptchampion.userId"
    
    // Store token in the keychain
    func saveToken(_ token: String, forKey key: String) -> Bool {
        deleteToken(forKey: key) // Remove existing token if any
        
        guard let tokenData = token.data(using: .utf8) else {
            print("KeychainService: Failed to convert token to data")
            return false
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: tokenData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("KeychainService: Failed to save token with status: \(status)")
            return false
        }
        
        return true
    }
    
    // Retrieve token from the keychain
    func getToken(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                print("KeychainService: Token not found for key: \(key)")
            } else {
                print("KeychainService: Failed to get token with status: \(status)")
            }
            return nil
        }
        
        guard let tokenData = result as? Data,
              let token = String(data: tokenData, encoding: .utf8) else {
            print("KeychainService: Failed to convert data to token")
            return nil
        }
        
        return token
    }
    
    // Delete token from the keychain
    func deleteToken(forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            print("KeychainService: Failed to delete token with status: \(status)")
            return false
        }
        
        return true
    }
    
    // Convenience methods for specific tokens
    func saveAccessToken(_ token: String) -> Bool {
        return saveToken(token, forKey: accessTokenKey)
    }
    
    func getAccessToken() -> String? {
        return getToken(forKey: accessTokenKey)
    }
    
    func saveRefreshToken(_ token: String) -> Bool {
        return saveToken(token, forKey: refreshTokenKey)
    }
    
    func getRefreshToken() -> String? {
        return getToken(forKey: refreshTokenKey)
    }
    
    func saveUserId(_ userId: String) -> Bool {
        return saveToken(userId, forKey: userIdKey)
    }
    
    func getUserId() -> String? {
        return getToken(forKey: userIdKey)
    }
    
    func clearAllTokens() {
        _ = deleteToken(forKey: accessTokenKey)
        _ = deleteToken(forKey: refreshTokenKey)
        _ = deleteToken(forKey: userIdKey)
    }
}

// Extension to make KeychainService compatible with the KeychainServiceProtocol
extension KeychainService: KeychainServiceProtocol {
    func saveToken(_ token: String) throws {
        if !saveAccessToken(token) {
            throw NSError(domain: "KeychainService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to save token"])
        }
    }
    
    func loadToken() throws -> String? {
        return getAccessToken()
    }
    
    func deleteToken() throws {
        if !deleteToken(forKey: accessTokenKey) {
            throw NSError(domain: "KeychainService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to delete token"])
        }
    }
    
    func getUserId() -> Int? {
        if let userIdString = getUserId() {
            return Int(userIdString)
        }
        return nil
    }
}

/// Errors related to keychain operations
enum KeychainError: Error {
    case saveError(status: OSStatus)
    case readError(status: OSStatus)
    case deleteError(status: OSStatus)
    case encodingError
    
    var description: String {
        switch self {
        case .saveError(let status):
            return "Failed to save to keychain. Status: \(status)"
        case .readError(let status):
            return "Failed to read from keychain. Status: \(status)"
        case .deleteError(let status):
            return "Failed to delete from keychain. Status: \(status)"
        case .encodingError:
            return "Failed to encode/decode data"
        }
    }
}

// MARK: - Extension for App Groups Support
extension KeychainService {
    /// Configure keychain for sharing with app group (useful for Watch extensions)
    /// - Parameter accessGroup: The app group identifier
    /// - Returns: Self for chaining
    func configureForSharing(accessGroup: String) -> KeychainService {
        // This would modify the keychain query to include kSecAttrAccessGroup
        // For now, just returning self without modification
        return self
    }
}

// MARK: - Mock for Testing/Preview
class MockKeychainService: KeychainServiceProtocol {
    private var mockStorage: [String: String] = [:]
    
    func saveToken(_ token: String) throws {
        mockStorage["accessToken"] = token
    }
    
    func getToken() throws -> String? {
        return mockStorage["accessToken"]
    }
    
    func deleteToken() throws {
        mockStorage.removeValue(forKey: "accessToken")
    }
    
    func saveRefreshToken(_ token: String) throws {
        mockStorage["refreshToken"] = token
    }
    
    func getRefreshToken() throws -> String? {
        return mockStorage["refreshToken"]
    }
    
    func deleteRefreshToken() throws {
        mockStorage.removeValue(forKey: "refreshToken")
    }
} 