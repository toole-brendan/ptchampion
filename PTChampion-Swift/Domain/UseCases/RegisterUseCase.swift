import Foundation

// Use case for handling user registration.
class RegisterUseCase {
    private let authRepository: AuthRepositoryProtocol
    
    init(authRepository: AuthRepositoryProtocol) {
        self.authRepository = authRepository
    }
    
    // Executes the registration operation.
    func execute(username: String, password: String) async throws -> User {
        // Add more robust validation (e.g., password complexity) if needed.
        guard !username.isEmpty, !password.isEmpty else {
            throw NSError(domain: "RegisterUseCase", code: 1, userInfo: [NSLocalizedDescriptionKey: "Username and password cannot be empty."])
        }
        
        return try await authRepository.register(username: username, password: password)
    }
} 