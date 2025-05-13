import SwiftUI
import SwiftData
import Foundation

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var lastScoreString: String = "-"
    @Published var weeklyReps: String = "-"
    @Published var monthlyWorkouts: String = "0"
    @Published var personalBest: String = "-"
    @Published var totalWorkouts: Int = 0
    @Published var nextPTTest: String = "-"
    @Published var latestAchievement: String = ""
    
    @Published var lastScoreTrend: TrendDirection? = nil
    @Published var weeklyPushupTrend: TrendDirection? = nil
    
    private var modelContext: ModelContext?
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        refresh()
    }
    
    func refresh() {
        guard let modelContext = modelContext else { return }
        
        let now = Date()
        let calendar = Calendar.current
        
        // Define date ranges
        let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: now)!
        let oneMonthAgo = calendar.date(byAdding: .month, value: -1, to: now)!
        let startOfThisWeek = calendar.startOfDay(for: oneWeekAgo) // Actually 7 days ago, adjust if fiscal week needed
        let startOfPreviousWeek = calendar.date(byAdding: .day, value: -7, to: startOfThisWeek)!
        let endOfPreviousWeek = calendar.date(byAdding: .second, value: -1, to: startOfThisWeek)!

        // Fetch all workouts (consider optimizing if performance becomes an issue)
        let allWorkoutsDescriptor = FetchDescriptor<WorkoutResultSwiftData>(sortBy: [SortDescriptor(\WorkoutResultSwiftData.endTime, order: .reverse)])
        guard let allWorkouts = try? modelContext.fetch(allWorkoutsDescriptor) else { return }
        
        self.totalWorkouts = allWorkouts.count

        // Last Score and Trend
        let scoredWorkouts = allWorkouts.filter { $0.score != nil }.prefix(2).map { $0 } // Get up to 2 most recent scored
        if let latestScored = scoredWorkouts.first {
            self.lastScoreString = String(format: "%.0f", latestScored.score ?? 0)
            if scoredWorkouts.count > 1, let previousScored = scoredWorkouts.last {
                if latestScored.score! > previousScored.score! { self.lastScoreTrend = .up }
                else if latestScored.score! < previousScored.score! { self.lastScoreTrend = .down }
                else { self.lastScoreTrend = .neutral }
            } else {
                self.lastScoreTrend = nil // Not enough data for trend
            }
        } else {
            self.lastScoreString = "-"
            self.lastScoreTrend = nil
        }

        // Weekly Reps (Push-ups) and Trend
        let pushupPredicateThisWeek = #Predicate<WorkoutResultSwiftData> { $0.exerciseType == "pushup" && $0.endTime >= startOfThisWeek && $0.endTime <= now }
        let pushupsThisWeekDescriptor = FetchDescriptor<WorkoutResultSwiftData>(predicate: pushupPredicateThisWeek)
        let pushupsThisWeek = (try? modelContext.fetch(pushupsThisWeekDescriptor) ?? []
        let currentWeekReps = pushupsThisWeek.reduce(0) { $0 + ($1.repCount ?? 0) }
        self.weeklyReps = "\(currentWeekReps)"
        
        let pushupPredicatePreviousWeek = #Predicate<WorkoutResultSwiftData> { $0.exerciseType == "pushup" && $0.endTime >= startOfPreviousWeek && $0.endTime < startOfThisWeek } // Use < startOfThisWeek
        let pushupsPreviousWeekDescriptor = FetchDescriptor<WorkoutResultSwiftData>(predicate: pushupPredicatePreviousWeek)
        let pushupsPreviousWeek = (try? modelContext.fetch(pushupsPreviousWeekDescriptor) ?? []
        let previousWeekReps = pushupsPreviousWeek.reduce(0) { $0 + ($1.repCount ?? 0) }

        if !pushupsThisWeek.isEmpty || !pushupsPreviousWeek.isEmpty { // Only show trend if there's some data
            if currentWeekReps > previousWeekReps { self.weeklyPushupTrend = .up }
            else if currentWeekReps < previousWeekReps { self.weeklyPushupTrend = .down }
            else { self.weeklyPushupTrend = .neutral }
        } else {
            self.weeklyPushupTrend = nil
        }

        // Monthly workouts (last 30 days)
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date() ?? Date()
        let monthlyWorkoutsDescriptor = FetchDescriptor<WorkoutResultSwiftData>(
            predicate: #Predicate { $0.startTime >= thirtyDaysAgo }
        )
        if let monthlyCount = try? modelContext.fetchCount(monthlyWorkoutsDescriptor) {
            monthlyWorkouts = "\(monthlyCount)"
        } else {
            monthlyWorkouts = "0"
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
        let futureDate = Calendar.current.date(byAdding: .day, value: 30, to: Date() ?? Date()
        nextPTTest = formatter.string(from: futureDate)
        
        // Set latest achievement message
        updateLatestAchievement(currentWeekReps: currentWeekReps, previousWeekReps: previousWeekReps)
    }
    
    private func updateLatestAchievement(currentWeekReps: Int, previousWeekReps: Int) {
        if currentWeekReps > 0 {
            latestAchievement = "Completed \(weeklyReps) push-ups this week"
            
            // Add comparison to previous week if there's data
            if previousWeekReps > 0 && currentWeekReps > previousWeekReps {
                let improvement = currentWeekReps - previousWeekReps
                let percentImprovement = Double(improvement) / Double(previousWeekReps) * 100
                latestAchievement += String(format: " (%.0f%% increase)", percentImprovement)
            }
        } else {
            latestAchievement = "Start your first workout to track achievements"
        }
    }
    
    // Helper to get time of day greeting
    var timeOfDayGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date()
        switch hour {
        case 0..<12: return "Morning"
        case 12..<17: return "Afternoon"
        default: return "Evening"
        }
    }
} 