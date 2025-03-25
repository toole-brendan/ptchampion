import Foundation
import Combine

enum APIError: Error {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case decodingError(Error)
    case networkError(Error)
    case unauthorized
    case unknown
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid server response"
        case .httpError(let statusCode):
            return "HTTP Error: \(statusCode)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .unauthorized:
            return "Unauthorized access"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}

class APIClient {
    static let shared = APIClient()
    
    private let baseURL = "http://localhost:5000/api"
    private let session = URLSession.shared
    private let jsonDecoder = JSONDecoder()
    private let jsonEncoder = JSONEncoder()
    
    private init() {
        // Configure date formatting for JSON
        jsonDecoder.dateDecodingStrategy = .iso8601
        jsonEncoder.dateEncodingStrategy = .iso8601
        jsonEncoder.keyEncodingStrategy = .convertToSnakeCase
    }
    
    // MARK: - Authentication
    
    func login(credentials: LoginCredentials) -> AnyPublisher<User, APIError> {
        return request(endpoint: "/auth/login", method: "POST", body: credentials)
    }
    
    func register(credentials: RegisterCredentials) -> AnyPublisher<User, APIError> {
        return request(endpoint: "/auth/register", method: "POST", body: credentials)
    }
    
    func logout() -> AnyPublisher<Void, APIError> {
        return requestVoid(endpoint: "/auth/logout", method: "POST")
    }
    
    func getCurrentUser() -> AnyPublisher<User, APIError> {
        return request(endpoint: "/user", method: "GET")
    }
    
    func updateUserLocation(update: LocationUpdate) -> AnyPublisher<User, APIError> {
        return request(endpoint: "/user/location", method: "PATCH", body: update)
    }
    
    // MARK: - Exercises
    
    func getExercises() -> AnyPublisher<[Exercise], APIError> {
        return request(endpoint: "/exercises", method: "GET")
    }
    
    func getExerciseById(id: Int) -> AnyPublisher<Exercise, APIError> {
        return request(endpoint: "/exercises/\(id)", method: "GET")
    }
    
    // MARK: - User Exercises
    
    func getUserExercises() -> AnyPublisher<[UserExercise], APIError> {
        return request(endpoint: "/user-exercises", method: "GET")
    }
    
    func getUserExercisesByType(type: ExerciseType) -> AnyPublisher<[UserExercise], APIError> {
        return request(endpoint: "/user-exercises/\(type.rawValue)", method: "GET")
    }
    
    func getLatestUserExercises() -> AnyPublisher<[String: UserExercise], APIError> {
        return request(endpoint: "/user-exercises/latest/all", method: "GET")
    }
    
    func createUserExercise(exercise: UserExerciseSubmission) -> AnyPublisher<UserExercise, APIError> {
        return request(endpoint: "/user-exercises", method: "POST", body: exercise)
    }
    
    // MARK: - Leaderboard
    
    func getGlobalLeaderboard() -> AnyPublisher<[LeaderboardEntry], APIError> {
        return request(endpoint: "/leaderboard/global", method: "GET")
    }
    
    func getLocalLeaderboard(latitude: Double, longitude: Double, radiusMiles: Int = 5) -> AnyPublisher<[LeaderboardEntry], APIError> {
        let queryParams = "?latitude=\(latitude)&longitude=\(longitude)&radius=\(radiusMiles)"
        return request(endpoint: "/leaderboard/local\(queryParams)", method: "GET")
    }
    
    // MARK: - Generic Request Methods
    
    private func request<T: Decodable, U: Encodable>(endpoint: String, method: String, body: U? = nil) -> AnyPublisher<T, APIError> {
        guard let url = URL(string: baseURL + endpoint) else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let body = body {
            do {
                request.httpBody = try jsonEncoder.encode(body)
            } catch {
                return Fail(error: APIError.decodingError(error)).eraseToAnyPublisher()
            }
        }
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }
                
                if httpResponse.statusCode == 401 {
                    throw APIError.unauthorized
                }
                
                if httpResponse.statusCode < 200 || httpResponse.statusCode > 299 {
                    throw APIError.httpError(httpResponse.statusCode)
                }
                
                return data
            }
            .decode(type: T.self, decoder: jsonDecoder)
            .mapError { error in
                if let apiError = error as? APIError {
                    return apiError
                } else if error is DecodingError {
                    return APIError.decodingError(error)
                } else {
                    return APIError.networkError(error)
                }
            }
            .eraseToAnyPublisher()
    }
    
    private func requestVoid<U: Encodable>(endpoint: String, method: String, body: U? = nil) -> AnyPublisher<Void, APIError> {
        guard let url = URL(string: baseURL + endpoint) else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let body = body {
            do {
                request.httpBody = try jsonEncoder.encode(body)
            } catch {
                return Fail(error: APIError.decodingError(error)).eraseToAnyPublisher()
            }
        }
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }
                
                if httpResponse.statusCode == 401 {
                    throw APIError.unauthorized
                }
                
                if httpResponse.statusCode < 200 || httpResponse.statusCode > 299 {
                    throw APIError.httpError(httpResponse.statusCode)
                }
                
                return ()
            }
            .mapError { error in
                if let apiError = error as? APIError {
                    return apiError
                } else {
                    return APIError.networkError(error)
                }
            }
            .eraseToAnyPublisher()
    }
}