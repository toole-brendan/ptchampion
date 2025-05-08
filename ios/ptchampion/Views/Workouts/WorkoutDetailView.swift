import SwiftUI
import PTDesignSystem
import SwiftData

struct WorkoutDetailView: View {
    let workoutResult: WorkoutResultSwiftData
    @Environment(\.modelContext) private var modelContext
    
    @State private var isLongestRunPR: Bool = false
    @State private var isFastestOverallPacePR: Bool = false
    @State private var isHighestScorePR: Bool = false
    @State private var isMostRepsPR: Bool = false
    
    // Helper to format duration
    private func formatDuration(_ seconds: Int) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: TimeInterval(seconds)) ?? "00:00:00"
    }
    
    // Helper to format distance (assuming miles for now, can be enhanced)
    private func formatDistance(_ meters: Double?) -> String {
        guard let meters = meters, meters > 0 else { return "N/A" }
        let miles = meters * 0.000621371
        // TODO: Add user preference for km/miles here later
        return String(format: "%.2f miles", miles)
    }

    // Helper to format average pace
    private func formatPace(distanceMeters: Double?, durationSeconds: Int) -> String {
        guard let distanceMeters = distanceMeters, distanceMeters > 0, durationSeconds > 0 else { return "N/A" }
        
        // For now, assumes miles. TODO: Use user preference
        let distanceMiles = distanceMeters * 0.000621371
        let minutesPerMile = (Double(durationSeconds) / 60.0) / distanceMiles
        
        if minutesPerMile.isFinite && !minutesPerMile.isNaN && minutesPerMile > 0 {
            let paceMinutes = Int(minutesPerMile)
            let paceSeconds = Int((minutesPerMile - Double(paceMinutes)) * 60)
            return String(format: "%d:%02d /mile", paceMinutes, paceSeconds)
        } else {
            return "N/A"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            PTLabel("Workout Complete!", style: .heading)
                .padding(.bottom)

            WorkoutDetailInfoRow(label: "Type:", value: workoutResult.exerciseType.capitalized)
            WorkoutDetailInfoRow(label: "Duration:", value: formatDuration(workoutResult.durationSeconds))
            
            if workoutResult.exerciseType.lowercased() == "run" {
                WorkoutDetailInfoRow(label: "Distance:", value: formatDistance(workoutResult.distanceMeters))
                if isLongestRunPR { Text("🎉 Longest Run PR!").font(.caption).foregroundColor(.green).padding(.leading) }
                WorkoutDetailInfoRow(label: "Avg Pace:", value: formatPace(distanceMeters: workoutResult.distanceMeters, durationSeconds: workoutResult.durationSeconds))
                if isFastestOverallPacePR { Text("🎉 Fastest Overall Pace PR!").font(.caption).foregroundColor(.green).padding(.leading) }
            }
            
            if let score = workoutResult.score {
                WorkoutDetailInfoRow(label: "Score:", value: String(format: "%.1f", score))
                if isHighestScorePR { Text("🎉 Highest Score PR!").font(.caption).foregroundColor(.green).padding(.leading) }
            } else if workoutResult.exerciseType.lowercased() != "run" {
                WorkoutDetailInfoRow(label: "Score:", value: "N/A")
            }
            
            if let repCount = workoutResult.repCount {
                WorkoutDetailInfoRow(label: "Reps:", value: "\(repCount)")
                if isMostRepsPR { Text("🎉 Most Reps PR!").font(.caption).foregroundColor(.green).padding(.leading) }
            }
            
            // Placeholder for Badges
            PTLabel("Badges Earned:", style: .subheading)
                .padding(.top)
            Text("Coming Soon!")
                .font(.caption)
                .foregroundColor(.gray)
            
            Spacer()
            
            // Placeholder for Share Button
            PTButton(workoutResult.isPublic ? "Remove from Leaderboard" : "Make Public for Leaderboard", style: .secondary) {
                workoutResult.isPublic.toggle()
                do {
                    try modelContext.save()
                    print("Workout public status updated: \(workoutResult.isPublic)")
                } catch {
                    print("Failed to save workout public status: \(error)")
                    // Optionally revert toggle if save fails
                    // workoutResult.isPublic.toggle()
                }
            }
            .padding(.bottom)
        }
        .padding(AppTheme.GeneratedSpacing.contentPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(AppTheme.GeneratedColors.background.ignoresSafeArea())
        .navigationTitle("Workout Summary")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            checkPersonalRecords()
        }
    }
    
    private func checkPersonalRecords() {
        let currentExerciseType = workoutResult.exerciseType
        let currentWorkoutID = workoutResult.id
        
        // Create a predicate to filter by exercise type and exclude the current workout
        let predicate = #Predicate<WorkoutResultSwiftData> { result in
            result.exerciseType == currentExerciseType && result.id != currentWorkoutID
        }
        
        let descriptor = FetchDescriptor<WorkoutResultSwiftData>(predicate: predicate, sortBy: [SortDescriptor<WorkoutResultSwiftData>(\.endTime, order: .reverse)])
        
        do {
            let historicalWorkouts = try modelContext.fetch(descriptor)
            
            if historicalWorkouts.isEmpty {
                // If no historical workouts, current one is a PR by default for applicable metrics
                if workoutResult.distanceMeters != nil { isLongestRunPR = true }
                if workoutResult.distanceMeters != nil && workoutResult.durationSeconds > 0 { isFastestOverallPacePR = true } // Pace PR if it's the first run
                if workoutResult.score != nil { isHighestScorePR = true }
                if workoutResult.repCount != nil { isMostRepsPR = true }
                return
            }
            
            // Check for Run PRs
            if workoutResult.exerciseType.lowercased() == "run" {
                if let currentDistance = workoutResult.distanceMeters {
                    let maxHistoricalDistance = historicalWorkouts.compactMap { $0.distanceMeters }.max() ?? 0
                    if currentDistance > maxHistoricalDistance {
                        isLongestRunPR = true
                    }
                }
                
                // Fastest Overall Pace PR
                if let currentDistance = workoutResult.distanceMeters, currentDistance > 0, workoutResult.durationSeconds > 0 {
                    let currentPaceSecondsPerMeter = Double(workoutResult.durationSeconds) / currentDistance
                    var isBestPace = true
                    for pastWorkout in historicalWorkouts {
                        if let pastDistance = pastWorkout.distanceMeters, pastDistance > 0, pastWorkout.durationSeconds > 0 {
                            let pastPaceSecondsPerMeter = Double(pastWorkout.durationSeconds) / pastDistance
                            if currentPaceSecondsPerMeter >= pastPaceSecondsPerMeter { // Higher or equal value means slower or same pace
                                isBestPace = false
                                break
                            }
                        }
                    }
                    if isBestPace { isFastestOverallPacePR = true }
                } else if historicalWorkouts.allSatisfy({ $0.distanceMeters == nil || $0.durationSeconds == 0 }) {
                     // If no prior valid runs to compare pace, this is a PR for pace
                     isFastestOverallPacePR = true
                }
            }
            
            // Check for Score PR
            if let currentScore = workoutResult.score {
                let maxHistoricalScore = historicalWorkouts.compactMap { $0.score }.max() ?? -Double.infinity
                if currentScore > maxHistoricalScore {
                    isHighestScorePR = true
                }
            }
            
            // Check for Reps PR
            if let currentReps = workoutResult.repCount {
                let maxHistoricalReps = historicalWorkouts.compactMap { $0.repCount }.max() ?? 0
                if currentReps > maxHistoricalReps {
                    isMostRepsPR = true
                }
            }
            
        } catch {
            print("Failed to fetch historical workouts for PR check: \(error)")
        }
    }
}

