import Foundation

// Defines the contract for fetching exercise definitions and user exercise history.
protocol ExerciseRepositoryProtocol {
    // Fetches the list of all available exercise definitions from the backend.
    func getExercises() async throws -> [Exercise]
    
    // Fetches a specific exercise definition by its ID.
    func getExerciseById(id: Int) async throws -> Exercise
    
    // Fetches all exercise records logged by the current user.
    func getUserExercises() async throws -> [UserExercise]
    
    // Fetches user exercise records filtered by exercise type (e.g., "pushup").
    func getUserExercisesByType(type: String) async throws -> [UserExercise]
    
    // Fetches the most recent exercise record for each type logged by the current user.
    func getLatestUserExercises() async throws -> [String: UserExercise]
    
    // Creates a new exercise record for the current user.
    // Takes a request object containing the exercise details.
    func createUserExercise(userExerciseData: CreateUserExerciseRequest) async throws -> UserExercise
    
    // --- Potential Local Cache/Offline Operations ---
    // (Could be separated into a LocalExerciseDataSource protocol if complex)
    
    // func saveUserExerciseLocally(exercise: UserExercise)
    // func getUnsyncedUserExercises() -> [UserExercise]
    // func markExercisesAsSynced(ids: [Int])
} 