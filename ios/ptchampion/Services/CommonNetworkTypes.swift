import Foundation

enum HTTPMethod: String { case get, post, put, patch, delete }

enum NetworkError: Error {
    case invalidURL
    case decodingFailed
    case server(status: Int, detail: String)
}

struct EmptyResponse: Decodable {}

struct ErrorResponse: Decodable, Error {
    let message: String
}

struct ServerHealthStatus: Decodable {
    let status: String        // e.g. "ok"
} 