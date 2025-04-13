import Foundation
// Removed Combine import
import PTChampion_Swift // Assuming models are accessible via the main module

// MARK: - API Client
class APIClient {
    static let shared = APIClient()

    private let baseURL = URL(string: "http://localhost:5000/api")! // Standardized base URL
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let authTokenManager = AuthTokenManager.shared // Placeholder for token management

    // Current user cache - consider moving to a dedicated UserSession manager
    private var currentUser: User?

    private init() {
        let configuration = URLSessionConfiguration.default
        self.session = URLSession(configuration: configuration)

        self.decoder = JSONDecoder()
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder.dateDecodingStrategy = .iso8601

        self.encoder = JSONEncoder()
        self.encoder.keyEncodingStrategy = .convertToSnakeCase
        self.encoder.dateEncodingStrategy = .iso8601
    }

    // MARK: - Token Management (Delegated)

    // Placeholder functions demonstrating delegation
    private func getToken() -> String? {
        return authTokenManager.getToken()
    }

    private func saveAuthData(token: String, expiresIn: String?, user: User) {
         authTokenManager.saveToken(token: token, expiresIn: expiresIn)
         // Consider saving user ID or full user object via AuthTokenManager or separate UserSession
         // authTokenManager.saveUserID(user.id)
         self.currentUser = user // Keep local cache for now
    }

    private func clearAuthData() {
        authTokenManager.clearToken()
        // authTokenManager.clearUserID()
        self.currentUser = nil
    }


    // MARK: - Health Check

    func checkApiHealth() async throws -> HealthResponse {
        return try await makeRequest(endpoint: "/health", method: "GET", requiresAuth: false)
    }

    // MARK: - Authentication

    func login(username: String, password: String) async throws -> User {
        let loginData = ["username": username, "password": password]
        let authResponse: AuthResponse = try await makeRequest(
            endpoint: "/login",
            method: "POST",
            body: loginData,
            requiresAuth: false,
            additionalHeaders: ["X-Client-Platform": "mobile"]
        )

        // Save token and user
        saveAuthData(token: authResponse.token, expiresIn: authResponse.expiresIn, user: authResponse.user)
        return authResponse.user
    }

    func register(username: String, password: String) async throws -> User {
        let registerData = ["username": username, "password": password]
         let authResponse: AuthResponse = try await makeRequest(
             endpoint: "/register",
             method: "POST",
             body: registerData,
             requiresAuth: false,
             additionalHeaders: ["X-Client-Platform": "mobile"]
         )

        // Save token and user
        saveAuthData(token: authResponse.token, expiresIn: authResponse.expiresIn, user: authResponse.user)
        return authResponse.user
    }

    func validateToken() async throws -> Bool {
        guard getToken() != nil else {
            return false
        }

        do {
            let _: User = try await makeRequest(endpoint: "/validate-token", method: "GET", requiresAuth: true)
            return true
        } catch let error as NetworkError where error == .unauthorized {
            clearAuthData()
            return false
        } catch {
            // Rethrow other errors
            throw error
        }
    }

    func logout() async throws {
         clearAuthData()
         // Optional: Call server-side logout endpoint, ignoring errors
         Task { // Fire and forget
             try? await makeRequest(endpoint: "/logout", method: "POST", requiresAuth: false, responseType: EmptyResponse.self)
         }
    }

    func getCurrentUser() async throws -> User {
        // If we have a cached user, return it
        if let user = currentUser {
            return user
        }

        // Otherwise fetch from API
        let user: User = try await makeRequest(endpoint: "/user", method: "GET", requiresAuth: true)
        self.currentUser = user // Update cache
        return user
    }

    // MARK: - User Location

    func updateUserLocation(latitude: Double, longitude: Double) async throws -> User {
        let locationData = ["latitude": latitude, "longitude": longitude]
        let user: User = try await makeRequest(endpoint: "/user/location", method: "POST", body: locationData, requiresAuth: true)
        self.currentUser = user // Update cache
        return user
    }

    // MARK: - Exercises (Public endpoints)

    func getExercises() async throws -> [Exercise] {
        return try await makeRequest(endpoint: "/exercises", method: "GET", requiresAuth: false)
    }

    func getExerciseById(id: Int) async throws -> Exercise {
        return try await makeRequest(endpoint: "/exercises/\\(id)", method: "GET", requiresAuth: false)
    }

    // MARK: - User Exercises (Protected endpoints)

