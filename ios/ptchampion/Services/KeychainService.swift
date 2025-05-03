import Foundation
import Security

// Concrete implementation using the NetworkClient's Keychain accessors
class KeychainService: KeychainServiceProtocol {

    // Shared singleton instance - wrap in dispatch_once pattern
    private static var _shared: KeychainService?
    private static let lock = NSLock()
    
    static var shared: KeychainService {
        lock.lock()
        defer { lock.unlock() }
        
        if _shared == nil {
            _shared = KeychainService()
            print("✅ KeychainService singleton initialized")
        }
        return _shared!
    }

    // Flag to track if we've already printed initialization message
    private static var didLogInitialization = false

    // Define unique identifiers for the keychain item
    private let serviceIdentifier: String
    private let accountIdentifier: String
    
    // Flag to detect if running in simulator
    private let isSimulator: Bool = {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }()

    // Error type for Keychain operations
    enum KeychainError: Error {
        case saveFailed(OSStatus)
        case loadFailed(OSStatus)
        case deleteFailed(OSStatus)
        case dataConversionError
        case unexpectedData
        case itemNotFound
        
        var localizedDescription: String {
            switch self {
            case .saveFailed(let status):
                return "Failed to save to keychain: \(status) - \(SecCopyErrorMessageString(status, nil) as String? ?? "Unknown error")"
            case .loadFailed(let status):
                return "Failed to load from keychain: \(status) - \(SecCopyErrorMessageString(status, nil) as String? ?? "Unknown error")"
            case .deleteFailed(let status):
                return "Failed to delete from keychain: \(status) - \(SecCopyErrorMessageString(status, nil) as String? ?? "Unknown error")"
            case .dataConversionError:
                return "Failed to convert between String and Data"
            case .unexpectedData:
                return "Unexpected data format in keychain"
            case .itemNotFound:
                return "Item not found in keychain"
            }
        }
    }

    // Initialize with unique service and account identifiers
    init(service: String = "com.ptchampion.auth", account: String = "jwtToken") {
        self.serviceIdentifier = service
        self.accountIdentifier = account
        
        // Only log initialization once to avoid log spam
        if !KeychainService.didLogInitialization {
            print("KeychainService initialized. Running in \(isSimulator ? "Simulator" : "Device") mode")
            KeychainService.didLogInitialization = true
        }
    }

    // Additional methods for AuthViewModel compatibility
    func getAccessToken() -> String? {
        do {
            // Use a direct query rather than going through multiple functions
            var query = keychainQuery
            query[kSecReturnData as String] = kCFBooleanTrue
            query[kSecMatchLimit as String] = kSecMatchLimitOne

            var item: CFTypeRef?
            let status = SecItemCopyMatching(query as CFDictionary, &item)

            if status == errSecSuccess, let tokenData = item as? Data,
               let token = String(data: tokenData, encoding: .utf8), 
               !token.isEmpty, token != "null", token != "(null)" {
                return token
            } else if status != errSecItemNotFound {
                print("KeychainService: Token error status: \(status)")
            }
            
            // Token missing or invalid
            print("KeychainService: Token not found or invalid.")
            return nil
        } catch {
            print("KeychainService - Error loading access token: \(error.localizedDescription)")
            return nil
        }
    }
    
    func saveAccessToken(_ token: String) {
        guard !token.isEmpty else {
            print("KeychainService: Attempted to save empty token - ignoring")
            return
        }
        
        do {
            try saveToken(token)
            print("KeychainService: Access token saved successfully")
        } catch {
            print("KeychainService - Error saving access token: \(error.localizedDescription)")
        }
    }
    
    func saveRefreshToken(_ token: String) {
        // Could be implemented similarly to saveToken but with a different key
        print("Saving refresh token - not implemented")
    }
    
    func saveUserID(_ userId: String) {
        // Store user ID in UserDefaults for now as a quick solution
        UserDefaults.standard.set(userId, forKey: "com.ptchampion.userId")
        print("KeychainService: User ID saved to UserDefaults: \(userId)")
    }
    
