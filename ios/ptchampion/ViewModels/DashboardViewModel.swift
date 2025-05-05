import SwiftUI
import SwiftData
import Foundation

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var lastScoreString: String = "-"
    @Published var weeklyReps: String = "-"
    @Published var monthlyWorkouts: String = "-"
    @Published var personalBest: String = "-"
    @Published var totalWorkouts: Int = 0
    @Published var nextPTTest: String = "-"
    
    private var modelContext: ModelContext?
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        refresh()
    }
    
    func refresh() {
        guard let modelContext = modelContext else { return }
        
        // Last score
        var lastScoreDescriptor = FetchDescriptor<WorkoutResultSwiftData>(
            predicate: #Predicate { $0.score != nil },
            sortBy: [SortDescriptor(\WorkoutResultSwiftData.startTime, order: .reverse)]
        )
        lastScoreDescriptor.fetchLimit = 1
        
        if let lastScoreResult = try? modelContext.fetch(lastScoreDescriptor).first,
           let score = lastScoreResult.score {
            lastScoreString = String(format: "%.0f%%", score)
        }
        
        // Weekly push-ups
        let calendar = Calendar.current
        let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        
        let weeklyPushUpsDescriptor = FetchDescriptor<WorkoutResultSwiftData>(
            predicate: #Predicate {
                $0.exerciseType == "pushup" &&
                $0.startTime >= oneWeekAgo
            }
        )
        
        if let pushUpResults = try? modelContext.fetch(weeklyPushUpsDescriptor) {
            let totalReps = pushUpResults.compactMap { $0.repCount }.reduce(0, +)
            weeklyReps = "\(totalReps)"
        }
        
        // Total workouts
        let allWorkoutsDescriptor = FetchDescriptor<WorkoutResultSwiftData>()
        if let workoutCount = try? modelContext.fetchCount(allWorkoutsDescriptor) {
            totalWorkouts = workoutCount
            monthlyWorkouts = "\(workoutCount)" // This is a placeholder; ideally filter by last 30 days
        }
        
        // Personal best (push-ups)
        var personalBestDescriptor = FetchDescriptor<WorkoutResultSwiftData>(
            predicate: #Predicate { $0.exerciseType == "pushup" },
            sortBy: [SortDescriptor(\WorkoutResultSwiftData.repCount, order: .reverse)]
        )
        personalBestDescriptor.fetchLimit = 1
        
        if let bestResult = try? modelContext.fetch(personalBestDescriptor).first,
           let reps = bestResult.repCount {
            personalBest = "\(reps) reps"
        }
        
        // Next PT test (placeholder - would connect to calendar or settings in real app)
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        let futureDate = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        nextPTTest = formatter.string(from: futureDate)
    }
    
    // Helper to get time of day greeting
    var timeOfDayGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Morning"
        case 12..<17: return "Afternoon"
        default: return "Evening"
        }
    }
} 