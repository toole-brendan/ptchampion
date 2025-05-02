import Foundation
import Security

// Concrete implementation using the NetworkClient's Keychain accessors
class KeychainService: KeychainServiceProtocol {

    // Shared singleton instance
    static let shared = KeychainService()

    // Share a single NetworkClient instance or inject it
    // Using a shared instance for simplicity here
    private let networkClient: NetworkClient

    // Define unique identifiers for the keychain item
    private let serviceIdentifier: String
    private let accountIdentifier: String

    // Error type for Keychain operations
    enum KeychainError: Error {
        case saveFailed(OSStatus)
        case loadFailed(OSStatus)
        case deleteFailed(OSStatus)
        case dataConversionError
        case unexpectedData
    }

    // Initialize with unique service and account identifiers
    init(service: String = "com.ptchampion.auth", account: String = "jwtToken", networkClient: NetworkClient = NetworkClient()) {
        self.serviceIdentifier = service
        self.accountIdentifier = account
        self.networkClient = networkClient
    }

    // Additional methods for AuthViewModel compatibility
    func getAccessToken() -> String? {
        do {
            return try loadToken()
        } catch {
            print("Error loading access token: \(error)")
            return nil
        }
    }
    
    func saveAccessToken(_ token: String) {
        do {
            try saveToken(token)
        } catch {
            print("Error saving access token: \(error)")
        }
    }
    
    func saveRefreshToken(_ token: String) {
        // Could be implemented similarly to saveToken but with a different key
        print("Saving refresh token - not implemented")
    }
    
    func saveUserId(_ userId: String) {
        // Store user ID in UserDefaults for now as a quick solution
        UserDefaults.standard.set(userId, forKey: "com.ptchampion.userId")
    }
    
    func getUserId() -> String? {
        // Get user ID from UserDefaults for now
        return UserDefaults.standard.string(forKey: "com.ptchampion.userId")
    }
    
    func clearAllTokens() {
        do {
            try deleteToken()
            UserDefaults.standard.removeObject(forKey: "com.ptchampion.userId")
        } catch {
            print("Error clearing tokens: \(error)")
        }
    }

    // Common query dictionary
    private var keychainQuery: [String: Any] {
        return [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: accountIdentifier
        ]
    }

    func saveToken(_ token: String) throws {
        guard let tokenData = token.data(using: .utf8) else {
            throw KeychainError.dataConversionError
        }

        var query = keychainQuery
        query[kSecValueData as String] = tokenData
        // kSecAttrAccessibleWhenUnlockedThisDeviceOnly is a good default level of security
        query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly

        // Delete existing item before saving, to ensure update works
        SecItemDelete(query as CFDictionary)

        // Add the new item
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
        print("KeychainService: Token saved successfully.")
    }

    func loadToken() throws -> String? {
        var query = keychainQuery
        query[kSecReturnData as String] = kCFBooleanTrue
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        switch status {
        case errSecSuccess:
            guard let tokenData = item as? Data else {
                throw KeychainError.unexpectedData
            }
            guard let token = String(data: tokenData, encoding: .utf8) else {
                throw KeychainError.dataConversionError
            }
            print("KeychainService: Token loaded successfully.")
            return token
        case errSecItemNotFound:
            print("KeychainService: Token not found.")
            return nil // No token found is not an error in this context
        default:
            throw KeychainError.loadFailed(status)
        }
    }

    func deleteToken() throws {
        let query = keychainQuery
        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
        print("KeychainService: Token deleted (or was not found).")
    }
} 