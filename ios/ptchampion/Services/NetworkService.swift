import Foundation
import Combine

/// A service for handling network requests with caching and retry capabilities
class NetworkService {
    // Singleton instance
    static let shared = NetworkService()
    
    // URL Session configuration
    private let session: URLSession
    
    // Base URL for API endpoints
    private let baseURL: String
    
    // Optional keychain service for token management
    private let keychainService: KeychainServiceProtocol?
    
    /// Initialize NetworkService with custom configuration
    /// - Parameters:
    ///   - baseURL: Base URL for API endpoints
    ///   - keychainService: Optional keychain service for token management
    ///   - sessionConfiguration: Custom URLSession configuration
    init(baseURL: String = "https://api.ptchampion.com/v1",
         keychainService: KeychainServiceProtocol? = KeychainService(),
         sessionConfiguration: URLSessionConfiguration = .default) {
        self.baseURL = baseURL
        self.keychainService = keychainService
        
        // Configure session with caching
        let config = sessionConfiguration
        config.requestCachePolicy = .useProtocolCachePolicy
        config.urlCache = URLCache(memoryCapacity: 20 * 1024 * 1024, // 20MB memory cache
                                   diskCapacity: 100 * 1024 * 1024,   // 100MB disk cache
                                   diskPath: "ptchampion_network_cache")
        
        // Set timeouts
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Generic Request Methods
    
    /// Send a request with generic response type
    /// - Parameters:
    ///   - endpoint: API endpoint path
    ///   - method: HTTP method to use
    ///   - parameters: URL query parameters
    ///   - body: Optional request body
    ///   - requiresAuth: Whether this request requires authentication
    ///   - retries: Number of retries on failure
    /// - Returns: Generic response of type T
    func request<T: Decodable>(
        _ endpoint: String,
        method: HTTPMethod = .get,
        parameters: [String: String] = [:],
        body: Encodable? = nil,
        requiresAuth: Bool = false,
        retries: Int = 2
    ) async throws -> T {
        // Start timing for logging/telemetry
        let startTime = Date()
        
        // Construct URL with query parameters
        guard var urlComponents = URLComponents(string: "\(baseURL)\(endpoint)") else {
            throw NetworkError.invalidURL
        }
        
        // Add query parameters if provided
        if !parameters.isEmpty {
            urlComponents.queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        
        guard let url = urlComponents.url else {
            throw NetworkError.invalidURL
        }
        
        // Create request
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.rawValue
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Add authentication if required
        if requiresAuth, let token = try await getAuthToken() {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Encode body if provided
        if let body = body {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.keyEncodingStrategy = .convertToSnakeCase
            urlRequest.httpBody = try encoder.encode(body)
        }
        
        // Log request (in debug builds)
        #if DEBUG
        print("🌐 \(method.rawValue) \(endpoint)")
        if let parameters = urlComponents.queryItems, !parameters.isEmpty {
            print("   Parameters: \(parameters)")
        }
        #endif
        
        // Perform the request with retry logic
        return try await withRetry(retries: retries) { [weak self] in
            guard let self = self else {
                throw NetworkError.serviceUnavailable
            }
            
            return try await self.performRequest(urlRequest)
        }
    }
    
    /// Helper method to retry requests
    private func withRetry<T>(
        retries: Int,
        delay: TimeInterval = 0.5,
        task: @escaping () async throws -> T
    ) async throws -> T {
        var currentTry = 0
        var lastError: Error?
        
        repeat {
            do {
                return try await task()
            } catch let error as NetworkError {
                // Don't retry client errors (4xx) except for auth errors which might be fixed
                if case .clientError(let statusCode, _) = error, 
                   statusCode != 401, statusCode != 403 {
                    throw error
                }
                
                currentTry += 1
                lastError = error
                
                if currentTry <= retries {
                    // Exponential backoff
                    let backoffTime = delay * pow(2.0, Double(currentTry - 1))
                    try await Task.sleep(nanoseconds: UInt64(backoffTime * 1_000_000_000))
                }
            } catch {
                // For other errors, just retry
                currentTry += 1
                lastError = error
                
                if currentTry <= retries {
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        } while currentTry <= retries
        
        throw lastError ?? NetworkError.unknown
    }
    
    /// Perform the actual network request
    private func performRequest<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await session.data(for: request)
        
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
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                
                do {
                    return try decoder.decode(T.self, from: data)
                } catch {
                    #if DEBUG
                    print("❌ Decoding error: \(error)")
                    if let json = String(data: data, encoding: .utf8) {
                        print("Raw response: \(json)")
                    }
                    #endif
                    throw NetworkError.decodingError(error)
                }
            }
            
        case 401:
            // Unauthorized - token expired or invalid
            throw NetworkError.unauthorized
            
        case 403:
            // Forbidden - insufficient permissions
            throw NetworkError.forbidden
            
        case 400...499:
            // Client error
            let errorMessage = try? JSONDecoder().decode(ErrorResponse.self, from: data).message
            throw NetworkError.clientError(statusCode: httpResponse.statusCode, 
                                          message: errorMessage ?? "Request error")
            
        case 500...599:
            // Server error
            throw NetworkError.serverError(statusCode: httpResponse.statusCode)
            
        default:
            throw NetworkError.unexpectedStatusCode(httpResponse.statusCode)
        }
    }
    
    // MARK: - Authentication Helper Methods
    
    private func getAuthToken() async throws -> String? {
        guard let keychainService = keychainService else {
            throw NetworkError.unauthorized
        }
        
        return keychainService.getAccessToken()
    }
    
    /// Check server health
    /// - Returns: Server health status with response time
    func checkHealth() async -> ServerHealthStatus {
        let startTime = Date()
        
        do {
            let _: EmptyResponse = try await request("/health")
            let responseTime = Date().timeIntervalSince(startTime) * 1000
            return ServerHealthStatus(status: "ok")
        } catch {
            return ServerHealthStatus(status: "error")
        }
    }
} 