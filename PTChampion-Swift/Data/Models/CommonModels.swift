import Foundation

// Represents an empty response body (e.g., for 204 No Content or successful POST/PUT without returned data)
struct EmptyResponse: Codable {}

// Represents an empty request body
struct EmptyBody: Codable {} 