    func getUserExercises() async throws -> [UserExercise] {
        return try await makeRequest(endpoint: "/user-exercises", method: "GET", requiresAuth: true)
    }

    func getUserExercisesByType(type: String) async throws -> [UserExercise] {
        return try await makeRequest(endpoint: "/user-exercises/\\(type)", method: "GET", requiresAuth: true)
    }

    func getLatestUserExercises() async throws -> [String: UserExercise] {
         return try await makeRequest(endpoint: "/user-exercises/latest/all", method: "GET", requiresAuth: true)
    }

    func createUserExercise(userExercise: CreateUserExerciseRequest) async throws -> UserExercise {
        return try await makeRequest(endpoint: "/user-exercises", method: "POST", body: userExercise, requiresAuth: true)
    }

    // MARK: - Leaderboard (Public endpoints)

    func getGlobalLeaderboard() async throws -> [LeaderboardEntry] {
        // Assuming LeaderboardEntry is defined in Data/Models/Leaderboard.swift
        // Might need adjustments based on actual backend response structure
        return try await makeRequest(endpoint: "/leaderboard/global", method: "GET", requiresAuth: false)
    }

    func getLocalLeaderboard(latitude: Double, longitude: Double, radiusMiles: Int = 5) async throws -> [LeaderboardEntry] {
        // Assuming LeaderboardEntry is defined in Data/Models/Leaderboard.swift
        let endpoint = "/leaderboard/local?latitude=\\(latitude)&longitude=\\(longitude)&radius=\\(radiusMiles)"
        return try await makeRequest(endpoint: endpoint, method: "GET", requiresAuth: false)
    }

    // MARK: - Sync Operations

    func syncUserData(deviceId: String) async throws -> SyncResponse {
        // Get the last sync timestamp, or use a default if this is the first sync
        // This logic should likely move to a dedicated SyncManager or Repository
        let lastSyncTimestamp = await getLastSyncTimestamp() // Placeholder for repository/sync manager call

        // Get any pending (unsynced) user exercises
        // This logic should live in a local data source/repository
        let unsyncedExercises = await getUnsyncedExercisesFromLocal() // Placeholder

        // Create the sync request
        let syncRequest = SyncRequest(
            deviceId: deviceId,
            lastSyncTimestamp: lastSyncTimestamp,
            data: SyncData(
                userExercises: unsyncedExercises,
                profile: nil // Profile updates might be handled separately
            )
        )

        let response: SyncResponse = try await makeRequest(endpoint: "/sync", method: "POST", body: syncRequest, requiresAuth: true)

        // Handle response: Save new timestamp, update local cache
        // This post-sync processing should also move to SyncManager/Repository
        await saveNewSyncTimestamp(response.timestamp) // Placeholder for repository/sync manager call

        if let exercises = response.data?.userExercises {
             await saveExercisesToLocalCache(exercises) // Placeholder
        }
        if let profile = response.data?.profile {
            self.currentUser = profile // Update local cache
             // Potentially notify AuthTokenManager or UserSession
        }

        return response
    }

    // Placeholder for fetching last sync timestamp - move to a repository/data source
    private func getLastSyncTimestamp() async -> String {
        // Implementation would fetch from a sync status store (UserDefaults, CoreData, etc.)
        // Managed by a dedicated sync component
        return "2000-01-01T00:00:00.000Z" // Default value
    }

    // Placeholder for saving new sync timestamp - move to a repository/data source
    private func saveNewSyncTimestamp(_ timestamp: String) async {
         // Implementation would save to a sync status store
    }

    // Placeholder for fetching local data - move to a repository/data source
    private func getUnsyncedExercisesFromLocal() async -> [CreateUserExerciseRequest] {
        // Implementation would fetch from CoreData or other local storage
        return []
    }

    // Placeholder for saving synced data - move to a repository/data source
    private func saveExercisesToLocalCache(_ exercises: [UserExercise]) async {
        // Implementation would save/update CoreData or other local storage
    }

    // MARK: - Profile Update
    func updateProfile(profileData: UpdateProfileRequest) async throws -> User {
         let user: User = try await makeRequest(endpoint: "/profile", method: "POST", body: profileData, requiresAuth: true)
         self.currentUser = user // Update cache
         return user
    }


    // MARK: - Generic Request Method (async/await)

