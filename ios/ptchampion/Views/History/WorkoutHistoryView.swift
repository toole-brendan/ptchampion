import SwiftUI
import SwiftData
import PTDesignSystem
import Foundation
import Charts

// Enhanced empty state view with military styling
struct EmptyHistoryDisplayView: View {
    let currentFilter: WorkoutFilter
    
    var body: some View {
        let specificFilterText = currentFilter == .all ? "Workouts" : currentFilter.rawValue
        let titleString = "No \(specificFilterText) Yet"
        let imageForEmptyState: Image
        
        if let customIcon = currentFilter.customIconName {
            imageForEmptyState = Image(customIcon)
        } else {
            imageForEmptyState = Image(systemName: currentFilter.systemImage)
        }
        
        return PTCard(style: .elevated) {
            VStack(spacing: AppTheme.GeneratedSpacing.medium) {
                imageForEmptyState
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(AppTheme.GeneratedColors.brassGold.opacity(0.6))
                    .padding(.top, AppTheme.GeneratedSpacing.medium)
                
                VStack(spacing: AppTheme.GeneratedSpacing.small) {
                    PTLabel(titleString, style: .heading)
                        .multilineTextAlignment(.center)
                    
                    PTLabel("Complete a workout to see your progress here!", style: .body)
                        .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.bottom, AppTheme.GeneratedSpacing.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, AppTheme.GeneratedSpacing.medium)
        }
        .padding(.horizontal, AppTheme.GeneratedSpacing.contentPadding)
        .padding(.vertical, AppTheme.GeneratedSpacing.medium)
    }
}

struct WorkoutHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var viewModel: WorkoutHistoryViewModel
    @State private var isShowingShareSheet = false
    @State private var shareText = ""
    @State private var selectedWorkout: WorkoutResultSwiftData?
    @State private var isEditMode: EditMode = .inactive
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                AppTheme.GeneratedColors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AppTheme.GeneratedSpacing.section) {
                        // Custom header to match Leaderboard style exactly
                        VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.small) {
                            Text("WORKOUT HISTORY")
                                .militaryMonospaced(size: AppTheme.GeneratedTypography.body)
                                .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                            
                            // Add subtitle caption similar to the Leaderboard
                            Text("Track your exercise progress")
                                .font(AppTheme.GeneratedTypography.body(size: AppTheme.GeneratedTypography.small))
                                .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                                .italic()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, AppTheme.GeneratedSpacing.contentPadding)
                        .padding(.top, 12) // Reduced padding to match Leaderboard
                        
                        // Filter bar component
                        ExerciseFilterBarView(filter: $viewModel.filter)
                        
                        // Streak cards component
                        WorkoutStreaksView(
                            currentStreak: viewModel.currentWorkoutStreak,
                            longestStreak: viewModel.longestWorkoutStreak
                        )
                        
                        // Progress chart component
                        WorkoutChartView(
                            chartData: viewModel.chartData,
                            chartYAxisLabel: viewModel.chartYAxisLabel,
                            filter: viewModel.filter
                        )
                        
                        // Workout history list section
                        workoutHistorySection
                    }
                    .padding(.bottom, AppTheme.GeneratedSpacing.section)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation {
                            isEditMode = isEditMode == .active ? .inactive : .active
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: isEditMode == .active ? "checkmark.circle.fill" : "pencil")
                            Text(isEditMode == .active ? "Done" : "Edit")
                        }
                    }
                    .tint(AppTheme.GeneratedColors.brassGold)
                }
            }
            .environment(\.editMode, $isEditMode)
            .sheet(isPresented: $isShowingShareSheet) {
                ActivityView(activityItems: [shareText])
            }
            .onAppear {
                viewModel.modelContext = modelContext
                Task {
                    await viewModel.fetchWorkouts()
                }
            }
        }
    }
    
    // Workout history list section
    private var workoutHistorySection: some View {
        VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.medium) {
            HStack {
                Text("WORKOUT HISTORY")
                    .militaryMonospaced(size: AppTheme.GeneratedTypography.small)
                    .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                    .padding(.horizontal, AppTheme.GeneratedSpacing.contentPadding)
                
                Spacer()
            }
            
            if viewModel.workoutsFiltered.isEmpty {
                EmptyHistoryDisplayView(currentFilter: viewModel.filter)
            } else {
                WorkoutHistoryList(
                    viewModel: viewModel,
                    onSelect: { workout in
                        selectedWorkout = workout.toWorkoutResult()
                    },
                    isEditable: isEditMode == .active
                )
            }
        }
        .navigationDestination(item: $selectedWorkout) { workout in
            WorkoutDetailView(workoutResult: workout)
        }
    }
    
    private func shareWorkout(result: WorkoutResultSwiftData) {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        
        var text = "PT Champion Workout: \(result.exerciseType.capitalized)\n"
        text += "Date: \(formatter.string(from: result.startTime))\n"
        text += "Duration: \(formatDuration(result.durationSeconds))\n"
        
        if let reps = result.repCount {
            text += "Reps: \(reps)\n"
        }
        
        if let score = result.score {
            text += "Score: \(Int(score))%\n"
        }
        
        if let distance = result.distanceMeters {
            let distanceMiles = distance * 0.000621371
            text += "Distance: \(String(format: "%.2f mi", distanceMiles))\n"
        }
        
        shareText = text
        isShowingShareSheet = true
    }
    
    private func formatDuration(_ duration: Int) -> String {
        let hours = duration / 3600
        let minutes = (duration % 3600) / 60
        let seconds = duration % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}

