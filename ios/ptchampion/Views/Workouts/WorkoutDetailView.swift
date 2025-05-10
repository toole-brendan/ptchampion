import SwiftUI
import PTDesignSystem
import SwiftData
import Charts // Ensure Charts is imported

// Helper struct for detailed rep breakdown including phase
struct WorkoutRepDetailItem: Identifiable {
    let id: UUID
    let repNumber: Int
    let formQuality: Double
    let phase: String?
}

struct WorkoutDetailView: View {
    let workoutResult: WorkoutResultSwiftData
    @Environment(\.modelContext) private var modelContext
    
    @State private var isLongestRunPR: Bool = false
    @State private var isFastestOverallPacePR: Bool = false
    @State private var isHighestScorePR: Bool = false
    @State private var isMostRepsPR: Bool = false

    // State for rep details
    @State private var repChartDataItems: [RepChartData] = []
    @State private var repTextDetails: [WorkoutRepDetailItem] = []
    @State private var isLoadingRepDetails: Bool = false
    @State private var repDetailsError: String? = nil
    
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
        ScrollView(.vertical, showsIndicators: true) { // Add explicit parameters to resolve ambiguity
            VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.large) {
                PTLabel("Workout Summary", style: .heading)
                    .padding(.bottom, AppTheme.GeneratedSpacing.small)

                WorkoutDetailInfoRow(label: "Type:", value: workoutResult.exerciseType.capitalized)
                WorkoutDetailInfoRow(label: "Date:", value: workoutResult.startTime, style: .dateTime.month().day().year().hour().minute())
                WorkoutDetailInfoRow(label: "Duration:", value: formatDuration(workoutResult.durationSeconds))
                
                if workoutResult.exerciseType.lowercased() == "run" {
                    WorkoutDetailInfoRow(label: "Distance:", value: formatDistance(workoutResult.distanceMeters))
                    if isLongestRunPR { Text("🎉 Longest Run PR!").font(.caption).foregroundColor(.green).padding(.leading) }
                    WorkoutDetailInfoRow(label: "Avg Pace:", value: formatPace(distanceMeters: workoutResult.distanceMeters, durationSeconds: workoutResult.durationSeconds))
                    if isFastestOverallPacePR { Text("🎉 Fastest Overall Pace PR!").font(.caption).foregroundColor(.green).padding(.leading) }
                }
                
                if let score = workoutResult.score {
                    WorkoutDetailInfoRow(label: "Score:", value: String(format: "%.1f%%", score))
                    if isHighestScorePR { Text("🎉 Highest Score PR!").font(.caption).foregroundColor(.green).padding(.leading) }
                } else if workoutResult.exerciseType.lowercased() != "run" {
                    WorkoutDetailInfoRow(label: "Score:", value: "N/A")
                }
                
                if let repCount = workoutResult.repCount {
                    WorkoutDetailInfoRow(label: "Reps:", value: "\(repCount)")
                    if isMostRepsPR { Text("🎉 Most Reps PR!").font(.caption).foregroundColor(.green).padding(.leading) }
                }
                
                // Section for Rep-by-Rep Breakdown
                if workoutResult.exerciseType.lowercased() != "run" { // Only show for non-run exercises
                    Section {
                        PTLabel("Rep-by-Rep Breakdown", style: .subheading)
                            .padding(.top)

                        if isLoadingRepDetails {
                            ProgressView("Loading rep details...")
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                        } else if let errorMsg = repDetailsError {
                            Text("Could not load rep details: \(errorMsg)")
                                .foregroundColor(AppTheme.GeneratedColors.error)
                                .padding()
                        } else if !repChartDataItems.isEmpty {
                            PTLabel("Form Quality per Rep", style: .caption).padding(.top, AppTheme.GeneratedSpacing.small)
                            Chart(repChartDataItems) { item in
                                RuleMark(y: .value("Target Quality", 0.75))
                                    .foregroundStyle(AppTheme.GeneratedColors.success.opacity(0.5))
                                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                                
                                BarMark(
                                    x: .value("Rep", "Rep \(item.repNumber)"),
                                    y: .value("Quality", item.formQuality)
                                )
                                .foregroundStyle(item.formQuality >= 0.75 ? AppTheme.GeneratedColors.success : AppTheme.GeneratedColors.warning)
                            }
                            .chartYScale(domain: 0...1)
                            .frame(height: 150)
                            .padding(.vertical, AppTheme.GeneratedSpacing.small)
                            
                            Divider().padding(.vertical, AppTheme.GeneratedSpacing.small)
                            
                            PTLabel("Detailed Feedback per Rep", style: .caption).padding(.bottom, AppTheme.GeneratedSpacing.extraSmall)
                            ForEach(repTextDetails) { detail in
                                VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.extraSmall) {
                                    HStack {
                                        Text("Rep \(detail.repNumber):")
                                            .font(AppTheme.GeneratedTypography.bodyBold(size: nil))
                                        Spacer()
                                        Text("Quality: \(String(format: "%.0f%%", detail.formQuality * 100))")
                                            .font(AppTheme.GeneratedTypography.body(size: nil))
                                    }
                                    if let phase = detail.phase, !phase.isEmpty {
                                        Text("Feedback: \(phase)")
                                            .font(AppTheme.GeneratedTypography.caption(size: nil))
                                            .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                                    } else {
                                        Text("Feedback: N/A")
                                            .font(AppTheme.GeneratedTypography.caption(size: nil))
                                            .foregroundColor(AppTheme.GeneratedColors.textTertiary)
                                    }
                                }
                                .padding(.vertical, AppTheme.GeneratedSpacing.extraSmall)
                                if detail.id != repTextDetails.last?.id {
                                     Divider()
                                }
                            }
                        } else {
                            Text("No detailed rep data found for this session.")
                                .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                                .padding()
                        }
                    }
                }


