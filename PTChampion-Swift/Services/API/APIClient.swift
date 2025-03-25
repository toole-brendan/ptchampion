import Foundation
import Combine

enum APIError: Error {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse
    case decodingFailed(Error)
    case serverError(Int, String)
    case unauthorized
    case notFound
    case noToken
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .requestFailed(let error):
            return "Request failed: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingFailed(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .serverError(let code, let message):
            return "Server error (\(code)): \(message)"
        case .unauthorized:
            return "You are not authorized to access this resource"
        case .notFound:
            return "Resource not found"
        case .noToken:
            return "Authentication token not found"
        }
    }
}

// MARK: - Auth Response
struct AuthResponse: Codable {
    let user: User
    let token: String
    let expiresIn: String
}

// MARK: - API Health Response
struct HealthResponse: Codable {
    let status: String
    let timestamp: String
    let version: String
}

// MARK: - API Client
class APIClient {
    static let shared = APIClient()
    
    private let baseURL = "http://localhost:5000/api"
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    // Token storage
    private let tokenKey = "auth_token"
    private let userIdKey = "user_id"
    private let tokenExpiryKey = "token_expiry"
    
    // UserDefaults for persistence
    private let defaults = UserDefaults.standard
    
    // Current user cache
    private var currentUser: User?
    
    private init() {
        let configuration = URLSessionConfiguration.default
        self.session = URLSession(configuration: configuration)
        
        self.decoder = JSONDecoder()
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder.dateDecodingStrategy = .iso8601
        
        self.encoder = JSONEncoder()
        self.encoder.keyEncodingStrategy = .convertToSnakeCase
        self.encoder.dateEncodingStrategy = .iso8601
    }
    
    // MARK: - Token Management
    
    private func saveToken(token: String, expiresIn: String) {
        defaults.set(token, forKey: tokenKey)
        defaults.set(expiresIn, forKey: tokenExpiryKey)
    }
    
    private func getToken() -> String? {
        return defaults.string(forKey: tokenKey)
    }
    
    private func clearToken() {
        defaults.removeObject(forKey: tokenKey)
        defaults.removeObject(forKey: tokenExpiryKey)
        defaults.removeObject(forKey: userIdKey)
    }
    