@MainActor
private func createSampleDataContainer() -> ModelContainer {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    do {
        let container = try ModelContainer(for: WorkoutResultSwiftData.self, configurations: config)

        let sampleRun = WorkoutResultSwiftData(exerciseType: "run", startTime: Date().addingTimeInterval(-3600), endTime: Date().addingTimeInterval(-100), durationSeconds: 2600, distanceMeters: 5012.5)
        let samplePushups = WorkoutResultSwiftData(exerciseType: "pushup", startTime: Date().addingTimeInterval(-86400), endTime: Date().addingTimeInterval(-86300), durationSeconds: 100, repCount: 25, score: 85.0)
        let sampleSitups = WorkoutResultSwiftData(exerciseType: "situp", startTime: Date().addingTimeInterval(-172800), endTime: Date().addingTimeInterval(-172750), durationSeconds: 50, repCount: 30)
        
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: today)!
        let fiveDaysAgo = calendar.date(byAdding: .day, value: -5, to: today)!

        container.mainContext.insert(sampleRun)
        container.mainContext.insert(samplePushups)
        container.mainContext.insert(sampleSitups)
        
        container.mainContext.insert(WorkoutResultSwiftData(exerciseType: "pushup", startTime: threeDaysAgo, endTime: threeDaysAgo, durationSeconds: 60, repCount: 10))
        container.mainContext.insert(WorkoutResultSwiftData(exerciseType: "situp", startTime: twoDaysAgo, endTime: twoDaysAgo, durationSeconds: 60, repCount: 10))
        container.mainContext.insert(WorkoutResultSwiftData(exerciseType: "pullup", startTime: yesterday, endTime: yesterday, durationSeconds: 60, repCount: 10))
        container.mainContext.insert(WorkoutResultSwiftData(exerciseType: "pushup", startTime: fiveDaysAgo, endTime: fiveDaysAgo, durationSeconds: 60, repCount: 10))

        return container
    } catch {
        fatalError("Failed to create model container for preview: \(error)")
    }
}

struct WorkoutHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        WorkoutHistoryView()
            .modelContainer(createSampleDataContainer())
    }
}

#Preview("Light Mode") {
    WorkoutHistoryView()
        .modelContainer(createSampleDataContainer())
        .environment(\.colorScheme, .light)
}

#Preview("Dark Mode") {
    WorkoutHistoryView()
        .modelContainer(createSampleDataContainer())
        .environment(\.colorScheme, .dark)
} 