                // Placeholder for Badges
                Section {
                    PTLabel("Badges Earned:", style: .subheading)
                        .padding(.top)
                    Text("Coming Soon!")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer() // Push button to bottom if content is short
                
                // Use a typed local variable to resolve ambiguity
                let secondaryButtonStyle: PTButton.ExtendedStyle = .secondary
                PTButton(workoutResult.isPublic ? "Set to Private" : "Set to Public (Leaderboard)", style: secondaryButtonStyle) {
                    workoutResult.isPublic.toggle()
                    // No explicit save here, assumes @Query handles it or it's saved elsewhere if needed persistently
                    // For explicit save:
                    // do {
                    //     try modelContext.save()
                    // } catch {
                    //     print("Failed to save workout public status: \(error)")
                    // }
                }
                .padding(.vertical, AppTheme.GeneratedSpacing.medium) // Ensure button has padding
            }
            .padding(AppTheme.GeneratedSpacing.contentPadding) // Overall padding for the VStack
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(AppTheme.GeneratedColors.background.ignoresSafeArea())
        .navigationTitle("Workout Details") // More specific title
        .navigationBarTitleDisplayMode(.inline)
        .task { // Use .task for async operations tied to view lifecycle
            await checkPersonalRecords()
            if workoutResult.exerciseType.lowercased() != "run" {
                 await fetchRepDetails()
            }
        }
    }
    
    private func fetchRepDetails() async {
        guard let workoutID = workoutResult.id as? UUID else { // Ensure workoutResult.id is treated as UUID
            repDetailsError = "Workout session ID is invalid."
            return
        }
        
        isLoadingRepDetails = true
        repDetailsError = nil

        let descriptor = FetchDescriptor<WorkoutDataPoint>(
            predicate: #Predicate { $0.workoutID == workoutID },
            sortBy: [SortDescriptor(\.timestamp)] // Sort by timestamp to maintain order
        )

        do {
            let dataPoints = try modelContext.fetch(descriptor)
            // Map to both chart data and text detail data
            self.repChartDataItems = dataPoints.map {
                RepChartData(id: $0.id, repNumber: $0.repNumber, formQuality: $0.formQuality)
            }
            self.repTextDetails = dataPoints.map {
                WorkoutRepDetailItem(id: $0.id, repNumber: $0.repNumber, formQuality: $0.formQuality, phase: $0.phase)
            }
            if dataPoints.isEmpty {
                 print("No WorkoutDataPoint found for session \(workoutID.uuidString)")
            }
        } catch {
            print("Failed to fetch rep details: \(error)")
            repDetailsError = error.localizedDescription
        }
        isLoadingRepDetails = false
    }
    
    private func checkPersonalRecords() async { // Mark as async if any part of it becomes async
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
struct WorkoutDetailInfoRow: View {
    let label: String
    let value: String
    var dateStyle: Date.FormatStyle? = nil // Optional Date.FormatStyle

    // Overloaded initializer for Date values
    init(label: String, value: Date, style: Date.FormatStyle = .dateTime.day().month().year().hour().minute()) {
        self.label = label
        self.value = value.formatted(style)
        self.dateStyle = style
    }
    
    // Original initializer for String values
    init(label: String, value: String) {
        self.label = label
        self.value = value
        self.dateStyle = nil
    }
    
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
    
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: WorkoutResultSwiftData.self, WorkoutDataPoint.self, configurations: config)
    
    // Insert mock WorkoutDataPoints for the pushup session for preview
    if let workoutID = samplePushups.id as? UUID {
        let mockDataPoints = [
            WorkoutDataPoint(id: UUID(), exerciseName: "pushup", repNumber: 1, formQuality: 0.9, phase: "Good start", workoutID: workoutID),
            WorkoutDataPoint(id: UUID(), exerciseName: "pushup", repNumber: 2, formQuality: 0.85, phase: "Elbows slightly flared", workoutID: workoutID),
            WorkoutDataPoint(id: UUID(), exerciseName: "pushup", repNumber: 3, formQuality: 0.70, phase: "Back arched", workoutID: workoutID)
        ]
        mockDataPoints.forEach { container.mainContext.insert($0) }
    }


    return NavigationView {
        // You can switch between sampleRun and samplePushups to test
        WorkoutDetailView(workoutResult: samplePushups)
    }
    .modelContainer(container)
} 