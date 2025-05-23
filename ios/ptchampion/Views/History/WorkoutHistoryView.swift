import SwiftUI
import SwiftData
import PTDesignSystem
import Foundation
import Charts

struct WorkoutHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var viewModel: WorkoutHistoryViewModel
    @State private var isShowingShareSheet = false
    @State private var shareText = ""
    @State private var selectedWorkout: WorkoutResultSwiftData?
    @State private var isEditMode: EditMode = .inactive
    @State private var isViewActive = false
    
    // Add initialFilterType parameter with default value
    var initialFilterType: WorkoutFilter = .all
    
    var body: some View {
        // Replace ScreenContainer with custom view matching Dashboard style
        NavigationStack {
            ZStack {
                // Ambient Background Gradient
                RadialGradient(
                    gradient: Gradient(colors: [
                        AppTheme.GeneratedColors.background.opacity(0.9),
                        AppTheme.GeneratedColors.background
                    ]),
                    center: .center,
                    startRadius: 50,
                    endRadius: UIScreen.main.bounds.height * 0.6
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.medium) {
                        // Custom styled header matching WorkoutHistoryView
                        VStack(spacing: 16) {
                            Text("WORKOUT HISTORY")
                                .font(.system(size: 32, weight: .bold))
                                .tracking(2)
                                .foregroundColor(AppTheme.GeneratedColors.deepOps)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Rectangle()
                                .frame(width: 120, height: 1.5)
                                .foregroundColor(AppTheme.GeneratedColors.brassGold)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Text("TRACK YOUR EXERCISE PROGRESS")
                                .font(.system(size: 16, weight: .regular))
                                .tracking(1.5)
                                .foregroundColor(AppTheme.GeneratedColors.deepOps)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Group filter bar and streak cards as one logical dashboard header
                        VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.medium) {
                            // Filter bar component
                            ExerciseFilterBarView(filter: $viewModel.filter)
                            
                            // Updated streak cards with dashboard styling
                            HStack(spacing: 16) {
                                // Current streak card
                                VStack(alignment: .center, spacing: 12) {
                                    // Title at top
                                    Text("CURRENT STREAK")
                                        .militaryMonospaced(size: 12)
                                        .foregroundColor(AppTheme.GeneratedColors.deepOps.opacity(0.8))
                                        .lineLimit(1)
                                        .multilineTextAlignment(.center)
                                        .padding(.top, 4)
                                    
                                    // Icon centered in circle container
                                    ZStack {
                                        Circle()
                                            .fill(AppTheme.GeneratedColors.oliveMist.opacity(0.3))
                                            .frame(width: 60, height: 60)
                                        
                                        Image(systemName: "flame.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(AppTheme.GeneratedColors.deepOps)
                                    }
                                    
                                    // Streak value with days label
                                    VStack(spacing: 2) {
                                        Text("\(viewModel.currentWorkoutStreak)")
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundColor(AppTheme.GeneratedColors.deepOps)
                                        
                                        Text("days")
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.center)
                                    }
                                }
                                .padding(.vertical, 16)
                                .frame(maxWidth: .infinity)
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(
                                    color: Color.black.opacity(0.05),
                                    radius: 3,
                                    x: 0,
                                    y: 1
                                )
                                
                                // Longest streak card
                                VStack(alignment: .center, spacing: 12) {
                                    // Title at top
                                    Text("LONGEST STREAK")
                                        .militaryMonospaced(size: 12)
                                        .foregroundColor(AppTheme.GeneratedColors.deepOps.opacity(0.8))
                                        .lineLimit(1)
                                        .multilineTextAlignment(.center)
                                        .padding(.top, 4)
                                    
                                    // Icon centered in circle container
                                    ZStack {
                                        Circle()
                                            .fill(AppTheme.GeneratedColors.oliveMist.opacity(0.3))
                                            .frame(width: 60, height: 60)
                                        
                                        Image(systemName: "chart.line.uptrend.xyaxis")
                                            .font(.system(size: 24))
                                            .foregroundColor(AppTheme.GeneratedColors.deepOps)
                                    }
                                    
                                    // Streak value with days label
                                    VStack(spacing: 2) {
                                        Text("\(viewModel.longestWorkoutStreak)")
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundColor(AppTheme.GeneratedColors.deepOps)
                                        
                                        Text("days")
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.center)
                                    }
                                }
                                .padding(.vertical, 16)
                                .frame(maxWidth: .infinity)
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(
                                    color: Color.black.opacity(0.05),
                                    radius: 3,
                                    x: 0,
                                    y: 1
                                )
                            }
                        }
                        
                        // Progress chart component
                        if viewModel.filter != .all {
                            WorkoutChartView(
                                chartData: viewModel.chartData,
                                chartYAxisLabel: viewModel.chartYAxisLabel,
                                filter: viewModel.filter
                            )
                        }
                        
                        // Workout History section with dashboard-style container
                        VStack(alignment: .leading, spacing: 0) {
                            // Header styled like dashboard containers
                            VStack(alignment: .leading, spacing: 4) {
                                Text("TRAINING RECORD")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(AppTheme.GeneratedColors.brassGold)
                                    .padding(.bottom, 4)
                                
                                Rectangle()
                                    .frame(height: 1)
                                    .foregroundColor(AppTheme.GeneratedColors.brassGold.opacity(0.3))
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppTheme.GeneratedColors.deepOps)
                            .cornerRadius(8, corners: [.topLeft, .topRight])
                            
                            // History content with white background instead of cream
                            VStack {
                                if viewModel.workoutsFiltered.isEmpty {
                                    // Empty state with updated styling to match chart empty state
                                    VStack(spacing: 20) {
                                        Image(systemName: "figure.run.circle")
                                            .font(.system(size: 36))
                                            .foregroundColor(AppTheme.GeneratedColors.brassGold)
                                            .padding()
                                            .background(
                                                Circle()
                                                    .fill(AppTheme.GeneratedColors.brassGold.opacity(0.1))
                                                    .frame(width: 80, height: 80)
                                            )
                                        
                                        Text("NO WORKOUTS YET")
                                            .militaryMonospaced(size: 14)
                                            .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                                            .fontWeight(.medium)
                                        
                                        Text("COMPLETE A WORKOUT TO SEE YOUR HISTORY HERE")
                                            .militaryMonospaced(size: 12)
                                            .foregroundColor(AppTheme.GeneratedColors.textTertiary)
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal, 20)
                                        
                                        if viewModel.filter != .all {
                                            Text("TRY CHANGING YOUR FILTER TO SEE MORE RESULTS")
                                                .militaryMonospaced(size: 12)
                                                .foregroundColor(AppTheme.GeneratedColors.textTertiary)
                                                .multilineTextAlignment(.center)
                                                .padding(.top, 4)
                                        }
                                    }
                                    .padding(.vertical, 40)
                                    .frame(maxWidth: .infinity)
                                } else {
                                    // Simplified list of workouts - removed LazyVStack for better performance
                                    VStack(spacing: 8) {
                                        ForEach(Array(viewModel.workoutsFiltered.enumerated()), id: \.element.id) { index, workout in
                                            WorkoutRowView(
                                                workout: workout,
                                                index: index,
                                                isEditMode: isEditMode,
                                                totalCount: viewModel.workoutsFiltered.count,
                                                onTap: { 
                                                    if !isEditMode.isEditing {
                                                        selectedWorkout = workout.toWorkoutResult()
                                                    }
                                                },
                                                onShare: { shareWorkout(result: workout.toWorkoutResult()) },
                                                onDelete: { 
                                                    Task {
                                                        await viewModel.deleteWorkout(id: workout.id)
                                                    }
                                                }
                                            )
                                        }
                                    }
                                    .padding(.vertical, 8)
                                }
                            }
                            .background(Color.white)
                            .cornerRadius(8, corners: [.bottomLeft, .bottomRight])
                        }
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
                    .padding(AppTheme.GeneratedSpacing.contentPadding)
                }
                .refreshable {
                    if isViewActive {
                        await viewModel.fetchWorkouts()
                    }
                }
            }
            .contentContainer()
            .environment(\.editMode, $isEditMode)
            .sheet(isPresented: $isShowingShareSheet) {
                ActivityView(activityItems: [shareText])
            }
            .navigationDestination(item: $selectedWorkout) { workout in
                WorkoutDetailView(workoutResult: workout)
            }
            .onAppear {
                isViewActive = true
                viewModel.modelContext = modelContext
                
                // Set initial filter when view appears
                if viewModel.filter == .all && initialFilterType != .all {
                    viewModel.filter = initialFilterType
                }
                
                Task {
                    await viewModel.fetchWorkouts()
                }
            }
            .onDisappear {
                isViewActive = false
                // Cancel any pending operations when switching away from this tab
                viewModel.cancelPendingOperations()
            }
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

// Simplified WorkoutRowView component
struct WorkoutRowView: View {
    let workout: WorkoutHistory
    let index: Int
    let isEditMode: EditMode
    let totalCount: Int
    let onTap: () -> Void
    let onShare: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            // Workout row
            WorkoutHistoryRowAdapter(workout: workout)
                .contentShape(Rectangle())
                .onTapGesture {
                    onTap()
                }
            
            if isEditMode.isEditing {
                Spacer()
                
                HStack(spacing: AppTheme.GeneratedSpacing.small) {
                    Button {
                        onShare()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(AppTheme.GeneratedColors.brassGold)
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(AppTheme.GeneratedColors.brassGold.opacity(0.1))
                            )
                    }
                    
                    Button {
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(AppTheme.GeneratedColors.error)
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(AppTheme.GeneratedColors.error.opacity(0.1))
                            )
                    }
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color.clear)
        
        if index < totalCount - 1 {
            Divider()
                .background(Color.gray.opacity(0.2))
                .padding(.horizontal, 16)
        }
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