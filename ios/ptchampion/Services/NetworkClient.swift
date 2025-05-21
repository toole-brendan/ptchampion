import Foundation
import Security // Import Security framework

// MARK: - API Error Enum (Shared)
// Consider moving to a dedicated Errors.swift file if more shared errors arise.
enum APIError: Error, LocalizedError {
    case invalidURL
    case requestFailed(statusCode: Int, message: String?)
    case invalidResponse
    case decodingError(Error)
    case encodingError(Error)
    case authenticationError(String? = "Authentication token is missing or invalid.")
    case underlying(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL encountered."
        case .requestFailed(let code, let message):
            return "Request failed with status code: \(code). \(message ?? "")"
        case .invalidResponse: return "Received an invalid response from the server."
        case .decodingError(let error): return "Failed to decode response: \(error.localizedDescription)"
        case .encodingError(let error): return "Failed to encode request: \(error.localizedDescription)"
        case .authenticationError(let message): return message
        case .underlying(let error): return error.localizedDescription
        }
    }
}

// Structure to decode potential error messages from the API
struct APIErrorResponse: Decodable, Error {
    let message: String
}

// Helper for requests that expect no response body (e.g., 204 No Content)
struct NetworkClientEmptyResponse: Decodable {}

// MARK: - Network Client
class NetworkClient {

    private let baseURL: URL

    // Read Base URL from Info.plist
    private static func getBaseURL() -> URL {
        // Use a direct hardcoded URL instead of trying to read from Info.plist
        // This avoids the repeated warnings when the key is missing from the built Info.plist
        return URL(string: "https://ptchampion-api-westus.azurewebsites.net/api/v1")!
        
        /* Original Info.plist loading code - commented out
        // Debug: Print bundle path and all keys
        let bundle = Bundle.main
        print("NetworkClient Debug: Bundle path = \(bundle.bundlePath)")
        
        if let infoPlistPath = bundle.path(forResource: "Info", ofType: "plist") {
            print("NetworkClient Debug: Info.plist path = \(infoPlistPath)")
            
            // Try to load the plist file directly
            if let plistDict = NSDictionary(contentsOfFile: infoPlistPath) as? [String: Any],
               let apiBaseUrl = plistDict["ApiBaseUrl"] as? String,
               !apiBaseUrl.isEmpty {
                print("NetworkClient: Loaded ApiBaseUrl directly from plist file: \(apiBaseUrl)")
                guard let url = URL(string: apiBaseUrl) else {
                    fatalError("NetworkClient Fatal: Invalid URL string loaded directly from Info.plist: \(apiBaseUrl)")
                }
                return url
            }
        } else {
            print("NetworkClient Debug: Info.plist not found in bundle path")
        }
        
        // Print all keys in the main bundle's info dictionary
        if let infoDict = bundle.infoDictionary {
            print("NetworkClient Debug: All Info.plist keys: \(infoDict.keys.sorted())")
        } else {
            print("NetworkClient Debug: Could not access Info.plist dictionary")
        }
        
        guard let plistUrlString = Bundle.main.object(forInfoDictionaryKey: "ApiBaseUrl") as? String, !plistUrlString.isEmpty else {
            print("NetworkClient Warning: ApiBaseUrl not found or empty in Info.plist. Falling back to default Vercel API URL.")
            // Use the same URL that's in Info.plist as fallback
            return URL(string: "https://ptchampion-api.vercel.app/api/v1")!
        }
        
        guard let url = URL(string: plistUrlString) else {
            fatalError("NetworkClient Fatal: Invalid URL string for ApiBaseUrl in Info.plist: \(plistUrlString)")
        }
        print("NetworkClient: Using Base URL: \(url.absoluteString)")
        return url
        */
    }

    private let urlSession: URLSession
    private let jsonDecoder: JSONDecoder
    private let jsonEncoder: JSONEncoder

    private let keychainAuthTokenKey = "com.ptchampion.authtoken" // Unique key for Keychain item
    private let keychainUserIdKey = "com.ptchampion.userid"    // Unique key for User ID
    private let keychainServiceIdentifier = Bundle.main.bundleIdentifier ?? "com.ptchampion.app" // Service identifier for query
    
    // Static shared instance for notifications
    static let shared = NetworkClient()
    
    // Token can be set directly for immediate use
    private var cachedAuthToken: String?
    
    // Read token from Keychain
    var authToken: String? {
        // First check if we have a cached token
        if let cachedToken = cachedAuthToken {
            return cachedToken
        }
        
        // Otherwise, check the keychain
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainServiceIdentifier,
            kSecAttrAccount as String: keychainAuthTokenKey,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: kCFBooleanTrue!
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status == errSecSuccess, let data = item as? Data else {
            if status != errSecItemNotFound {
                 print("NetworkClient: Error reading token from Keychain - Status: \(status)")
            }
            return nil
        }

        // Cache the token after reading it
        let token = String(data: data, encoding: .utf8)
        cachedAuthToken = token
        return token
    }
    
