import Foundation

// Protocol defining the interface for secure token storage
protocol KeychainServiceProtocol {
    func saveToken(_ token: String) throws
    func loadToken() throws -> String?
    func deleteToken() throws
    // Optional: Methods for saving/loading other sensitive data like user ID
    func getUserId() -> Int?
} 