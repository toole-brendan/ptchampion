// AuthenticationFix.swift
// Fixes for the 401 authentication errors

import Foundation

// Extension to NetworkClient to handle token refresh
extension NetworkClient {
    
    // Add token refresh capability
    func performAuthenticatedRequest<T: Decodable>(
        _ request: URLRequest,
        responseType: T.Type,
        retryCount: Int = 0
    ) async throws -> T {
        var modifiedRequest = request
        
        // Ensure we have a valid token
        guard let token = try? await ensureValidToken() else {
            logError("No valid authentication token available")
            throw NetworkError.unauthorized
        }
        
        // Add authorization header
        modifiedRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: modifiedRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            
            // Log the response
            logInfo("Response [\(httpResponse.statusCode)] \(request.url?.absoluteString ?? "")")
            
            if httpResponse.statusCode == 401 && retryCount < 2 {
                logWarning("Got 401, attempting token refresh (attempt \(retryCount + 1))")
                
                // Clear the cached token
                try? KeychainService.shared.deleteToken()
                
                // Try to refresh the token
                if let newToken = try? await refreshAuthToken() {
                    // Retry with new token
                    return try await performAuthenticatedRequest(
                        request,
                        responseType: responseType,
                        retryCount: retryCount + 1
                    )
                }
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                logError("Request failed with status \(httpResponse.statusCode)")
                if let errorData = try? JSONSerialization.jsonObject(with: data) {
                    logError("Error response: \(errorData)")
                }
                throw NetworkError.clientError(statusCode: httpResponse.statusCode, message: "Request failed")
            }
            
            return try JSONDecoder().decode(responseType, from: data)
            
        } catch {
            logError("Network request failed: \(error)")
            throw error
        }
    }
    
    private func ensureValidToken() async throws -> String {
        // First check keychain
        if let token = KeychainService.shared.getAccessToken() {
            // TODO: Add token expiry validation here
            return token
        }
        
        // Try to refresh
        if let newToken = try? await refreshAuthToken() {
            return newToken
        }
        
        throw NetworkError.unauthorized
    }
    
    private func refreshAuthToken() async throws -> String? {
        logInfo("Attempting to refresh authentication token")
        
        // Check if we have stored credentials
        guard let refreshToken = try KeychainService.shared.getRefreshToken() else {
            logError("No refresh token available")
            // Trigger re-authentication
            await MainActor.run {
                NotificationCenter.default.post(
                    name: .authenticationRequired,
                    object: nil
                )
            }
            return nil
        }
        
        // Make refresh request
        var request = URLRequest(url: URL(string: "\(self.apiBaseURL)/auth/refresh")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["refresh_token": refreshToken]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            logError("Token refresh failed")
            return nil
        }
        
        struct TokenResponse: Decodable {
            let access_token: String
            let refresh_token: String?
        }
        
        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
        
        // Store new tokens
        try KeychainService.shared.saveAccessToken(tokenResponse.access_token)
        if let newRefreshToken = tokenResponse.refresh_token {
            KeychainService.shared.saveRefreshToken(newRefreshToken)
        }
        
        logInfo("Token refreshed successfully")
        return tokenResponse.access_token
    }
}

// Use existing NetworkError enum from CommonNetworkTypes.swift
// No need to redefine it here

// Notification for re-authentication
extension Notification.Name {
    static let authenticationRequired = Notification.Name("authenticationRequired")
}

// Update AuthViewModel to handle re-authentication
extension AuthViewModel {
    func setupAuthenticationObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAuthenticationRequired),
            name: .authenticationRequired,
            object: nil
        )
    }
    
    @objc private func handleAuthenticationRequired() {
        logWarning("Re-authentication required")
        DispatchQueue.main.async { [weak self] in
            self?.logout()
        }
    }
} 