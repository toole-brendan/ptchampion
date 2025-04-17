import Foundation
import CoreLocation

// Implementation of LeaderboardServiceProtocol using URLSession
class LeaderboardService: LeaderboardServiceProtocol {

    // TODO: Replace with your actual backend base URL (e.g., from config)
    private let baseURL = URL(string: "http://localhost:8080/api/v1")!
    private let urlSession: URLSession
    private let jsonDecoder: JSONDecoder

    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
        self.jsonDecoder = JSONDecoder()
        // Configure decoder if needed (e.g., date strategies)
    }

    // MARK: - API Endpoints Enum (Helper)
    private enum APIEndpoint {
        case global
        case local(lat: Double, lon: Double, radius: Int)

        var path: String {
            switch self {
            case .global: return "/leaderboards/global"
            case .local: return "/leaderboards/local"
            }
        }

        var queryItems: [URLQueryItem]? {
            switch self {
            case .global:
                return nil
            case .local(let lat, let lon, let radius):
                return [
                    URLQueryItem(name: "latitude", value: String(lat)),
                    URLQueryItem(name: "longitude", value: String(lon)),
                    URLQueryItem(name: "radiusMiles", value: String(radius))
                ]
            }
        }

        var method: String { "GET" } // Assume GET for leaderboards
    }

    // MARK: - Protocol Implementation

    func fetchGlobalLeaderboard(authToken: String) async throws -> [LeaderboardEntry] {
        let endpoint = APIEndpoint.global
        guard var urlComponents = URLComponents(url: baseURL.appendingPathComponent(endpoint.path), resolvingAgainstBaseURL: false) else {
            throw APIError.invalidURL
        }
        urlComponents.queryItems = endpoint.queryItems

        guard let url = urlComponents.url else {
             throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method
        request.addValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")

        print("LeaderboardService: Fetching global leaderboard from \(url)")
        return try await performRequest(request: request)
    }

    func fetchLocalLeaderboard(latitude: Double, longitude: Double, radiusMiles: Int, authToken: String) async throws -> [LeaderboardEntry] {
         let endpoint = APIEndpoint.local(lat: latitude, lon: longitude, radius: radiusMiles)
         guard var urlComponents = URLComponents(url: baseURL.appendingPathComponent(endpoint.path), resolvingAgainstBaseURL: false) else {
             throw APIError.invalidURL
         }
         urlComponents.queryItems = endpoint.queryItems

         guard let url = urlComponents.url else {
              throw APIError.invalidURL
         }

         var request = URLRequest(url: url)
         request.httpMethod = endpoint.method
         request.addValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")

         print("LeaderboardService: Fetching local leaderboard from \(url)")
         return try await performRequest(request: request)
    }

    // MARK: - Generic Request Helper (Reuse or Share)
    private func performRequest<T: Decodable>(request: URLRequest) async throws -> T {
         let (data, response) = try await urlSession.data(for: request)
         guard let httpResponse = response as? HTTPURLResponse else {
             throw APIError.invalidResponse
         }
         print("LeaderboardService: Response status code: \(httpResponse.statusCode)")
         guard (200...299).contains(httpResponse.statusCode) else {
             if let errorResponse = try? jsonDecoder.decode(APIErrorResponse.self, from: data) {
                 print("LeaderboardService: Decoded API error: \(errorResponse.message)")
                 throw errorResponse
             }
             throw APIError.requestFailed(statusCode: httpResponse.statusCode)
         }
         do {
             let decodedData = try jsonDecoder.decode(T.self, from: data)
             return decodedData
         } catch {
             print("LeaderboardService: Failed to decode response: \(error)")
             throw APIError.decodingError(error)
         }
     }
}

// Assuming APIError and APIErrorResponse are accessible 