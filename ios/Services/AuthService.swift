import Foundation

// Implementation of AuthServiceProtocol using URLSession
class AuthService: AuthServiceProtocol {

    // TODO: Replace with your actual backend base URL (e.g., from config)
    private let baseURL = URL(string: "http://localhost:8080/api/v1")!

    private let urlSession: URLSession
    private let jsonDecoder: JSONDecoder
    private let jsonEncoder: JSONEncoder

    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
        self.jsonDecoder = JSONDecoder()
        // Configure decoder/encoder if needed (e.g., date strategies)
        self.jsonEncoder = JSONEncoder()
    }

    // MARK: - API Endpoints Enum (Helper)
    private enum APIEndpoint {
        case login
        case register
        // case userProfile // Example for fetching user

        var path: String {
            switch self {
            case .login: return "/auth/login"
            case .register: return "/auth/register"
            // case .userProfile: return "/users/me"
            }
        }

        var method: String {
            switch self {
            case .login, .register: return "POST"
            // case .userProfile: return "GET"
            }
        }
    }

    // MARK: - Protocol Implementation

    func login(credentials: LoginRequest) async throws -> AuthResponse {
        let endpoint = APIEndpoint.login
        let url = baseURL.appendingPathComponent(endpoint.path)
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try jsonEncoder.encode(credentials)

        print("AuthService: Sending login request to \(url)")
        return try await performRequest(request: request)
    }

    func register(userInfo: RegistrationRequest) async throws -> Void {
        let endpoint = APIEndpoint.register
        let url = baseURL.appendingPathComponent(endpoint.path)
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try jsonEncoder.encode(userInfo)

        print("AuthService: Sending registration request to \(url)")
        // Perform request, discarding response data if successful
        let (_, response) = try await urlSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        print("AuthService: Registration response status code: \(httpResponse.statusCode)")
        guard (200...299).contains(httpResponse.statusCode) else {
            // Attempt to decode error response if available
            // Note: This assumes the backend sends APIErrorResponse on failure
            // let errorData = // Need the data from the failed request if we want to decode body
            // if let errorResponse = try? jsonDecoder.decode(APIErrorResponse.self, from: errorData) {
            //     throw errorResponse
            // }
            throw APIError.requestFailed(statusCode: httpResponse.statusCode)
        }
        // Registration successful, return Void
        return
    }

    // MARK: - Generic Request Helper (Example)

    private func performRequest<T: Decodable>(request: URLRequest) async throws -> T {
        let (data, response) = try await urlSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        print("AuthService: Response status code: \(httpResponse.statusCode)")
        guard (200...299).contains(httpResponse.statusCode) else {
            // Attempt to decode standard error response
            if let errorResponse = try? jsonDecoder.decode(APIErrorResponse.self, from: data) {
                print("AuthService: Decoded API error: \(errorResponse.message)")
                throw errorResponse
            }
            throw APIError.requestFailed(statusCode: httpResponse.statusCode)
        }

        do {
            let decodedData = try jsonDecoder.decode(T.self, from: data)
            return decodedData
        } catch {
            print("AuthService: Failed to decode response: \(error)")
            throw APIError.decodingError(error)
        }
    }
}

// MARK: - API Error Enum

enum APIError: Error, LocalizedError {
    case invalidURL
    case requestFailed(statusCode: Int)
    case invalidResponse
    case decodingError(Error)
    case encodingError(Error)
    case underlying(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL encountered."
        case .requestFailed(let code): return "Request failed with status code: \(code)."
        case .invalidResponse: return "Received an invalid response from the server."
        case .decodingError(let error): return "Failed to decode response: \(error.localizedDescription)"
        case .encodingError(let error): return "Failed to encode request: \(error.localizedDescription)"
        case .underlying(let error): return error.localizedDescription
        }
    }
} 