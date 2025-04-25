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
class KeychainService: KeychainServiceProtocol {
    // Keys for keychain items
    private enum KeychainKeys {
        static let accessToken = "com.ptchampion.accessToken"
        static let refreshToken = "com.ptchampion.refreshToken"
    }
    
    // MARK: - Access Token Methods
    
    /// Save access token to keychain
    /// - Parameter token: The access token to save
    /// - Throws: KeychainError if save fails
    func saveToken(_ token: String) throws {
        try saveToKeychain(key: KeychainKeys.accessToken, data: token)
    }
    
    /// Retrieve access token from keychain
    /// - Returns: The access token if available
    /// - Throws: KeychainError if retrieval fails
    func getToken() throws -> String? {
        return try getFromKeychain(key: KeychainKeys.accessToken)
    }
    
    /// Delete access token from keychain
    /// - Throws: KeychainError if deletion fails
    func deleteToken() throws {
        try deleteFromKeychain(key: KeychainKeys.accessToken)
    }
    
    // MARK: - Refresh Token Methods
    
    /// Save refresh token to keychain
    /// - Parameter token: The refresh token to save
    /// - Throws: KeychainError if save fails
    func saveRefreshToken(_ token: String) throws {
        try saveToKeychain(key: KeychainKeys.refreshToken, data: token)
    }
    
    /// Retrieve refresh token from keychain
    /// - Returns: The refresh token if available
    /// - Throws: KeychainError if retrieval fails
    func getRefreshToken() throws -> String? {
        return try getFromKeychain(key: KeychainKeys.refreshToken)
    }
    
    /// Delete refresh token from keychain
    /// - Throws: KeychainError if deletion fails
    func deleteRefreshToken() throws {
        try deleteFromKeychain(key: KeychainKeys.refreshToken)
    }
    
    // MARK: - Private Helper Methods
    
    /// Save data to keychain
    /// - Parameters:
    ///   - key: The key under which to store the data
    ///   - data: The string data to store
    /// - Throws: KeychainError if save fails
    private func saveToKeychain(key: String, data: String) throws {
        guard let encodedData = data.data(using: .utf8) else {
            throw KeychainError.encodingError
        }
        
        // Delete any existing item before saving
        try? deleteFromKeychain(key: key)
        
        // Create keychain query
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: encodedData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        
        // Add item to keychain
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.saveError(status: status)
        }
    }
    
    /// Retrieve data from keychain
    /// - Parameter key: The key for the data to retrieve
    /// - Returns: The string data if available
    /// - Throws: KeychainError if retrieval fails
    private func getFromKeychain(key: String) throws -> String? {
        // Create keychain query
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        // Query the keychain
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        // Check query results
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                return nil
            }
            throw KeychainError.readError(status: status)
        }
        
        // Convert data to string
        guard let data = dataTypeRef as? Data,
              let result = String(data: data, encoding: .utf8) else {
            throw KeychainError.encodingError
        }
        
        return result
    }
    
    /// Delete data from keychain
    /// - Parameter key: The key for the data to delete
    /// - Throws: KeychainError if deletion fails
    private func deleteFromKeychain(key: String) throws {
        // Create keychain query
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        // Delete from keychain
        let status = SecItemDelete(query as CFDictionary)
        
        // Check if successful or item not found (which is fine)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteError(status: status)
        }
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