    func getUserID() -> String? {
        // Get user ID from UserDefaults for now
        let userId = UserDefaults.standard.string(forKey: "com.ptchampion.userId")
        print("KeychainService: Retrieved User ID from UserDefaults: \(String(describing: userId))")
        return userId
    }
    
    func clearAllTokens() {
        do {
            try deleteToken()
            UserDefaults.standard.removeObject(forKey: "com.ptchampion.userId")
            print("KeychainService: All tokens cleared")
        } catch {
            print("KeychainService - Error clearing tokens: \(error.localizedDescription)")
        }
    }

    // Common query dictionary
    private var keychainQuery: [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: accountIdentifier
        ]
        
        // Skip access groups in simulator which doesn't support them
        if !isSimulator {
            // If you use access groups, add them here
            // query[kSecAttrAccessGroup as String] = "your.access.group"
        }
        
        return query
    }

    func saveToken(_ token: String) throws {
        guard let tokenData = token.data(using: .utf8) else {
            throw KeychainError.dataConversionError
        }

        print("KeychainService: Attempting to save token")
        
        // First, check if the item already exists
        if try itemExists() {
            // Update the existing item
            print("KeychainService: Item exists, updating...")
            try updateExistingToken(with: tokenData)
        } else {
            // Create a new item
            print("KeychainService: Item doesn't exist, creating new...")
            try addNewToken(with: tokenData)
        }
        
        print("KeychainService: Token saved successfully.")
    }
    
    private func itemExists() throws -> Bool {
        var query = keychainQuery
        query[kSecReturnData as String] = false
        
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        
        switch status {
        case errSecSuccess:
            return true
        case errSecItemNotFound:
            return false
        default:
            print("KeychainService: Error checking if item exists: \(status)")
            // Don't throw here, just return false to try adding the item
            return false
        }
    }
    
    private func updateExistingToken(with tokenData: Data) throws {
        let query = keychainQuery
        let attributesToUpdate: [String: Any] = [
            kSecValueData as String: tokenData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
        
        guard status == errSecSuccess else {
            print("KeychainService: Failed to update token with status: \(status)")
            throw KeychainError.saveFailed(status)
        }
    }
    
    private func addNewToken(with tokenData: Data) throws {
        var query = keychainQuery
        query[kSecValueData as String] = tokenData
        query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            print("KeychainService: Failed to add token with status: \(status)")
            throw KeychainError.saveFailed(status)
        }
    }

    func loadToken() throws -> String? {
        print("KeychainService: Attempting to load token")
        
        var query = keychainQuery
        query[kSecReturnData as String] = kCFBooleanTrue
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        switch status {
        case errSecSuccess:
            guard let tokenData = item as? Data else {
                print("KeychainService: Retrieved item is not Data")
                throw KeychainError.unexpectedData
            }
            
            guard let token = String(data: tokenData, encoding: .utf8) else {
                print("KeychainService: Could not convert Data to String")
                throw KeychainError.dataConversionError
            }
            
            print("KeychainService: Token loaded successfully.")
            return token
            
        case errSecItemNotFound:
            print("KeychainService: Token not found.")
            return nil // No token found is not an error in this context
            
        default:
            print("KeychainService: Failed to load token with status: \(status)")
            throw KeychainError.loadFailed(status)
        }
    }

    func deleteToken() throws {
        print("KeychainService: Attempting to delete token")
        
        let query = keychainQuery
        let status = SecItemDelete(query as CFDictionary)

        // Only consider it an error if it's not a success and not just "item not found"
        guard status == errSecSuccess || status == errSecItemNotFound else {
            print("KeychainService: Failed to delete token with status: \(status)")
            throw KeychainError.deleteFailed(status)
        }
        
        print("KeychainService: Token deleted (or was not found).")
    }
} 