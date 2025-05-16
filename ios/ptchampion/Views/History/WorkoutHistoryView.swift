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
    
    // Add initialFilterType parameter with default value
    var initialFilterType: WorkoutFilter = .all
    
    var body: some View {
        // Replace ScreenContainer with a custom styled view matching the Dashboard style
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
                        // Custom styled header matching Dashboard
                        VStack(spacing: 16) {
                            Text("WORKOUT HISTORY")
                                .font(.system(size: 32, weight: .bold))
                                .tracking(2)
                                .foregroundColor(AppTheme.GeneratedColors.deepOps)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Rectangle()
                                .frame(width: 120, height: 1.5)
                                .foregroundColor(AppTheme.GeneratedColors.deepOps)
                            
                            Text("TRACK YOUR EXERCISE PROGRESS")
                                .font(.system(size: 16, weight: .regular))
                                .tracking(1.5)
                                .foregroundColor(AppTheme.GeneratedColors.deepOps)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            // Edit button
                            Button {
                                withAnimation {
                                    isEditMode = isEditMode == .active ? .inactive : .active
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: isEditMode == .active ? "checkmark.circle.fill" : "pencil")
                                        .font(.system(size: 14))
                                    Text(isEditMode == .active ? "DONE" : "EDIT HISTORY")
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .foregroundColor(AppTheme.GeneratedColors.brassGold)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .strokeBorder(AppTheme.GeneratedColors.brassGold, lineWidth: 1)
                                )
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 8)
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Group filter bar and streak cards as one logical dashboard header
                        VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.medium) {
                            // Filter bar component
                            ExerciseFilterBarView(filter: $viewModel.filter)
                            
                            // Streak cards component
                            WorkoutStreaksView(
                                currentStreak: viewModel.currentWorkoutStreak,
                                longestStreak: viewModel.longestWorkoutStreak
                            )
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
                                Text("WORKOUT HISTORY")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(AppTheme.GeneratedColors.brassGold)
                                    .padding(.bottom, 4)
                                
                                Rectangle()
                                    .frame(height: 1)
                                    .foregroundColor(AppTheme.GeneratedColors.brassGold.opacity(0.3))
                                    .padding(.bottom, 4)
                                
                                Text("YOUR EXERCISE RECORD")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(AppTheme.GeneratedColors.brassGold)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppTheme.GeneratedColors.deepOps)
                            .cornerRadius(8, corners: [.topLeft, .topRight])
                            
                            // History content with cream background 
                            VStack {
                                if viewModel.workoutsFiltered.isEmpty {
                                    // Empty state
                                    VStack(spacing: 20) {
                                        Image(systemName: "figure.run.circle")
                                            .font(.system(size: 32))
                                            .foregroundColor(AppTheme.GeneratedColors.brassGold)
                                            .padding()
                                            .background(
                                                Circle()
                                                    .fill(AppTheme.GeneratedColors.brassGold.opacity(0.1))
                                                    .frame(width: 80, height: 80)
                                            )
                                        
                                        Text("No Workouts Yet")
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundColor(AppTheme.GeneratedColors.deepOps)
                                        
                                        Text("Complete a workout to see your history here.")
                                            .font(.system(size: 16))
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal, 20)
                                        
                                        if viewModel.filter != .all {
                                            Text("Try changing your filter to see more results.")
                                                .font(.system(size: 14))
                                                .foregroundColor(.secondary)
                                                .padding(.top, 4)
                                        }
                                    }
                                    .padding(.vertical, 40)
                                    .frame(maxWidth: .infinity)
                                } else {
                                    // List of workouts
                                    ScrollView {
                                        LazyVStack(spacing: 8) {
                                            ForEach(Array(viewModel.workoutsFiltered.enumerated()), id: \.element.id) { index, workout in
                                                HStack {
                                                    // Workout row
                                                    WorkoutHistoryRowAdapter(workout: workout)
                                                        .contentShape(Rectangle())
                                                        .onTapGesture {
                                                            if !isEditMode.isEditing {
                                                                selectedWorkout = workout.toWorkoutResult()
                                                            }
                                                        }
                                                    
                                                    if isEditMode.isEditing {
                                                        Spacer()
                                                        
                                                        HStack(spacing: AppTheme.GeneratedSpacing.small) {
                                                            Button {
                                                                shareWorkout(result: workout.toWorkoutResult())
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
                                                                Task {
                                                                    await viewModel.deleteWorkout(id: workout.id)
                                                                }
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
                                                
                                                if index < viewModel.workoutsFiltered.count - 1 {
                                                    Divider()
                                                        .background(Color.gray.opacity(0.2))
                                                        .padding(.horizontal, 16)
                                                }
                                            }
                                        }
                                        .padding(.vertical, 8)
                                    }
                                    .refreshable {
                                        await viewModel.fetchWorkouts()
                                    }
                                }
                            }
                            .background(Color(hex: "#EDE9DB"))
                            .cornerRadius(8, corners: [.bottomLeft, .bottomRight])
                        }
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
                    .padding(AppTheme.GeneratedSpacing.contentPadding)
                }
            }
            .environment(\.editMode, $isEditMode)
            .sheet(isPresented: $isShowingShareSheet) {
                ActivityView(activityItems: [shareText])
            }
            .navigationDestination(item: $selectedWorkout) { workout in
                WorkoutDetailView(workoutResult: workout)
            }
            .onAppear {
                viewModel.modelContext = modelContext
                
                // Set initial filter when view appears
                if viewModel.filter == .all && initialFilterType != .all {
                    viewModel.filter = initialFilterType
                }
                
                Task {
                    await viewModel.fetchWorkouts()
                }
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