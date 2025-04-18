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


// MARK: - Network Client
class NetworkClient {

    private let baseURL: URL

    // Read Base URL from Info.plist
    private static func getBaseURL() -> URL {
        guard let plistUrlString = Bundle.main.object(forInfoDictionaryKey: "ApiBaseUrl") as? String, !plistUrlString.isEmpty else {
            print("NetworkClient Warning: ApiBaseUrl not found or empty in Info.plist. Falling back to default localhost.")
            // Fallback URL (consider making this fatal in production or asserting)
            return URL(string: "http://localhost:8080/api/v1")!
        }
        
        guard let url = URL(string: plistUrlString) else {
            fatalError("NetworkClient Fatal: Invalid URL string for ApiBaseUrl in Info.plist: \(plistUrlString)")
        }
        print("NetworkClient: Using Base URL: \(url.absoluteString)")
        return url
    }

    private let urlSession: URLSession
    private let jsonDecoder: JSONDecoder
    private let jsonEncoder: JSONEncoder

    private let keychainAuthTokenKey = "com.ptchampion.authtoken" // Unique key for Keychain item
    private let keychainUserIdKey = "com.ptchampion.userid"    // Unique key for User ID
    private let keychainServiceIdentifier = Bundle.main.bundleIdentifier ?? "com.ptchampion.app" // Service identifier for query

    // Read token from Keychain
    private var authToken: String? {
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

        return String(data: data, encoding: .utf8)
    }

    // Read User ID from Keychain
    var currentUserId: Int? {
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
        // Assuming User ID is stored as a string representation of an Int
        return Int(String(data: data, encoding: .utf8) ?? "")
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
                request.httpBody = try jsonEncoder.encode(body)
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
            return decodedData
        } catch {
            print("NetworkClient: Failed to decode response for \(url): \(error)")
            // Provide more context on decoding errors
            if let decodingError = error as? DecodingError {
                 print("NetworkClient: Decoding error details: \(decodingError)")
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
    func saveLoginCredentials(token: String, userId: Int) {
        // Save Token
        saveKeychainItem(key: keychainAuthTokenKey, value: token)
        // Save User ID (as String)
        saveKeychainItem(key: keychainUserIdKey, value: String(userId))
    }
    
    // Clear token AND User ID from Keychain
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
        guard let path = url.pathComponents.last else {
            return true // Assume auth needed if path is weird
        }
        // Check if the path suffix matches any in the noAuthPaths set
        return !noAuthPaths.contains { path.hasSuffix($0) }
    }
}

// Helper for requests that expect no response body (e.g., 204 No Content)
struct EmptyResponse: Decodable {} 