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
        }
    }
}

class APIClient {
    static let shared = APIClient()
    
    private let baseURL = "http://localhost:5000/api"
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.httpShouldSetCookies = true
        configuration.httpCookieAcceptPolicy = .always
        self.session = URLSession(configuration: configuration)
        
        self.decoder = JSONDecoder()
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder.dateDecodingStrategy = .iso8601
        
        self.encoder = JSONEncoder()
        self.encoder.keyEncodingStrategy = .convertToSnakeCase
        self.encoder.dateEncodingStrategy = .iso8601
    }
    
    // MARK: - Authentication
    
    func login(username: String, password: String) -> AnyPublisher<User, Error> {
        let loginData = ["username": username, "password": password]
        return makeRequest(endpoint: "/auth/login", method: "POST", body: loginData)
    }
    
    func register(username: String, password: String) -> AnyPublisher<User, Error> {
        let registerData = ["username": username, "password": password]
        return makeRequest(endpoint: "/auth/register", method: "POST", body: registerData)
    }
    
    func logout() -> AnyPublisher<Void, Error> {
        return makeRequest(endpoint: "/auth/logout", method: "POST")
    }
    
    func getCurrentUser() -> AnyPublisher<User, Error> {
        return makeRequest(endpoint: "/user", method: "GET")
    }
    
    // MARK: - User Location
    
    func updateUserLocation(latitude: Double, longitude: Double) -> AnyPublisher<User, Error> {
        let locationData = ["latitude": latitude, "longitude": longitude]
        return makeRequest(endpoint: "/user/location", method: "POST", body: locationData)
    }
    
    // MARK: - Exercises
    
    func getExercises() -> AnyPublisher<[Exercise], Error> {
        return makeRequest(endpoint: "/exercises", method: "GET")
    }
    
    func getExerciseById(id: Int) -> AnyPublisher<Exercise, Error> {
        return makeRequest(endpoint: "/exercises/\(id)", method: "GET")
    }
    
    // MARK: - User Exercises
    
    func getUserExercises() -> AnyPublisher<[UserExercise], Error> {
        return makeRequest(endpoint: "/user-exercises", method: "GET")
    }
    
    func getUserExercisesByType(type: String) -> AnyPublisher<[UserExercise], Error> {
        return makeRequest(endpoint: "/user-exercises/type/\(type)", method: "GET")
    }
    
    func getLatestUserExercises() -> AnyPublisher<[String: UserExercise], Error> {
        return makeRequest(endpoint: "/user-exercises/latest/all", method: "GET")
    }
    
    func createUserExercise(userExercise: CreateUserExerciseRequest) -> AnyPublisher<UserExercise, Error> {
        return makeRequest(endpoint: "/user-exercises", method: "POST", body: userExercise)
    }
    
    // MARK: - Leaderboard
    
    func getGlobalLeaderboard() -> AnyPublisher<[LeaderboardEntry], Error> {
        return makeRequest(endpoint: "/leaderboard/global", method: "GET")
    }
    
    func getLocalLeaderboard(latitude: Double, longitude: Double, radiusMiles: Int = 5) -> AnyPublisher<[LeaderboardEntry], Error> {
        return makeRequest(endpoint: "/leaderboard/local?latitude=\(latitude)&longitude=\(longitude)&radiusMiles=\(radiusMiles)", method: "GET")
    }
    
    // MARK: - Private Methods
    
    private func makeRequest<T: Decodable>(endpoint: String, method: String, body: Encodable? = nil) -> AnyPublisher<T, Error> {
        guard let url = URL(string: baseURL + endpoint) else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
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
    
    private func makeRequest<T>(endpoint: String, method: String, body: Encodable? = nil) -> AnyPublisher<Void, Error> {
        guard let url = URL(string: baseURL + endpoint) else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
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
}

// MARK: - Request Models

struct CreateUserExerciseRequest: Encodable {
    let exerciseId: Int
    let repetitions: Int?
    let formScore: Int?
    let timeInSeconds: Int?
    let completed: Bool
    let metadata: [String: String]?
}