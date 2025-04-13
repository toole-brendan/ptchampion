import Foundation

// Use case for fetching the list of available exercise definitions.
class GetExercisesUseCase {
    private let exerciseRepository: ExerciseRepositoryProtocol
    
    init(exerciseRepository: ExerciseRepositoryProtocol) {
        self.exerciseRepository = exerciseRepository
    }
    
    // Executes the fetch operation.
    func execute() async throws -> [Exercise] {
        return try await exerciseRepository.getExercises()
    }
} 