import Foundation
import Security

// Manages secure storage and retrieval of authentication tokens using Keychain.
class AuthTokenManager {
    static let shared = AuthTokenManager()

    // Define unique identifiers for the Keychain service and account.
    // Using Bundle ID is a common practice for the service.
    private let service = Bundle.main.bundleIdentifier ?? "com.ptchampion.keychain"
    private let tokenAccount = "userAuthToken"
    private let expiryAccount = "userAuthTokenExpiry"
    private let userIdAccount = "userId"

    private init() {}

    // MARK: - Token Operations

    func saveToken(token: String, expiresIn: String?) {
        save(data: token, for: tokenAccount)
        if let expiry = expiresIn {
            // Convert expiresIn string (assuming ISO 8601 or similar) to Data or store as String
            // For simplicity, storing as String for now. Consider Date conversion for validation.
             save(data: expiry, for: expiryAccount)
        }
        // Clear old expiry if new token doesn't have one
        else {
            delete(for: expiryAccount)
        }
        print("AuthTokenManager: Token saved to Keychain.")
    }

    func getToken() -> String? {
        return read(for: tokenAccount)
    }

    func getTokenExpiry() -> String? {
        return read(for: expiryAccount)
    }

    func clearToken() {
        delete(for: tokenAccount)
        delete(for: expiryAccount)
        delete(for: userIdAccount) // Also clear associated user ID
        print("AuthTokenManager: Token and related data cleared from Keychain.")
    }

    // MARK: - User ID (Optional)

    // Optionally store User ID securely if needed frequently without full User object
    func saveUserID(_ userId: Int) {
        save(data: String(userId), for: userIdAccount)
    }

    func getUserID() -> Int? {
        guard let userIdString = read(for: userIdAccount) else { return nil }
        return Int(userIdString)
    }

    // MARK: - Keychain Helper Methods

    private func save(data: String, for account: String) {
        guard let data = data.data(using: .utf8) else {
            print("AuthTokenManager: Error converting string to data for account \(account).")
            return
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]

        // Check if item exists to decide between SecItemAdd and SecItemUpdate
        let status = SecItemCopyMatching(query as CFDictionary, nil)

        var operationStatus: OSStatus

        if status == errSecSuccess {
            // Item exists, update it
            operationStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
            if operationStatus != errSecSuccess {
                logKeychainError(status: operationStatus, operation: "update", account: account)
            }
        } else if status == errSecItemNotFound {
            // Item does not exist, add it
            var mergedQuery = query
            mergedQuery[kSecValueData as String] = data
            // Optional: Set accessibility level (e.g., kSecAttrAccessibleWhenUnlockedThisDeviceOnly)
            // mergedQuery[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            operationStatus = SecItemAdd(mergedQuery as CFDictionary, nil)
            if operationStatus != errSecSuccess {
                 logKeychainError(status: operationStatus, operation: "add", account: account)
            }
        } else {
            // Some other error occurred during lookup
            logKeychainError(status: status, operation: "lookup", account: account)
            operationStatus = status // Report the lookup error
        }

        if operationStatus == errSecSuccess {
           // print("AuthTokenManager: Successfully saved data for account \(account).")
        } else {
            // Error already logged by logKeychainError
        }
    }

    private func read(for account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        if status == errSecSuccess {
            guard let data = dataTypeRef as? Data,
                  let string = String(data: data, encoding: .utf8) else {
                 print("AuthTokenManager: Error converting Keychain data to string for account \(account).")
                return nil
            }
            return string
        } else if status == errSecItemNotFound {
            // Item not found is not necessarily an error, just means no token is stored
            // print("AuthTokenManager: No data found in Keychain for account \(account).")
            return nil
        } else {
            // Other error during read
            logKeychainError(status: status, operation: "read", account: account)
            return nil
        }
    }

    private func delete(for account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let status = SecItemDelete(query as CFDictionary)

        if status == errSecSuccess {
            // print("AuthTokenManager: Successfully deleted data for account \(account).")
        } else if status == errSecItemNotFound {
             // print("AuthTokenManager: No data found to delete in Keychain for account \(account).")
        } else {
            logKeychainError(status: status, operation: "delete", account: account)
        }
    }

    // MARK: - Error Logging

    private func logKeychainError(status: OSStatus, operation: String, account: String) {
        var errorMessage: String = "Unknown Keychain error"
        if #available(iOS 11.3, *), let cfError = SecCopyErrorMessageString(status, nil) {
            errorMessage = cfError as String
        } else {
            // Fallback for older iOS versions or if specific message isn't available
             switch status {
                 case errSecUnimplemented: errorMessage = "Function or operation not implemented."
                 case errSecParam: errorMessage = "One or more parameters passed to a function were not valid."
                 case errSecAllocate: errorMessage = "Failed to allocate memory."
                 case errSecNotAvailable: errorMessage = "No keychain is available. You may need to restart your computer."
                 case errSecDuplicateItem: errorMessage = "The specified item already exists in the keychain."
                 case errSecItemNotFound: errorMessage = "The specified item could not be found in the keychain."
                 case errSecInteractionNotAllowed: errorMessage = "User interaction is not allowed."
                 case errSecDecode: errorMessage = "Unable to decode the provided data."
                 case errSecAuthFailed: errorMessage = "The user name or passphrase you entered is not correct."
                 default: errorMessage = "Keychain Error Code: \(status)"
             }
        }
         print("AuthTokenManager: Keychain \(operation) failed for account '\(account)'. Status: \(status). Message: \(errorMessage)")
    }

} 