import Foundation

// Use case for fetching the current user's exercise history.
class GetUserExerciseHistoryUseCase {
    private let exerciseRepository: ExerciseRepositoryProtocol
    
    init(exerciseRepository: ExerciseRepositoryProtocol) {
        self.exerciseRepository = exerciseRepository
    }
    
    // Executes the fetch operation.
    // TODO: Add parameters for filtering (by type, date range) or pagination if needed.
    func execute() async throws -> [UserExercise] {
        // Could add sorting logic here if desired (e.g., by date descending)
        let history = try await exerciseRepository.getUserExercises()
        return history.sorted { $0.createdAt ?? Date.distantPast > $1.createdAt ?? Date.distantPast }
    }
    
    // Example variant: Fetch history by type
    func execute(type: String) async throws -> [UserExercise] {
         guard !type.isEmpty else {
              throw NSError(domain: "GetUserExerciseHistoryUseCase", code: 1, userInfo: [NSLocalizedDescriptionKey: "Exercise type cannot be empty."])
         }
        let history = try await exerciseRepository.getUserExercisesByType(type: type)
        return history.sorted { $0.createdAt ?? Date.distantPast > $1.createdAt ?? Date.distantPast }
    }
} 