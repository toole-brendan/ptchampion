import Foundation

// A protocol for network client operations
protocol NetworkClientProtocol {
    func performRequest<T: Decodable>(endpoint: String, method: String, body: Data?, responseType: T.Type) async throws -> T
}

// Concrete NetworkClient implementation
class NetworkClient: NetworkClientProtocol {
    
    // Add shared singleton instance
    static let shared = NetworkClient()
    
    // Base URL for API
    let baseURL = "https://ptchampion-api-westus.azurewebsites.net/api/v1"
    
    // Create shared URLSession
    private let session: URLSession
    
    // Initialize with optional URLSession for testing
    init(session: URLSession = URLSession.shared) {
        self.session = session
        print("NetworkClient initialized")
    }
    
    // Lazy token retrieval to avoid initialization cycles
    private func getAuthToken() -> String? {
        return KeychainService.shared.getAccessToken()
    }
    
    // Generic method to perform network requests
    func performRequest<T: Decodable>(endpoint: String, method: String = "GET", body: Data? = nil, responseType: T.Type) async throws -> T {
        // Create full URL from baseURL and endpoint
        guard let url = URL(string: baseURL + endpoint) else {
            throw URLError(.badURL)
        }
        
        // Create and configure URLRequest
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add auth token if available - using lazy token access
        if let token = getAuthToken() {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Add body data if provided
        if let body = body {
            request.httpBody = body
        }
        
        print("📡 Sending \(method) request to \(url.absoluteString)")
        
        // Perform the request and handle response
        let (data, response) = try await session.data(for: request)
        
        // Verify HTTP status code
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            print("❌ HTTP Error: Status code \(statusCode)")
            throw URLError(.badServerResponse)
        }
        
        print("✅ Request successful with status code \((response as? HTTPURLResponse)?.statusCode ?? 0)")
        
        // Decode and return response data
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            print("❌ Decoding error: \(error)")
            if let dataString = String(data: data, encoding: .utf8) {
                print("Response data: \(dataString)")
            }
            throw error
        }
    }
} 