    private func makeRequest<T: Decodable, B: Encodable>(
        endpoint: String,
        method: String,
        queryItems: [URLQueryItem]? = nil,
        body: B? = nil,
        requiresAuth: Bool = false,
        additionalHeaders: [String: String] = [:],
        responseType: T.Type = T.self // Keep explicit type for clarity
    ) async throws -> T {

        guard var urlComponents = URLComponents(url: baseURL.appendingPathComponent(endpoint), resolvingAgainstBaseURL: true) else {
            throw NetworkError.badURL
        }
        urlComponents.queryItems = queryItems // Add query items if any

        guard let url = urlComponents.url else {
             throw NetworkError.badURL
         }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept") // Prefer Accept header

        // Add Auth Token if required
        if requiresAuth {
            guard let token = getToken() else {
                // No token available for authenticated request
                throw NetworkError.unauthorized // Or a more specific .noToken error if defined
            }
            request.setValue("Bearer \\(token)", forHTTPHeaderField: "Authorization")
        }

        // Add any additional headers
        additionalHeaders.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        // Encode body if provided
        if let body = body {
            // Only set Content-Type if there is a body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            do {
                request.httpBody = try encoder.encode(body)
            } catch {
                // Log encoding error details
                print("Encoding error: \\(error)")
                throw NetworkError.requestFailed(error) // Or a specific encoding error type
            }
        }

        // Perform the request
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
             // Log network request error
             print("Network request error: \\(error)")
            // Map specific URLSession errors if needed (e.g., timeout, offline)
            throw NetworkError.requestFailed(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
             print("Invalid response: Not an HTTPURLResponse")
            throw NetworkError.invalidResponse(response)
        }

        // Log response status and potentially headers/body for debugging
        print("[\(method)] \(url.absoluteString) - Status: \(httpResponse.statusCode)")
        // print("Response Headers: \\(httpResponse.allHeaderFields)")
        // print("Response Body: \\(String(data: data, encoding: .utf8) ?? "<No Body or Non-UTF8>")")


        // Handle HTTP status codes
        switch httpResponse.statusCode {
        case 200...299:
            // Handle empty response (e.g., 204 No Content)
            if T.self == EmptyResponse.self {
                 // Ensure EmptyResponse is defined somewhere (e.g., Data/Models/Common.swift)
                 guard let empty = EmptyResponse() as? T else {
                     // This should ideally not happen if T is constrained correctly
                     throw NetworkError.decodingError(DecodingError.typeMismatch(T.self, DecodingError.Context(codingPath: [], debugDescription: "Could not cast EmptyResponse to expected type T")))
                 }
                 return empty
             }
            if data.isEmpty && !(T.self == EmptyResponse.self) {
                // Received empty data for a non-empty expected response type
                print("Warning: Received empty data for expected type \\(T.self)")
                 throw NetworkError.decodingError(DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Expected non-empty data but received empty.")))
            }

            // Decode successful response
            do {
                let decodedObject = try decoder.decode(T.self, from: data)
                return decodedObject
            } catch let decodingError as DecodingError {
                 // Provide detailed decoding error logging
                 print("Decoding error: \\(decodingError)")
                 Self.logDecodingErrorDetails(decodingError, data: data)
                 throw NetworkError.decodingError(decodingError)
             } catch {
                 print("Generic decoding error: \\(error)")
                 throw NetworkError.decodingError(error)
             }
        case 401: // Unauthorized
            // Clear token, potentially trigger re-login flow via notification/delegate
            if requiresAuth { // Only clear token if the failed request required auth
                 clearAuthData()
            }
            throw NetworkError.unauthorized
        case 403: // Forbidden
            // Often indicates lack of permissions even if authenticated
            // Decode potential error body
             let apiError = try? decoder.decode(APIErrorResponse.self, from: data)
             print("Forbidden (403): \\(apiError?.message ?? "No error message")")
             throw NetworkError.apiError(apiError ?? APIErrorResponse(error: "Forbidden", message: String(data: data, encoding: .utf8), code: 403)) // Create a default if decode fails

        case 404: // Not Found
            let apiError = try? decoder.decode(APIErrorResponse.self, from: data)
             print("Not Found (404): \\(apiError?.message ?? "No error message")")
             throw NetworkError.apiError(apiError ?? APIErrorResponse(error: "Not Found", message: String(data: data, encoding: .utf8), code: 404))

        case 400, 422: // Bad Request, Unprocessable Entity (often validation errors)
             do {
                 let apiError = try decoder.decode(APIErrorResponse.self, from: data)
                 print("API Error (\(httpResponse.statusCode)): \\(apiError.message ?? apiError.error)")
                 throw NetworkError.apiError(apiError)
             } catch let decodingError {
                 // Fallback if error response itself is not decodable
                 print("Failed to decode API error response (\(httpResponse.statusCode)): \\(decodingError)")
                 print("Raw error data: \\(String(data: data, encoding: .utf8) ?? "<invalid encoding>")")
                 // Create a generic error using the status code and raw data
                  let fallbackMessage = String(data: data, encoding: .utf8) ?? "Undecodable error response"
                  throw NetworkError.apiError(APIErrorResponse(error: "Server Error", message: fallbackMessage, code: httpResponse.statusCode))
             }

        case 500...599: // Server Errors
            let apiError = try? decoder.decode(APIErrorResponse.self, from: data)
            print("Server Error (\(httpResponse.statusCode)): \\(apiError?.message ?? "No error message")")
            throw NetworkError.apiError(apiError ?? APIErrorResponse(error: "Internal Server Error", message: String(data: data, encoding: .utf8), code: httpResponse.statusCode))


        default:
             print("Unhandled HTTP status code: \(httpResponse.statusCode)")
             // Attempt to decode as APIErrorResponse, otherwise use generic invalid response
             let apiError = try? decoder.decode(APIErrorResponse.self, from: data)
             if let apiError = apiError {
                 throw NetworkError.apiError(apiError)
             } else {
                 throw NetworkError.invalidResponse(httpResponse)
             }
        }
    }

