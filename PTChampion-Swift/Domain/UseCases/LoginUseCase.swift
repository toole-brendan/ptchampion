import Foundation

// Use case for handling user login.
class LoginUseCase {
    // Depend on the repository protocol, not the concrete implementation.
    private let authRepository: AuthRepositoryProtocol
    
    // Inject the repository dependency.
    init(authRepository: AuthRepositoryProtocol) {
        self.authRepository = authRepository
    }
    
    // Executes the login operation.
    // Takes username and password, returns the User object on success.
    func execute(username: String, password: String) async throws -> User {
        // Input validation could be added here if needed.
        guard !username.isEmpty, !password.isEmpty else {
            // Consider defining specific DomainError types
            throw NSError(domain: "LoginUseCase", code: 1, userInfo: [NSLocalizedDescriptionKey: "Username and password cannot be empty."])
        }
        
        // Call the repository method to perform the login.
        return try await authRepository.login(username: username, password: password)
    }
} 