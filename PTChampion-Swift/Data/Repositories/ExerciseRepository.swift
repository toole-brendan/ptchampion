import Foundation

// Concrete implementation of the ExerciseRepositoryProtocol using APIClient.
class ExerciseRepository: ExerciseRepositoryProtocol {
    
    private let apiClient = APIClient.shared
    // TODO: Inject local data source (e.g., CoreData) if offline support is needed.
    
    func getExercises() async throws -> [Exercise] {
        return try await apiClient.getExercises()
    }
    
    func getExerciseById(id: Int) async throws -> Exercise {
        return try await apiClient.getExerciseById(id: id)
    }
    
    func getUserExercises() async throws -> [UserExercise] {
        return try await apiClient.getUserExercises()
    }
    
    func getUserExercisesByType(type: String) async throws -> [UserExercise] {
        return try await apiClient.getUserExercisesByType(type: type)
    }
    
    func getLatestUserExercises() async throws -> [String : UserExercise] {
        return try await apiClient.getLatestUserExercises()
    }
    
    func createUserExercise(userExerciseData: CreateUserExerciseRequest) async throws -> UserExercise {
        // TODO: Implement local saving first if offline support is required.
        // 1. Save locally with "pending sync" status.
        // 2. Attempt to sync with backend (here or in a separate sync process).
        // 3. Update local status upon successful sync.
        
        // For now, directly call the API.
        return try await apiClient.createUserExercise(userExercise: userExerciseData)
    }
    
    // --- Placeholder implementations for potential local cache/offline methods ---
    /*
    func saveUserExerciseLocally(exercise: UserExercise) {
        // Implementation using CoreData or another local store
    }
    
    func getUnsyncedUserExercises() -> [UserExercise] {
        // Implementation using CoreData or another local store
        return []
    }
    
    func markExercisesAsSynced(ids: [Int]) {
        // Implementation using CoreData or another local store
    }
     */
} 