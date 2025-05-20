import Foundation
import Combine

/// Unified Network Service that provides similar behavior to the web apiClient
/// Handles token management, caching, retries, and error handling
class UnifiedNetworkService {
    // Singleton instance
    static let shared = UnifiedNetworkService()
    
    // URL session with caching configuration
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        // Cache settings similar to web configuration
        config.requestCachePolicy = .useProtocolCachePolicy
        config.urlCache = URLCache(memoryCapacity: 20 * 1024 * 1024, // 20MB memory cache
                                  diskCapacity: 100 * 1024 * 1024,   // 100MB disk cache
                                  diskPath: "unified_network_cache")
        return URLSession(configuration: config)
    }()
    
    // Base URL for API endpoints
    private let baseURL: String
    
    // Service for secure token storage
    private let keychainService: KeychainServiceProtocol
    
    // Token refresh handling
    private var isRefreshing = false
    private var refreshSubscribers: [((Bool) -> Void)] = []
    
    // Private error cases specific to this implementation
    private enum ServiceError: Error {
        case needsRetryWithNewToken
        case maxRetriesExceeded
    }
    
    init(baseURL: String = "https://ptchampion-api-westus.azurewebsites.net/api/v1",
         keychainService: KeychainServiceProtocol = KeychainService()) {
        self.baseURL = baseURL
        self.keychainService = keychainService
    }
    
    // MARK: - API Request Methods
    
    /// Generic API request method similar to web apiRequest
    /// - Parameters:
    ///   - endpoint: API endpoint path
    ///   - method: HTTP method
    ///   - body: Optional request body
    ///   - requiresAuth: Whether authentication is required
    /// - Returns: Response data
    func request<T: Decodable>(
        _ endpoint: String,
        method: HTTPMethod,
        body: Encodable? = nil,
        requiresAuth: Bool = false,
        retries: Int = 1
    ) async throws -> T {
        // Construct the full URL
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw NetworkError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.rawValue
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Add token if authentication is required
        if requiresAuth {
            guard let token = try await getAuthToken() else {
                throw NetworkError.unauthorized
            }
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Encode body if provided
        if let body = body {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            urlRequest.httpBody = try encoder.encode(body)
        }
        
        // Log request details (similar to web logging)
        print("🌐 \(method.rawValue) \(endpoint)")
        
        // Perform the request with retry logic
        return try await withRetry(retries: retries) {
            do {
                let (data, response) = try await self.session.data(for: urlRequest)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.invalidResponse
                }
                
                // Handle response based on status code
                switch httpResponse.statusCode {
                case 200...299:
                    // Success
                    if T.self == EmptyResponse.self {
                        // For endpoints that don't return data
                        return EmptyResponse() as! T
                    } else {
                        let decoder = JSONDecoder()
                        decoder.dateDecodingStrategy = .iso8601
                        return try decoder.decode(T.self, from: data)
                    }
                    
                case 401:
                    // Handle unauthorized - attempt token refresh
                    if requiresAuth {
                        if await self.refreshTokenIfNeeded() {
                            // Retry with new token
                            throw ServiceError.needsRetryWithNewToken
                        } else {
                            throw NetworkError.server(status: 401, detail: "Unauthorized")
                        }
                    }
                    throw NetworkError.server(status: 401, detail: "Unauthorized")
                    
                case 400...499:
                    // Client error
                    let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
                    throw NetworkError.server(status: httpResponse.statusCode, 
                                            detail: errorResponse?.message ?? "Client error")
                    
                case 500...599:
                    // Server error
                    throw NetworkError.server(status: httpResponse.statusCode, detail: "Server error")
                    
                default:
                    throw NetworkError.server(status: httpResponse.statusCode, detail: "Unexpected status code")
                }
            } catch ServiceError.needsRetryWithNewToken {
                // Special case to trigger retry with new token
                throw ServiceError.needsRetryWithNewToken
            } catch {
                throw error
            }
        }
    }
    
    /// Helper method for retrying requests
    private func withRetry<T>(retries: Int, task: () async throws -> T) async throws -> T {
        var attempts = 0
        var lastError: Error?
        
        while attempts <= retries {
            do {
                return try await task()
            } catch ServiceError.needsRetryWithNewToken {
                // This is a special case - we'll retry immediately with the new token
                attempts += 1
                lastError = NetworkError.server(status: 401, detail: "Unauthorized")
                
                // Small delay before retry
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            } catch {
                attempts += 1
                lastError = error
                
                if attempts <= retries {
                    // Exponential backoff
                    let delay = UInt64(min(pow(2.0, Double(attempts)) * 1_000_000_000, 30_000_000_000))
                    try? await Task.sleep(nanoseconds: delay)
                }
            }
        }
        
        throw lastError ?? ServiceError.maxRetriesExceeded
    }
    
    // MARK: - Authentication Methods
    
    /// Get the current auth token or throw if not available
    private func getAuthToken() async throws -> String? {
        return try keychainService.getToken()
    }
    
    /// Refresh token if needed
    private func refreshTokenIfNeeded() async -> Bool {
        // Prevent multiple simultaneous refresh attempts
        guard !isRefreshing else {
            // Wait for the current refresh to complete
            return await withCheckedContinuation { continuation in
                // forward the value the publisher will pass later
                self.refreshSubscribers.append { success in
                    continuation.resume(returning: success)
                }
            }
        }
        
        isRefreshing = true
        defer {
            isRefreshing = false
            // Notify subscribers of result
            let success = true // Assume success for now
            self.refreshSubscribers.forEach { $0(success) }
            self.refreshSubscribers.removeAll()
        }
        
        // Get refresh token from keychain
        guard let refreshToken = try? keychainService.getRefreshToken() else {
            return false
        }
        
        // Create refresh token URL request
        guard let url = URL(string: "\(baseURL)/auth/refresh") else {
            return false
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Create refresh token request body
        let refreshBody = ["refresh_token": refreshToken]
        request.httpBody = try? JSONEncoder().encode(refreshBody)
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, 
                  (200...299).contains(httpResponse.statusCode) else {
                return false
            }
            
            // Decode the response
            guard let tokenResponse = try? JSONDecoder().decode(TokenResponse.self, from: data) else {
                return false
            }
            
            // Store the new tokens
            try? keychainService.saveToken(tokenResponse.accessToken)
            try? keychainService.saveRefreshToken(tokenResponse.refreshToken)
            
            return true
        } catch {
            print("Error refreshing token: \(error)")
            return false
        }
    }
    
    // MARK: - Authentication Methods
    
    func login(email: String, password: String) async throws -> LoginResponse {
        let loginData = LoginRequest(email: email, password: password)
        let response: LoginResponse = try await request("/auth/login", method: .post, body: loginData)
        
        // Store tokens
        try keychainService.saveToken(response.token)
        if let refreshToken = response.refreshToken {
            try keychainService.saveRefreshToken(refreshToken)
        }
        
        return response
    }
    
    func register(userData: RegisterUserRequest) async throws -> UserResponse {
        return try await request("/auth/register", method: .post, body: userData)
    }
    
    func logout() {
        // Clear tokens
        try? keychainService.deleteToken()
        try? keychainService.deleteRefreshToken()
    }
    
    // MARK: - Health Check
    
    func checkServerHealth() async -> ServerHealthStatus {
        let startTime = Date()
        
        do {
            let _: EmptyResponse = try await request("/health", method: .get)
            return ServerHealthStatus(status: "ok")
        } catch {
            return ServerHealthStatus(status: "error")
        }
    }
}

// MARK: - Helper Types

// UnifiedNetworkError has been replaced by the consolidated NetworkError in CommonNetworkTypes.swift

struct TokenResponse: Decodable {
    let accessToken: String
    let refreshToken: String
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
    }
}

// MARK: - Request/Response Models

// This LoginRequest is specific to UnifiedNetworkService and doesn't conflict with AuthLoginRequest
struct LoginRequest: Encodable {
    let email: String
    let password: String
}

struct LoginResponse: Decodable {
    let token: String
    let refreshToken: String?
    let user: UserResponse?
    
    enum CodingKeys: String, CodingKey {
        case token = "access_token"
        case refreshToken = "refresh_token"
        case user
    }
}

struct RegisterUserRequest: Encodable {
    let username: String
    let password: String
    let email: String?
    let displayName: String?
    
    enum CodingKeys: String, CodingKey {
        case username
        case password
        case email
        case displayName = "display_name"
    }
}

struct UserResponse: Decodable {
    let id: String
    let username: String
    let email: String?
    let displayName: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case email
        case displayName = "display_name"
    }
}

// Removed duplicate type definitions for EmptyResponse, ErrorResponse, and ServerHealthStatus
// These are now defined only in CommonNetworkTypes.swift