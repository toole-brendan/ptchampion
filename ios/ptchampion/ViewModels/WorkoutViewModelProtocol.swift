import SwiftUI
import SwiftData

/// Common protocol for workout view models (camera-based and run-based)
protocol WorkoutViewModelProtocol: ObservableObject {
    /// The model context for storing workout data
    var modelContext: ModelContext? { get set }
    
    /// The completed workout result for navigation
    var completedWorkoutResult: WorkoutResultSwiftData? { get }
    
    /// The elapsed time formatted as a string
    var elapsedTimeFormatted: String { get }
    
    /// A method to start the workout
    func startWorkout()
    
    /// A method to stop the workout
    func stopWorkout()
    
    /// A method to clean up resources when the view disappears
    func cleanup()
}

// Default implementation for cleanup
extension WorkoutViewModelProtocol {
    func cleanup() {
        // Default implementation does nothing
    }
} 