    private func addAuthHeader(to request: inout URLRequest) {
        if let token = getToken() {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
    }
    
    // MARK: - Health Check
    
    func checkApiHealth() -> AnyPublisher<HealthResponse, Error> {
        return makeRequest(endpoint: "/health", method: "GET", requiresAuth: false)
    }
    
    // MARK: - Authentication
    
    func login(username: String, password: String) -> AnyPublisher<User, Error> {
        let loginData = ["username": username, "password": password]
        
        return makeRequest(endpoint: "/login", method: "POST", body: loginData, requiresAuth: false, additionalHeaders: ["X-Client-Platform": "mobile"])
            .flatMap { (authResponse: AuthResponse) -> AnyPublisher<User, Error> in
                // Save token and user
                self.saveToken(token: authResponse.token, expiresIn: authResponse.expiresIn)
                self.currentUser = authResponse.user
                defaults.set(authResponse.user.id, forKey: self.userIdKey)
                
                return Just(authResponse.user)
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    func register(username: String, password: String) -> AnyPublisher<User, Error> {
        let registerData = ["username": username, "password": password]
        
        return makeRequest(endpoint: "/register", method: "POST", body: registerData, requiresAuth: false, additionalHeaders: ["X-Client-Platform": "mobile"])
            .flatMap { (authResponse: AuthResponse) -> AnyPublisher<User, Error> in
                // Save token and user
                self.saveToken(token: authResponse.token, expiresIn: authResponse.expiresIn)
                self.currentUser = authResponse.user
                defaults.set(authResponse.user.id, forKey: self.userIdKey)
                
                return Just(authResponse.user)
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    func validateToken() -> AnyPublisher<Bool, Error> {
        guard getToken() != nil else {
            return Just(false)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        
        return makeRequest(endpoint: "/validate-token", method: "GET", requiresAuth: true)
            .map { (_: User) -> Bool in
                return true
            }
            .catch { error -> AnyPublisher<Bool, Error> in
                if case APIError.unauthorized = error {
                    self.clearToken()
                    return Just(false).setFailureType(to: Error.self).eraseToAnyPublisher()
                }
                return Fail(error: error).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    func logout() -> AnyPublisher<Void, Error> {
        clearToken()
        currentUser = nil
        
        // Optional server-side logout (but we don't need to wait for it)
        _ = makeRequest(endpoint: "/logout", method: "POST", requiresAuth: false)
            .catch { _ in Just(()).setFailureType(to: Error.self).eraseToAnyPublisher() }
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
        
        return Just(())
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func getCurrentUser() -> AnyPublisher<User, Error> {
        // If we have a cached user, return it
        if let user = currentUser {
            return Just(user)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        
        // Otherwise fetch from API
        return makeRequest(endpoint: "/user", method: "GET", requiresAuth: true)
            .handleEvents(receiveOutput: { [weak self] user in
                self?.currentUser = user
            })
            .eraseToAnyPublisher()
    }
    
    // MARK: - User Location
    
    func updateUserLocation(latitude: Double, longitude: Double) -> AnyPublisher<User, Error> {
        let locationData = ["latitude": latitude, "longitude": longitude]
        return makeRequest(endpoint: "/user/location", method: "POST", body: locationData, requiresAuth: true)
            .handleEvents(receiveOutput: { [weak self] user in
                self?.currentUser = user
            })
            .eraseToAnyPublisher()
    }
    
    // MARK: - Exercises (Public endpoints)
    
    func getExercises() -> AnyPublisher<[Exercise], Error> {
        return makeRequest(endpoint: "/exercises", method: "GET", requiresAuth: false)
    }
    
    func getExerciseById(id: Int) -> AnyPublisher<Exercise, Error> {
        return makeRequest(endpoint: "/exercises/\(id)", method: "GET", requiresAuth: false)
    }
    
    // MARK: - User Exercises (Protected endpoints)
    
    func getUserExercises() -> AnyPublisher<[UserExercise], Error> {
        return makeRequest(endpoint: "/user-exercises", method: "GET", requiresAuth: true)
    }
    
    func getUserExercisesByType(type: String) -> AnyPublisher<[UserExercise], Error> {
        return makeRequest(endpoint: "/user-exercises/\(type)", method: "GET", requiresAuth: true)
    }
    
    func getLatestUserExercises() -> AnyPublisher<[String: UserExercise], Error> {
        return makeRequest(endpoint: "/user-exercises/latest/all", method: "GET", requiresAuth: true)
    }
    
    func createUserExercise(userExercise: CreateUserExerciseRequest) -> AnyPublisher<UserExercise, Error> {
        return makeRequest(endpoint: "/user-exercises", method: "POST", body: userExercise, requiresAuth: true)
    }
    
    // MARK: - Leaderboard (Public endpoints)
    
    func getGlobalLeaderboard() -> AnyPublisher<[LeaderboardEntry], Error> {
        return makeRequest(endpoint: "/leaderboard/global", method: "GET", requiresAuth: false)
    }
    
    func getLocalLeaderboard(latitude: Double, longitude: Double, radiusMiles: Int = 5) -> AnyPublisher<[LeaderboardEntry], Error> {
        return makeRequest(endpoint: "/leaderboard/local?latitude=\(latitude)&longitude=\(longitude)&radius=\(radiusMiles)", method: "GET", requiresAuth: false)
    }
    
    // MARK: - Generic Request Methods
    
    private func makeRequest<T: Decodable>(
        endpoint: String,
        method: String,
        body: Encodable? = nil,
        requiresAuth: Bool = false,
        additionalHeaders: [String: String] = [:]
    ) -> AnyPublisher<T, Error> {
        guard let url = URL(string: baseURL + endpoint) else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authorization if required
        if requiresAuth {
            guard let token = getToken() else {
                return Fail(error: APIError.noToken).eraseToAnyPublisher()
            }
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Add any additional headers
        additionalHeaders.forEach { key, value in
            request.addValue(value, forHTTPHeaderField: key)
        }
        
        // Add body if provided
        if let body = body {
            do {
                request.httpBody = try encoder.encode(body)
            } catch {
                return Fail(error: error).eraseToAnyPublisher()
            }
        }
        
        return session.dataTaskPublisher(for: request)
            .mapError { APIError.requestFailed($0) }
            .flatMap { data, response -> AnyPublisher<T, Error> in
                guard let httpResponse = response as? HTTPURLResponse else {
                    return Fail(error: APIError.invalidResponse).eraseToAnyPublisher()
                }
                
                switch httpResponse.statusCode {
                case 200...299:
                    do {
                        let decodedData = try self.decoder.decode(T.self, from: data)
                        return Just(decodedData)
                            .setFailureType(to: Error.self)
                            .eraseToAnyPublisher()
                    } catch {
                        return Fail(error: APIError.decodingFailed(error)).eraseToAnyPublisher()
                    }
                case 401:
                    // Clear token on 401 Unauthorized
                    if requiresAuth {
                        self.clearToken()
                    }
                    return Fail(error: APIError.unauthorized).eraseToAnyPublisher()
                case 404:
                    return Fail(error: APIError.notFound).eraseToAnyPublisher()
                default:
                    let message = String(data: data, encoding: .utf8) ?? "Unknown error"
                    return Fail(error: APIError.serverError(httpResponse.statusCode, message)).eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }
    
    // Overload for void responses
    private func makeRequest<T>(
        endpoint: String,
        method: String,
        body: Encodable? = nil,
        requiresAuth: Bool = false,
        additionalHeaders: [String: String] = [:]
    ) -> AnyPublisher<Void, Error> {
        guard let url = URL(string: baseURL + endpoint) else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authorization if required
        if requiresAuth {
            guard let token = getToken() else {
                return Fail(error: APIError.noToken).eraseToAnyPublisher()
            }
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Add any additional headers
        additionalHeaders.forEach { key, value in
            request.addValue(value, forHTTPHeaderField: key)
        }
        
        if let body = body {
            do {
                request.httpBody = try encoder.encode(body)
            } catch {
                return Fail(error: error).eraseToAnyPublisher()
            }
        }
        
        return session.dataTaskPublisher(for: request)
            .mapError { APIError.requestFailed($0) }
            .flatMap { data, response -> AnyPublisher<Void, Error> in
                guard let httpResponse = response as? HTTPURLResponse else {
                    return Fail(error: APIError.invalidResponse).eraseToAnyPublisher()
                }
                
                switch httpResponse.statusCode {
                case 200...299:
                    return Just(())
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                case 401:
                    // Clear token on 401 Unauthorized
                    if requiresAuth {
                        self.clearToken()
                    }
                    return Fail(error: APIError.unauthorized).eraseToAnyPublisher()
                case 404:
                    return Fail(error: APIError.notFound).eraseToAnyPublisher()
                default:
                    let message = String(data: data, encoding: .utf8) ?? "Unknown error"
                    return Fail(error: APIError.serverError(httpResponse.statusCode, message)).eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Auth Status
    
    var isLoggedIn: Bool {
        return getToken() != nil && defaults.integer(forKey: userIdKey) > 0
    }
}

// MARK: - Request Models

struct CreateUserExerciseRequest: Encodable {
    let exerciseId: Int
    let type: String
    let repetitions: Int?
    let formScore: Int?
    let timeInSeconds: Int?
    let distance: Double?
    let score: Int
    let metadata: [String: String]?
}