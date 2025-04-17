import Foundation

// Implementation of WorkoutServiceProtocol using URLSession
class WorkoutService: WorkoutServiceProtocol {

    // TODO: Replace with your actual backend base URL (e.g., from config)
    private let baseURL = URL(string: "http://localhost:8080/api/v1")!
    private let urlSession: URLSession
    private let jsonDecoder: JSONDecoder
    private let jsonEncoder: JSONEncoder

    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
        // Configure date strategy for decoder/encoder
        self.jsonDecoder = JSONDecoder()
        self.jsonDecoder.dateDecodingStrategy = .iso8601 // Adjust if backend uses different format
        self.jsonEncoder = JSONEncoder()
        self.jsonEncoder.dateEncodingStrategy = .iso8601 // Adjust if backend uses different format
    }

    // MARK: - API Endpoints Enum (Helper)
    private enum APIEndpoint {
        case saveWorkout
        case getHistory
        // case getWorkoutDetail(id: String)

        var path: String {
            switch self {
            case .saveWorkout: return "/workouts"
            case .getHistory: return "/workouts/history"
            // case .getWorkoutDetail(let id): return "/workouts/\(id)"
            }
        }

        var method: String {
            switch self {
            case .saveWorkout: return "POST"
            case .getHistory: return "GET"
            // case .getWorkoutDetail: return "GET"
            }
        }
    }

    // MARK: - Protocol Implementation

    func saveWorkout(result: WorkoutResultPayload, authToken: String) async throws -> Void {
        let endpoint = APIEndpoint.saveWorkout
        let url = baseURL.appendingPathComponent(endpoint.path)
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization") // Add auth token
        request.httpBody = try jsonEncoder.encode(result)

        print("WorkoutService: Saving workout to \(url)")
        let (_, response) = try await urlSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse // Use APIError from AuthService or define a shared one
        }

        print("WorkoutService: Save workout response status: \(httpResponse.statusCode)")
        guard (200...299).contains(httpResponse.statusCode) else {
            // TODO: Handle potential error response body
            throw APIError.requestFailed(statusCode: httpResponse.statusCode)
        }
        // Success
    }

    func fetchWorkoutHistory(authToken: String) async throws -> [WorkoutRecord] {
        let endpoint = APIEndpoint.getHistory
        let url = baseURL.appendingPathComponent(endpoint.path)
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method
        request.addValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization") // Add auth token

        print("WorkoutService: Fetching history from \(url)")
        return try await performRequest(request: request)
    }

    // MARK: - Generic Request Helper (Similar to AuthService)
    // Consider moving this to a shared NetworkClient class
    private func performRequest<T: Decodable>(request: URLRequest) async throws -> T {
         let (data, response) = try await urlSession.data(for: request)

         guard let httpResponse = response as? HTTPURLResponse else {
             throw APIError.invalidResponse
         }

         print("WorkoutService: Response status code: \(httpResponse.statusCode)")
         guard (200...299).contains(httpResponse.statusCode) else {
             if let errorResponse = try? jsonDecoder.decode(APIErrorResponse.self, from: data) {
                 print("WorkoutService: Decoded API error: \(errorResponse.message)")
                 throw errorResponse
             }
             throw APIError.requestFailed(statusCode: httpResponse.statusCode)
         }

         do {
             let decodedData = try jsonDecoder.decode(T.self, from: data)
             return decodedData
         } catch {
             print("WorkoutService: Failed to decode response: \(error)")
             throw APIError.decodingError(error)
         }
     }
}

// Assuming APIError and APIErrorResponse are accessible (e.g., defined globally or imported)
// If not, redefine or move them here or to a shared location. 