    // Overload for requests without a request body
     private func makeRequest<T: Decodable>(
         endpoint: String,
         method: String,
         queryItems: [URLQueryItem]? = nil,
         requiresAuth: Bool = false,
         additionalHeaders: [String: String] = [:],
         responseType: T.Type = T.self
     ) async throws -> T {
         // Use a placeholder Encodable type like `EmptyBody` for the body parameter
         // Ensure EmptyBody is defined (e.g., in Data/Models/Common.swift)
         struct EmptyBody: Encodable {}
         return try await makeRequest(endpoint: endpoint, method: method, queryItems: queryItems, body: EmptyBody?.none, requiresAuth: requiresAuth, additionalHeaders: additionalHeaders, responseType: responseType)
     }

     // Overload for requests without a response body (e.g., POST/PUT returning 204)
     private func makeRequest<B: Encodable>(
         endpoint: String,
         method: String,
         queryItems: [URLQueryItem]? = nil,
         body: B? = nil,
         requiresAuth: Bool = false,
         additionalHeaders: [String: String] = [:]
     ) async throws {
         // Call the generic function expecting `EmptyResponse`
         // Ensure EmptyResponse is defined (e.g., in Data/Models/Common.swift)
         let _: EmptyResponse = try await makeRequest(endpoint: endpoint, method: method, queryItems: queryItems, body: body, requiresAuth: requiresAuth, additionalHeaders: additionalHeaders, responseType: EmptyResponse.self)
     }

    // Helper for logging decoding errors
    private static func logDecodingErrorDetails(_ error: DecodingError, data: Data) {
        print("--- Decoding Error Details ---")
        switch error {
        case .typeMismatch(let type, let context):
            print("Type mismatch for type \\(type) at path: \\(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
            print("Debug description: \\(context.debugDescription)")
        case .valueNotFound(let type, let context):
            print("Value not found for type \\(type) at path: \\(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
            print("Debug description: \\(context.debugDescription)")
        case .keyNotFound(let key, let context):
            print("Key not found: '\\(key.stringValue)' at path: \\(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
            print("Debug description: \\(context.debugDescription)")
        case .dataCorrupted(let context):
            print("Data corrupted at path: \\(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
            print("Debug description: \\(context.debugDescription)")
        @unknown default:
            print("Unknown decoding error: \\(error.localizedDescription)")
        }
        if let jsonString = String(data: data, encoding: .utf8) {
             print("Raw JSON data trying to be decoded: \\(jsonString)")
        } else {
             print("Raw data trying to be decoded was not valid UTF-8.")
        }
        print("-----------------------------")
    }
}

// Removed placeholder AuthTokenManager class

// Removed placeholder EmptyResponse struct

// Note: Ensure all referenced Models (User, Exercise, UserExercise, LeaderboardEntry,
// AuthResponse, HealthResponse, CreateUserExerciseRequest, SyncRequest, SyncData,
// SyncResponse, UpdateProfileRequest, EmptyResponse, EmptyBody) and Errors (NetworkError, APIErrorResponse)
// are correctly defined and accessible. You might need to adjust imports or use `@_exported import`. 