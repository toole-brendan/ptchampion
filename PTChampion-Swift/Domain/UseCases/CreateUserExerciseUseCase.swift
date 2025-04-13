import Foundation

// Use case for creating a new user exercise record.
class CreateUserExerciseUseCase {
    private let exerciseRepository: ExerciseRepositoryProtocol
    
    init(exerciseRepository: ExerciseRepositoryProtocol) {
        self.exerciseRepository = exerciseRepository
    }
    
    // Executes the creation operation.
    // Takes the details needed to create the record.
    func execute(exerciseId: Int, 
                   type: String, 
                   repetitions: Int?, 
                   formScore: Int?, 
                   timeInSeconds: Int?, 
                   distance: Double?, 
                   grade: Int, 
                   metadata: [String: String]?, 
                   deviceId: String?) async throws -> UserExercise {
        
        // Construct the request object
        let request = CreateUserExerciseRequest(
            exerciseId: exerciseId,
            type: type,
            repetitions: repetitions,
            formScore: formScore,
            timeInSeconds: timeInSeconds,
            distance: distance,
            grade: grade,
            metadata: metadata,
            deviceId: deviceId,
            syncStatus: "pending" // Set initial sync status if saving locally first
        )
        
        // Call the repository method.
        // The repository handles potential local saving + backend sync.
        return try await exerciseRepository.createUserExercise(userExerciseData: request)
    }
} 