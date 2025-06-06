import Foundation
import Combine

@MainActor
class ProgressViewModel: ObservableObject {

    private let workoutService: WorkoutService
    private let keychainService: KeychainServiceProtocol

    @Published var workoutHistory: [UserExerciseRecord] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    init(workoutService: WorkoutService = WorkoutService(),
         keychainService: KeychainServiceProtocol = KeychainService()) {
        self.workoutService = workoutService
        self.keychainService = keychainService
        // Initial fetch when the ViewModel is created
        fetchHistory()
    }

    func fetchHistory() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                guard let token = try keychainService.loadToken() else {
                    print("ProgressViewModel: Cannot fetch history, user not authenticated.")
                    errorMessage = "Authentication required to view history."
                    isLoading = false
                    return
                }

                print("ProgressViewModel: Fetching workout history...")
                let history = try await workoutService.fetchWorkoutHistory(authToken: token)
                // Sort history by date, newest first and update published properties
                self.workoutHistory = history.sorted(by: { $0.createdAt > $1.createdAt })
                self.isLoading = false
                print("ProgressViewModel: Fetched and sorted \(self.workoutHistory.count) history records.")

            } catch let error as APIErrorResponse {
                 print("ProgressViewModel: Failed to fetch history (API Error): \(error.localizedDescription)")
                 errorMessage = "Failed to load history: \(error.localizedDescription)"
                 isLoading = false
            } catch let error as APIError {
                 print("ProgressViewModel: Failed to fetch history (Client Error): \(error.localizedDescription)")
                 errorMessage = "Failed to load history. Check connection."
                 isLoading = false
            } catch {
                 print("ProgressViewModel: Failed to fetch history (Unexpected Error): \(error.localizedDescription)")
                 errorMessage = "An unexpected error occurred while loading history."
                 isLoading = false
            }
        }
    }

    // Formatter for displaying dates in the history list
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium // e.g., "Oct 26, 2023"
        formatter.timeStyle = .short // e.g., "2:30 PM"
        return formatter
    }()

    func formattedDate(_ date: Date) -> String {
        return dateFormatter.string(from: date)
    }
} 