    // Public method to update the cached token
    func updateAuthToken(_ token: String?) {
        cachedAuthToken = token
        print("NetworkClient: Auth token updated in cache")
    }

    // Read User ID from Keychain
    var currentUserId: String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainServiceIdentifier,
            kSecAttrAccount as String: keychainUserIdKey,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: kCFBooleanTrue!
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status == errSecSuccess, let data = item as? Data else {
            if status != errSecItemNotFound {
                 print("NetworkClient: Error reading User ID from Keychain - Status: \(status)")
            }
            return nil
        }
        // User ID is stored as a string
        return String(data: data, encoding: .utf8)
    }

    // Define paths that should NOT have the auth token added automatically
    private let noAuthPaths: Set<String> = [
        "/auth/login",
        "/auth/register"
    ]

    init(urlSession: URLSession = .shared) {
        self.baseURL = NetworkClient.getBaseURL() // Get base URL on init
        self.urlSession = urlSession

        self.jsonDecoder = JSONDecoder()
        self.jsonDecoder.dateDecodingStrategy = .iso8601 // Match schema expectation

        self.jsonEncoder = JSONEncoder()
        self.jsonEncoder.dateEncodingStrategy = .iso8601 // Match schema expectation
        // self.jsonEncoder.keyEncodingStrategy = .convertToSnakeCase // Uncomment if API expects snake_case
    }

    // MARK: - Request Execution

    /// Performs a network request with automatic token injection and JSON decoding/encoding.
    /// - Parameters:
    ///   - endpointPath: The specific API endpoint path (e.g., "/users/me").
    ///   - method: The HTTP method (e.g., "GET", "POST").
    ///   - queryParams: Optional dictionary of query parameters to append to the URL.
    ///   - body: An optional Encodable object to be sent as the request body.
    /// - Returns: The decoded response object.
    func performRequest<Response: Decodable>(
        endpointPath: String,
        method: String,
        queryParams: [String: String]? = nil,
        body: (any Encodable)? = nil
    ) async throws -> Response {
        
        guard var urlComponents = URLComponents(url: baseURL.appendingPathComponent(endpointPath), resolvingAgainstBaseURL: false) else {
            throw APIError.invalidURL
        }
        
        // Append query parameters if provided
        if let queryParams = queryParams, !queryParams.isEmpty {
            urlComponents.queryItems = queryParams.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        
        guard let url = urlComponents.url else {
             throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        // Automatically add auth token if required and available
        if requiresAuthentication(path: endpointPath) {
            guard let token = authToken else {
                print("NetworkClient: Error - Auth token required for \(endpointPath) but not found.")
                throw APIError.authenticationError()
            }
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Encode body if provided
        if let body = body {
            do {
                let bodyData = try jsonEncoder.encode(body)
                request.httpBody = bodyData
                if let bodyString = String(data: bodyData, encoding: .utf8) {
                    print("NetworkClient: Request body: \(bodyString)")
                }
            } catch {
                print("NetworkClient: Failed to encode request body: \(error)")
                throw APIError.encodingError(error)
            }
        }

        print("NetworkClient: Performing \(method) request to \(url)")
        let (data, response) = try await urlSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        print("NetworkClient: Received status code \(httpResponse.statusCode) for \(url)")
        
        // Print response headers for debugging
        print("NetworkClient: Response headers: \(httpResponse.allHeaderFields)")
        
        // DEBUG: Print response body as string
        if let responseString = String(data: data, encoding: .utf8) {
            print("NetworkClient: Response body: \(responseString)")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            // Try to decode a specific error message from the response body
            let errorMessage = try? jsonDecoder.decode(APIErrorResponse.self, from: data).message
            print("NetworkClient: Request failed with status \(httpResponse.statusCode). Error: \(errorMessage ?? "No specific message")")
            throw APIError.requestFailed(statusCode: httpResponse.statusCode, message: errorMessage)
        }

        // Handle cases where no response body is expected (e.g., 204 No Content)
        // If Response is `Void.Type` or an empty struct, we can return successfully here.
        // This check requires a bit more nuance depending on how you define "no content" response types.
        // For now, we assume Decodable handles empty data if the type expects it.

        do {
            let decodedData = try jsonDecoder.decode(Response.self, from: data)
            print("NetworkClient: Successfully decoded response of type \(Response.self)")
            return decodedData
        } catch {
            print("NetworkClient: Failed to decode response for \(url): \(error)")
            // Provide more context on decoding errors
            if let decodingError = error as? DecodingError {
                 print("NetworkClient: Decoding error details: \(decodingError)")
                 switch decodingError {
                 case .keyNotFound(let key, let context):
                     print("NetworkClient: Missing key: \(key.stringValue) in \(context.codingPath)")
                 case .typeMismatch(let type, let context):
                     print("NetworkClient: Type mismatch: expected \(type) at \(context.codingPath)")
                 case .valueNotFound(let type, let context):
                     print("NetworkClient: Value not found: expected \(type) at \(context.codingPath)")
                 case .dataCorrupted(let context):
                     print("NetworkClient: Data corrupted at \(context.codingPath)")
                 @unknown default:
                     print("NetworkClient: Unknown decoding error")
                 }
            }
            throw APIError.decodingError(error)
        }
    }
    
    /// Performs a request where no response body is expected on success (e.g., 200 OK, 204 No Content).
    /// - Parameters:
    ///   - endpointPath: The specific API endpoint path.
    ///   - method: The HTTP method.
    ///   - queryParams: Optional dictionary of query parameters to append to the URL.
    ///   - body: An optional Encodable object to be sent as the request body.
    func performRequestNoContent(
        endpointPath: String,
        method: String,
        queryParams: [String: String]? = nil,
        body: (any Encodable)? = nil
    ) async throws -> Void {
        
        guard var urlComponents = URLComponents(url: baseURL.appendingPathComponent(endpointPath), resolvingAgainstBaseURL: false) else {
            throw APIError.invalidURL
        }
        
        // Append query parameters if provided
        if let queryParams = queryParams, !queryParams.isEmpty {
            urlComponents.queryItems = queryParams.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        
        guard let url = urlComponents.url else {
             throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        // Automatically add auth token if required and available
        if requiresAuthentication(path: endpointPath) {
            guard let token = authToken else {
                print("NetworkClient: Error - Auth token required for \(endpointPath) but not found.")
                throw APIError.authenticationError()
            }
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Encode body if provided
        if let body = body {
             do {
                request.httpBody = try jsonEncoder.encode(body)
            } catch {
                print("NetworkClient: Failed to encode request body: \(error)")
                throw APIError.encodingError(error)
            }
        }

        print("NetworkClient: Performing \(method) request (expecting no content) to \(url)")
        let (data, response) = try await urlSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        print("NetworkClient: Received status code \(httpResponse.statusCode) for \(url)")
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = try? jsonDecoder.decode(APIErrorResponse.self, from: data).message
            print("NetworkClient: Request failed with status \(httpResponse.statusCode). Error: \(errorMessage ?? "No specific message")")
            throw APIError.requestFailed(statusCode: httpResponse.statusCode, message: errorMessage)
        }
        
        // Success, no need to decode body
    }

    // MARK: - Helpers

    private func requiresAuthentication(path: String) -> Bool {
        // Check if the request path ends with one of the paths that DON'T require auth
        return !noAuthPaths.contains { path.hasSuffix($0) }
    }
    
    // Save token AND User ID to Keychain
    // Update this to accept AuthResponse or separate token/userId
    @available(*, deprecated, message: "Use KeychainService.shared instead to ensure consistent token storage")
    func saveLoginCredentials(token: String, userId: String) {
        // Save Token
        saveKeychainItem(key: keychainAuthTokenKey, value: token)
        // Save User ID
        saveKeychainItem(key: keychainUserIdKey, value: userId)
    }
    
    // Clear token AND User ID from Keychain
    @available(*, deprecated, message: "Use KeychainService.shared.clearAllTokens() instead to ensure consistent token cleanup")
    func clearLoginCredentials() {
         deleteKeychainItem(key: keychainAuthTokenKey)
         deleteKeychainItem(key: keychainUserIdKey)
    }
    
    // Private helper to save/update generic keychain item
    private func saveKeychainItem(key: String, value: String) {
        guard let valueData = value.data(using: .utf8) else {
            print("NetworkClient: Error converting value to data for key \(key).")
            return
        }
        
        // Delete existing first
        deleteKeychainItem(key: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainServiceIdentifier,
            kSecAttrAccount as String: key,
            kSecValueData as String: valueData,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        if status == errSecSuccess {
            print("NetworkClient: Item for key \(key) saved to Keychain.")
        } else {
            print("NetworkClient: Error saving item for key \(key) - Status: \(status)")
        }
    }

    // Private helper to delete generic keychain item
    private func deleteKeychainItem(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainServiceIdentifier,
            kSecAttrAccount as String: key
        ]
        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            print("NetworkClient: Error deleting item for key \(key) - Status: \(status)")
        }
    }
    
    // Keep old methods for compatibility or remove if AuthService is updated
    @available(*, deprecated, message: "Use saveLoginCredentials instead")
    func saveToken(_ token: String) {
        saveKeychainItem(key: keychainAuthTokenKey, value: token)
    }
    @available(*, deprecated, message: "Use clearLoginCredentials instead")
    func clearToken() {
        deleteKeychainItem(key: keychainAuthTokenKey)
    }

    private func shouldAddAuthHeader(for url: URL) -> Bool {
        guard let path = url.path.components(separatedBy: "/").last else {
            return true // Assume auth needed if path is weird
        }
        // Check if the path suffix matches any in the noAuthPaths set
        return !noAuthPaths.contains { path.hasSuffix($0) }
    }
}

// No need to redeclare EmptyResponse as we're importing it from NetworkService
// struct EmptyResponse: Decodable {} 