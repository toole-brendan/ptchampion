import Foundation

enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case invalidData
    case requestFailed(Error)
    case unauthorized
    case serverError(Int)
    case decodingError(Error)
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .invalidData:
            return "Invalid data received"
        case .requestFailed(let error):
            return "Request failed: \(error.localizedDescription)"
        case .unauthorized:
            return "Unauthorized. Please login again."
        case .serverError(let code):
            return "Server error with code: \(code)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        }
    }
}

class NetworkService {
    // Singleton instance
    static let shared = NetworkService()
    
    // Base URL for the API
    private let baseURL = "https://your-app-backend.com/api"
    // This should be replaced with actual server URL when deployed
    
    // Session for API requests
    private let session = URLSession.shared
    
    // Authentication token
    private var authToken: String?
    
    private init() {}
    
    // Set authentication token
    func setAuthToken(_ token: String?) {
        self.authToken = token
    }
    
    // MARK: - Generic Request Methods
    
    /// Performs a network request
    /// - Parameters:
    ///   - endpoint: API endpoint to call
    ///   - method: HTTP method (GET, POST, etc)
    ///   - body: Optional request body
    ///   - completion: Completion handler with Result type
    func request<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: [String: Any]? = nil,
        completion: @escaping (Result<T, NetworkError>) -> Void
    ) {
        // Construct URL
        guard let url = URL(string: "\(baseURL)/\(endpoint)") else {
            completion(.failure(.invalidURL))
            return
        }
        
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add auth token if available
        if let token = authToken {
            // This would depend on your authentication system
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Add body for POST requests
        if let body = body {
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: body)
            } catch {
                completion(.failure(.requestFailed(error)))
                return
            }
        }
        
        // Perform request
        let task = session.dataTask(with: request) { data, response, error in
            // Check for errors
            if let error = error {
                completion(.failure(.requestFailed(error)))
                return
            }
            
            // Check response status
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.invalidResponse))
                return
            }
            
            // Handle HTTP status codes
            switch httpResponse.statusCode {
            case 200...299:
                // Success
                break
            case 401:
                completion(.failure(.unauthorized))
                return
            case 400...499:
                completion(.failure(.serverError(httpResponse.statusCode)))
                return
            case 500...599:
                completion(.failure(.serverError(httpResponse.statusCode)))
                return
            default:
                completion(.failure(.invalidResponse))
                return
            }
            
            // Ensure data exists
            guard let data = data else {
                completion(.failure(.invalidData))
                return
            }
            
            // Decode the response
            do {
                let decodedResponse = try JSONDecoder().decode(T.self, from: data)
                completion(.success(decodedResponse))
            } catch {
                print("Decoding error: \(error)")
                completion(.failure(.decodingError(error)))
            }
        }
        
        task.resume()
    }
    
    // MARK: - User API Methods
    
    func login(username: String, password: String, completion: @escaping (Result<User, NetworkError>) -> Void) {
        let body = ["username": username, "password": password]
        request(endpoint: "auth/login", method: "POST", body: body, completion: completion)
    }
    
    func register(username: String, password: String, completion: @escaping (Result<User, NetworkError>) -> Void) {
        let body = ["username": username, "password": password]
        request(endpoint: "auth/register", method: "POST", body: body, completion: completion)
    }
    
    func getCurrentUser(completion: @escaping (Result<User, NetworkError>) -> Void) {
        request(endpoint: "user", completion: completion)
    }
    
    func updateUserLocation(latitude: Double, longitude: Double, completion: @escaping (Result<User, NetworkError>) -> Void) {
        let body = ["latitude": latitude, "longitude": longitude]
        request(endpoint: "user/location", method: "POST", body: body, completion: completion)
    }
    
    // MARK: - Exercise API Methods
    
    func getExercises(completion: @escaping (Result<[Exercise], NetworkError>) -> Void) {
        request(endpoint: "exercises", completion: completion)
    }
    
    func getUserExercises(completion: @escaping (Result<[UserExercise], NetworkError>) -> Void) {
        request(endpoint: "user-exercises", completion: completion)
    }
    
    func getLatestUserExercises(completion: @escaping (Result<[String: UserExercise], NetworkError>) -> Void) {
        request(endpoint: "user-exercises/latest/all", completion: completion)
    }
    
    func saveExerciseResult(exerciseId: Int, repetitions: Int? = nil, timeInSeconds: Int? = nil, 
                            formScore: Int? = nil, grade: Int, completion: @escaping (Result<UserExercise, NetworkError>) -> Void) {
        var body: [String: Any] = [
            "exerciseId": exerciseId,
            "grade": grade,
            "completed": true
        ]
        
        // Add optional parameters if provided
        if let repetitions = repetitions {
            body["repetitions"] = repetitions
        }
        
        if let timeInSeconds = timeInSeconds {
            body["timeInSeconds"] = timeInSeconds
        }
        
        if let formScore = formScore {
            body["formScore"] = formScore
        }
        
        request(endpoint: "user-exercises", method: "POST", body: body, completion: completion)
    }
    
    // MARK: - Leaderboard API Methods
    
    func getGlobalLeaderboard(completion: @escaping (Result<[LeaderboardEntry], NetworkError>) -> Void) {
        request(endpoint: "leaderboard/global", completion: completion)
    }
    
    func getLocalLeaderboard(completion: @escaping (Result<[LeaderboardEntry], NetworkError>) -> Void) {
        request(endpoint: "leaderboard/local", completion: completion)
    }
}