// Helper view for consistent row display
// Renamed from InfoRow to avoid conflict
struct WorkoutDetailInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            PTLabel(label, style: .bodyBold)
            Spacer()
            PTLabel(value, style: .body)
        }
    }
}

#Preview {
    // Create a sample WorkoutResultSwiftData for the preview
    let sampleRun = WorkoutResultSwiftData(
        exerciseType: "run", 
        startTime: Date().addingTimeInterval(-3600), // 1 hour ago
        endTime: Date(), 
        durationSeconds: 3600, 
        repCount: nil, 
        score: nil, // Runs don't have a score in the current model, grade is for other exercises
        distanceMeters: 5000.0, // 5km
        isPublic: false
    )
    
    let samplePushups = WorkoutResultSwiftData(
        exerciseType: "pushup", 
        startTime: Date().addingTimeInterval(-600), // 10 mins ago
        endTime: Date(), 
        durationSeconds: 120, // 2 mins for the set
        repCount: 30, 
        score: 88.5, 
        distanceMeters: nil,
        isPublic: true
    )

    return NavigationView {
        // You can switch between sampleRun and samplePushups to test
        WorkoutDetailView(workoutResult: sampleRun)
    }
    .modelContainer(for: WorkoutResultSwiftData.self, inMemory: true) // Needed if WorkoutResultSwiftData uses @Model
} 