import Foundation

enum HTTPMethod: String { case get, post, put, patch, delete }

/// Consolidated network error type that covers all error cases across the app
public enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case unauthorized
    case forbidden               // used by NetworkService
    case needsRetryWithNewToken  // used by UnifiedNetworkService
    case serviceUnavailable      // used by NetworkService
    case clientError(statusCode: Int, message: String)
    case serverError(statusCode: Int)
    case server(status: Int, detail: String) // format used by UnifiedNetworkService
    case unexpectedStatusCode(Int)
    case maxRetriesExceeded
    case decodingError(Error)
    case decodingFailed         // simpler version without the underlying error
    case unknown
}

struct EmptyResponse: Decodable {}

struct ErrorResponse: Decodable, Error {
    let message: String
}

struct ServerHealthStatus: Decodable {
    let status: String        // e.g. "ok"
} 