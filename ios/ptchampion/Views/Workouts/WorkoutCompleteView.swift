// ios/ptchampion/Views/Workouts/WorkoutCompleteView.swift

import SwiftUI
import SwiftData
import Charts // For SwiftUI Charts
import PTDesignSystem

// Helper struct for chart data to ensure Identifiable conformance for ForEach in Chart
struct RepChartData: Identifiable {
    let id: UUID // Use WorkoutDataPoint's ID
    let repNumber: Int
    let formQuality: Double // 0.0 to 1.0
}

struct WorkoutCompleteView: View {
    let result: WorkoutResultSwiftData?
    let exerciseGrader: AnyExerciseGraderBox // For additional feedback like lastFormIssue

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var repDetailsForChart: [RepChartData] = []
    @State private var isLoadingDetails: Bool = false
    @State private var fetchError: String? = nil

    var body: some View {
        NavigationView { // Wrap in NavigationView for a title and dismiss button
            VStack(spacing: AppTheme.GeneratedSpacing.large) {
                if let workoutResult = result {
                    Text("Workout Complete!")
                        .font(AppTheme.GeneratedTypography.heading(size: AppTheme.GeneratedTypography.heading1))
                        .foregroundColor(AppTheme.GeneratedColors.textPrimary)

                    Form {
                        Section("Summary") {
                            WorkoutCompletionInfoRow(label: "Exercise", value: workoutResult.exerciseType.capitalized)
                            WorkoutCompletionInfoRow(label: "Duration", value: formatDuration(workoutResult.durationSeconds))
                            WorkoutCompletionInfoRow(label: "Total Reps", value: "\(workoutResult.repCount)")
                            if let score = workoutResult.score {
                                WorkoutCompletionInfoRow(label: "Overall Score", value: String(format: "%.1f", score))
                            }
                            WorkoutCompletionInfoRow(label: "Avg. Form Quality", value: String(format: "%.0f%%", exerciseGrader.formQualityAverage * 100))
                            if let lastIssue = exerciseGrader.lastFormIssue, !lastIssue.isEmpty {
                                WorkoutCompletionInfoRow(label: "Last Form Tip", value: lastIssue, isVertical: true)
                            }
                        }

                        if isLoadingDetails {
                            Section("Rep Details") {
                                ProgressView("Loading rep details...")
                            }
                        } else if fetchError != nil {
                            Section("Rep Details") {
                                Text("Could not load rep details: \(fetchError!)")
                                    .foregroundColor(AppTheme.GeneratedColors.error)
                            }
                        } else if !repDetailsForChart.isEmpty {
                            Section("Form Quality per Rep") {
                                Chart(repDetailsForChart) {
                                    RuleMark(y: .value("Target Quality", 0.75))
                                        .foregroundStyle(AppTheme.GeneratedColors.success.opacity(0.5))
                                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                                    
                                    BarMark(
                                        x: .value("Rep", "Rep \($0.repNumber)"),
                                        y: .value("Quality", $0.formQuality)
                                    )
                                    .foregroundStyle($0.formQuality >= 0.75 ? AppTheme.GeneratedColors.success : AppTheme.GeneratedColors.warning)
                                }
                                .chartYScale(domain: 0...1)
                                .frame(height: 200)
                                .padding(.top)
                            }
                        } else {
                            Section("Rep Details"){
                                Text("No detailed rep data found for this session.")
                                    .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                            }
                        }
                    }
                } else {
                    // Handle case where workout result is nil (e.g., save failed)
                    Text("Workout Data Unavailable")
                        .font(AppTheme.GeneratedTypography.heading(size: AppTheme.GeneratedTypography.heading2))
                        .foregroundColor(AppTheme.GeneratedColors.error)
                    Text("There was an issue saving or loading the workout details.")
                        .font(AppTheme.GeneratedTypography.body(size: nil))
                        .multilineTextAlignment(.center)
                        .padding()
                }

                // Add a typed local variable to resolve ambiguity
                let primaryButtonStyle: PTButton.ExtendedStyle = .primary
                PTButton("Done", style: primaryButtonStyle) {
                    dismiss()
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .background(AppTheme.GeneratedColors.cream)
            .navigationTitle("Workout Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await fetchRepDetails()
            }
            .onDisappear {
                dismiss()
                print("WorkoutCompleteView disappeared - dismissing workout session")
            }
        }
    }

    private func fetchRepDetails() async {
        guard let workoutID = result?.id else {
            fetchError = "Workout session ID is missing."
            print("Failed to fetch rep details: Workout session ID is missing")
            return
        }
        
        isLoadingDetails = true
        fetchError = nil
        print("Fetching rep details for workout ID: \(workoutID)")

        let descriptor = FetchDescriptor<WorkoutDataPoint>(
            predicate: #Predicate { $0.workoutID == workoutID },
            sortBy: [SortDescriptor(\WorkoutDataPoint.timestamp)]
        )

        do {
            let dataPoints = try modelContext.fetch(descriptor)
            self.repDetailsForChart = dataPoints.map {
                RepChartData(id: $0.id, repNumber: $0.repNumber, formQuality: $0.formQuality)
            }
            if dataPoints.isEmpty {
                 print("No WorkoutDataPoint found for session \(workoutID.uuidString)")
            } else {
                 print("Found \(dataPoints.count) rep data points for workout")
            }
        } catch {
            print("Failed to fetch rep details: \(error)")
            fetchError = error.localizedDescription
        }
        isLoadingDetails = false
    }

    private func formatDuration(_ totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// Renamed from InfoRow to avoid conflict
struct WorkoutCompletionInfoRow: View {
    let label: String
    let value: String
    var isVertical: Bool = false

    var body: some View {
        if isVertical {
            VStack(alignment: .leading) {
                Text(label)
                    .font(AppTheme.GeneratedTypography.caption(size: nil))
                    .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                Text(value)
                    .font(AppTheme.GeneratedTypography.body(size: nil))
                    .foregroundColor(AppTheme.GeneratedColors.textPrimary)
            }
        } else {
            HStack {
                Text(label)
                    .font(AppTheme.GeneratedTypography.body(size: nil))
                    .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                Spacer()
                Text(value)
                    .font(AppTheme.GeneratedTypography.body(size: nil))
                    .foregroundColor(AppTheme.GeneratedColors.textPrimary)
            }
        }
    }
}

#if DEBUG
struct WorkoutCompleteView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a mock WorkoutResultSwiftData
        let mockResult = WorkoutResultSwiftData(
            id: UUID().uuidString,
            exerciseType: "Pushup",
            startTime: Date().addingTimeInterval(-60 * 5), // 5 minutes ago
            endTime: Date(),
            durationSeconds: 300,
            repCount: 25,
            score: 85.5
        )

        // Create a mock ExerciseGraderBox
        let mockGrader = WorkoutSessionPlaceholderGrader() // Using WorkoutSessionPlaceholderGrader instead of PlaceholderGrader
        mockGrader.repCount = 25
        mockGrader.formQualityAverage = 0.88
        mockGrader.lastFormIssue = "Elbows flared out on last rep."
        let mockGraderBox = AnyExerciseGraderBox(mockGrader)

        // Create some mock rep data points for the chart preview
        let mockRepDetails = [
            RepChartData(id: UUID(), repNumber: 1, formQuality: 0.9),
            RepChartData(id: UUID(), repNumber: 2, formQuality: 0.85),
            RepChartData(id: UUID(), repNumber: 3, formQuality: 0.92),
            RepChartData(id: UUID(), repNumber: 4, formQuality: 0.78),
            RepChartData(id: UUID(), repNumber: 5, formQuality: 0.80)
        ]
        
        // Create a mock model container and populate it for preview if needed for fetchRepDetails
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: WorkoutResultSwiftData.self, WorkoutDataPoint.self, configurations: config)
        
        // Insert the mock result so it can be "found" if view expects to fetch it by ID passed via result
        container.mainContext.insert(mockResult)
        
        // Insert mock WorkoutDataPoints linked to mockResult for chart preview
        if let workoutID = mockResult.id as? UUID { // Ensure UUID is extracted correctly
            mockRepDetails.forEach {
                let dp = WorkoutDataPoint(id: $0.id, exerciseName: "Pushup", repNumber: $0.repNumber, formQuality: $0.formQuality, workoutID: workoutID)
                container.mainContext.insert(dp)
            }
        }
        
        return WorkoutCompleteView(result: mockResult, exerciseGrader: mockGraderBox)
            .modelContainer(container) // Provide the mock container for the preview
            //.preferredColorScheme(.dark) // Example for theme testing
    }
}
#endif 