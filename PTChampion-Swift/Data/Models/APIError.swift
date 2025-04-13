import Foundation

// Represents a standard error response from the backend API
struct APIErrorResponse: Codable, Error {
    let error: String
    let message: String? // Optional detailed message
    let code: Int?       // Optional backend-specific error code
}

// Custom Error enum for client-side network errors
enum NetworkError: Error, LocalizedError {
    case badURL
    case requestFailed(Error)
    case invalidResponse(URLResponse?)
    case decodingError(Error)
    case apiError(APIErrorResponse)
    case unauthorized
    case unknown

    var errorDescription: String? {
        switch self {
        case .badURL: return "Invalid API endpoint URL."
        case .requestFailed(let error): return "Network request failed: \(error.localizedDescription)"
        case .invalidResponse: return "Received an invalid response from the server."
        case .decodingError(let error): return "Failed to decode server response: \(error.localizedDescription)"
        case .apiError(let apiError): return apiError.message ?? apiError.error // Use backend message if available
        case .unauthorized: return "Unauthorized. Please check your login credentials."
        case .unknown: return "An unknown error occurred."
        }
    }
} 