import Foundation
import Combine
import Security // For Keychain access (conceptual)

@MainActor // Ensure UI updates happen on the main thread
class AuthManager: ObservableObject {
    @Published private(set) var currentUser: User? = nil
    @Published private(set) var isAuthenticated: Bool = false
    @Published var authError: String? = nil
    @Published var isLoading: Bool = false

    private let authRepository: AuthRepositoryProtocol
    private let keychainService: KeychainServiceProtocol // Protocol for Keychain interaction

    // Key for storing token in Keychain
    private let authTokenKey = "com.ptchampion.authtoken"

    init(authRepository: AuthRepositoryProtocol = AuthRepository(), 
         keychainService: KeychainServiceProtocol = KeychainService()) { // Use default implementations
        self.authRepository = authRepository
        self.keychainService = keychainService
        loadInitialAuthState()
    }

    // Load token from keychain on startup
    private func loadInitialAuthState() {
        if let token = keychainService.loadToken(forKey: authTokenKey) {
            // TODO: Validate token (e.g., check expiry, maybe fetch user profile)
            // For now, assume any stored token is valid
            APIClient.shared.setAuthToken(token) // Configure APIClient
            // Fetch user profile based on token or store user details in keychain too
            // self.currentUser = fetchUserProfile() 
            self.isAuthenticated = true
            print("AuthManager: Found existing token, user authenticated.")
        } else {
            print("AuthManager: No token found, user not authenticated.")
            self.isAuthenticated = false
        }
    }

    func login(credentials: LoginRequest) async {
        isLoading = true
        authError = nil
        do {
            let response = try await authRepository.login(credentials: credentials)
            keychainService.saveToken(response.token, forKey: authTokenKey)
            currentUser = response.user
            isAuthenticated = true
            print("AuthManager: Login successful for \(response.user.username)")
        } catch let error as NetworkError {
            print("AuthManager: Login failed - NetworkError: \(error.localizedDescription)")
            authError = error.localizedDescription
            isAuthenticated = false
        } catch {
            print("AuthManager: Login failed - Unknown Error: \(error)")
            authError = "An unexpected error occurred during login."
            isAuthenticated = false
        }
        isLoading = false
    }

    func register(details: RegisterRequest) async {
        isLoading = true
        authError = nil
        do {
            let response = try await authRepository.register(details: details)
            keychainService.saveToken(response.token, forKey: authTokenKey)
            currentUser = response.user
            isAuthenticated = true
            print("AuthManager: Registration successful for \(response.user.username)")
        } catch let error as NetworkError {
            print("AuthManager: Registration failed - NetworkError: \(error.localizedDescription)")
            authError = error.localizedDescription
            isAuthenticated = false
        } catch {
            print("AuthManager: Registration failed - Unknown Error: \(error)")
            authError = "An unexpected error occurred during registration."
            isAuthenticated = false
        }
        isLoading = false
    }

    func logout() {
        // Call repository logout to clear token in APIClient
        // Type cast if needed, or add logout to protocol
        (authRepository as? AuthRepository)?.logout() 
        
        keychainService.deleteToken(forKey: authTokenKey)
        currentUser = nil
        isAuthenticated = false
        print("AuthManager: User logged out.")
    }
}

// MARK: - Keychain Service Protocol and Mock Implementation

protocol KeychainServiceProtocol {
    func saveToken(_ token: String, forKey key: String) -> Bool
    func loadToken(forKey key: String) -> String?
    func deleteToken(forKey key: String) -> Bool
}

// Basic Keychain interaction (Replace with a robust library or implementation)
class KeychainService: KeychainServiceProtocol {
    func saveToken(_ token: String, forKey key: String) -> Bool {
        guard let data = token.data(using: .utf8) else { return false }
        
        // Delete existing item first
        deleteToken(forKey: key)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly // Accessibility
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            print("Keychain Error: Failed to save token. Status: \(status)")
            return false
        }
        print("Keychain: Token saved for key \(key)")
        return true
    }

    func loadToken(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        guard status == errSecSuccess, let retrievedData = dataTypeRef as? Data else {
             // errSecItemNotFound is expected if no token exists
             if status != errSecItemNotFound {
                 print("Keychain Error: Failed to load token. Status: \(status)")
             }
            return nil
        }
        
        print("Keychain: Token loaded for key \(key)")
        return String(data: retrievedData, encoding: .utf8)
    }

    func deleteToken(forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
             print("Keychain Error: Failed to delete token. Status: \(status)")
            return false
        }
        if status == errSecSuccess { print("Keychain: Token deleted for key \(key)") }
        return true
    }
} 