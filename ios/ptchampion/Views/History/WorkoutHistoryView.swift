import SwiftUI
import SwiftData
import PTDesignSystem
import Foundation
import Charts

enum WorkoutFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case pushup = "Push-Ups"
    case situp = "Sit-Ups"
    case pullup = "Pull-Ups"
    case run = "Run"
    
    var id: String { self.rawValue }
    
    var systemImage: String {
        switch self {
        case .all: return "figure.run.circle.fill"
        case .pushup: return "figure.strengthtraining.traditional"
        case .situp: return "figure.core.training"
        case .pullup: return "figure.strengthtraining.traditional"
        case .run: return "figure.run"
        }
    }
    
    // Custom icon names for exercise types
    var customIconName: String? {
        switch self {
        case .pushup: return "pushup"
        case .situp: return "situp"
        case .pullup: return "pullup"
        case .run: return "running"
        default: return nil
        }
    }
    
    // Convert to exercise type string used in database
    var exerciseTypeString: String? {
        switch self {
        case .all: return nil
        case .pushup: return "pushup"
        case .situp: return "situp"
        case .pullup: return "pullup"
        case .run: return "run"
        }
    }
}

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
    
    // Define the FetchDescriptor separately as a static property
    private static var queryDescriptor: FetchDescriptor<WorkoutResultSwiftData> {
        var descriptor = FetchDescriptor<WorkoutResultSwiftData>(sortBy: [SortDescriptor(\.startTime, order: .reverse)])
        return descriptor
    }
    
    // Use the static descriptor in the Query
    @Query(Self.queryDescriptor, animation: .default) private var allWorkoutResults: [WorkoutResultSwiftData]
    
    @State private var filter: WorkoutFilter = .all
    @State private var isShowingShareSheet = false
    @State private var shareText = ""
    @State private var selectedWorkout: WorkoutResultSwiftData? // State for navigation
    @State private var currentChartData: [ChartableDataPoint] = [] // State for chart data
    @State private var currentYAxisLabel: String = "" // State for chart label
    @State private var currentWorkoutStreak: Int = 0 // State for current streak
    @State private var longestWorkoutStreak: Int = 0 // State for longest streak
    @State private var isEditMode: EditMode = .inactive

    // Filter workout results based on selected filter
    private var workoutResults: [WorkoutResultSwiftData] {
        if filter == .all {
            return allWorkoutResults
        } else {
            return allWorkoutResults.filter { $0.exerciseType == filter.exerciseTypeString }
        }
    }
    
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
                        
                        // Custom exercise filter pills
                        exerciseFilterSection
                        
                        // Streak cards section
                        streakCardsSection
                        
                        // Progress chart section
                        progressChartSection
                        
                        // Workout history list
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
            .onChange(of: filter) { 
                updateChartData()
            }
            .onChange(of: workoutResults) { 
                updateChartData()
                updateStreaks()
            }
            .onAppear {
                updateChartData()
                updateStreaks()
            }
        }
    }
    
    // MARK: - UI Components
    
    // Exercise filter pills section
    private var exerciseFilterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.GeneratedSpacing.itemSpacing) {
                ForEach(WorkoutFilter.allCases) { filterOption in
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            filter = filterOption
                        }
                    } label: {
                        HStack(spacing: 6) {
                            if let customIcon = filterOption.customIconName {
                                Image(customIcon)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 16, height: 16)
                            } else {
                                Image(systemName: filterOption.systemImage)
                                    .font(.system(size: 12))
                            }
                            
                            Text(filterOption.rawValue)
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(filter == filterOption ? 
                                      AppTheme.GeneratedColors.primary : 
                                      AppTheme.GeneratedColors.cardBackground)
                                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                        )
                        .foregroundColor(filter == filterOption ? 
                                         AppTheme.GeneratedColors.textOnPrimary : 
                                         AppTheme.GeneratedColors.textPrimary)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding(.horizontal, AppTheme.GeneratedSpacing.contentPadding)
            .padding(.vertical, 4)
        }
    }
    
    // Streak cards section
    private var streakCardsSection: some View {
        HStack(spacing: AppTheme.GeneratedSpacing.medium) {
            // Current streak card
            PTCard(style: .elevated) {
                VStack(alignment: .center, spacing: AppTheme.GeneratedSpacing.small) {
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(AppTheme.GeneratedColors.brassGold)
                            .font(.system(size: 14))
                        
                        Text("Current Streak")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                    }
                    
                    Text("\(currentWorkoutStreak)")
                        .font(.system(size: 36, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                    
                    Text("days")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppTheme.GeneratedColors.textTertiary)
                        .offset(y: -5)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.GeneratedSpacing.medium)
            }
            
            // Longest streak card
            PTCard(style: .elevated) {
                VStack(alignment: .center, spacing: AppTheme.GeneratedSpacing.small) {
                    HStack(spacing: 6) {
                        Image(systemName: "crown.fill")
                            .foregroundColor(AppTheme.GeneratedColors.brassGold)
                            .font(.system(size: 14))
                        
                        Text("Longest Streak")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                    }
                    
                    Text("\(longestWorkoutStreak)")
                        .font(.system(size: 36, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                    
                    Text("days")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppTheme.GeneratedColors.textTertiary)
                        .offset(y: -5)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.GeneratedSpacing.medium)
            }
        }
        .padding(.horizontal, AppTheme.GeneratedSpacing.contentPadding)
    }
    
    // Progress chart section
    private var progressChartSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.medium) {
            if !currentChartData.isEmpty && filter != .all {
                Text("PROGRESS CHART")
                    .militaryMonospaced(size: AppTheme.GeneratedTypography.small)
                    .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                    .padding(.horizontal, AppTheme.GeneratedSpacing.contentPadding)
                
                PTCard(style: .elevated) {
                    VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.small) {
                        HStack {
                            Text(filter.rawValue)
                                .militaryMonospaced(size: AppTheme.GeneratedTypography.body)
                                .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                            
                            Spacer()
                            
                            Text(filter.rawValue)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppTheme.GeneratedColors.brassGold)
                        }
                        
                        Chart(currentChartData) { point in
                            LineMark(
                                x: .value("Date", point.date),
                                y: .value(currentYAxisLabel, point.value)
                            )
                            .foregroundStyle(AppTheme.GeneratedColors.brassGold)
                            .interpolationMethod(.catmullRom)
                            
                            PointMark(
                                x: .value("Date", point.date),
                                y: .value(currentYAxisLabel, point.value)
                            )
                            .foregroundStyle(AppTheme.GeneratedColors.brassGold)
                            .symbolSize(CGSize(width: 8, height: 8))
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading) { _ in
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 3]))
                                    .foregroundStyle(AppTheme.GeneratedColors.textTertiary.opacity(0.3))
                                AxisTick(stroke: StrokeStyle(lineWidth: 1))
                                    .foregroundStyle(AppTheme.GeneratedColors.textTertiary)
                                AxisValueLabel()
                                    .foregroundStyle(AppTheme.GeneratedColors.textSecondary)
                            }
                        }
                        .chartXAxis {
                            AxisMarks(values: .automatic(desiredCount: 5)) { value in
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 3]))
                                    .foregroundStyle(AppTheme.GeneratedColors.textTertiary.opacity(0.3))
                                AxisTick(stroke: StrokeStyle(lineWidth: 1))
                                    .foregroundStyle(AppTheme.GeneratedColors.textTertiary)
                                AxisValueLabel(format: .dateTime.month().day())
                                    .foregroundStyle(AppTheme.GeneratedColors.textSecondary)
                            }
                        }
                        .frame(height: 200)
                        .padding(.top, AppTheme.GeneratedSpacing.small)
                        
                        HStack {
                            Spacer()
                            
                            HStack(spacing: 4) {
                                Text("Y-Axis:")
                                    .font(.system(size: 12))
                                    .foregroundColor(AppTheme.GeneratedColors.textTertiary)
                                
                                Text(currentYAxisLabel)
                                    .militaryMonospaced(size: 12)
                                    .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                            }
                        }
                    }
                    .padding(AppTheme.GeneratedSpacing.contentPadding)
                }
            } else if filter != .all {
                // Empty chart state
                Text("PROGRESS CHART")
                    .militaryMonospaced(size: AppTheme.GeneratedTypography.small)
                    .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                    .padding(.horizontal, AppTheme.GeneratedSpacing.contentPadding)
                
                PTCard(style: .flat) {
                    VStack(spacing: AppTheme.GeneratedSpacing.medium) {
                        Image(systemName: "chart.line.downtrend.xyaxis")
                            .font(.system(size: 36))
                            .foregroundColor(AppTheme.GeneratedColors.textTertiary.opacity(0.6))
                        
                        VStack(spacing: AppTheme.GeneratedSpacing.small) {
                            Text("Not enough data to display chart")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                            
                            Text("Complete more \(filter.rawValue) workouts to see your progress")
                                .font(.system(size: 14))
                                .foregroundColor(AppTheme.GeneratedColors.textTertiary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 180)
                    .padding(AppTheme.GeneratedSpacing.contentPadding)
                }
            }
        }
        .padding(.horizontal, filter != .all ? 0 : AppTheme.GeneratedSpacing.contentPadding)
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
            
            if workoutResults.isEmpty {
                EmptyHistoryDisplayView(currentFilter: filter)
            } else {
                ForEach(workoutResults) { result in
                    PTCard(style: isEditMode == .active ? .highlight : .standard) {
                        HStack {
                            WorkoutHistoryRow(result: result)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    if isEditMode == .inactive {
                                        selectedWorkout = result
                                    }
                                }
                            
                            if isEditMode == .active {
                                Spacer()
                                
                                HStack(spacing: AppTheme.GeneratedSpacing.small) {
                                    Button {
                                        shareWorkout(result: result)
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
                                        deleteWorkout(result: result)
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
                        .padding(AppTheme.GeneratedSpacing.small)
                    }
                    .padding(.horizontal, AppTheme.GeneratedSpacing.contentPadding)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        if isEditMode == .inactive {
                            Button(role: .destructive) {
                                deleteWorkout(result: result)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            
                            Button {
                                shareWorkout(result: result)
                            } label: {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }
                            .tint(AppTheme.GeneratedColors.brassGold)
                        }
                    }
                }
                .navigationDestination(item: $selectedWorkout) { workout in
                    WorkoutDetailView(workoutResult: workout)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    // Function to calculate and update streaks
    private func updateStreaks() {
        // Calculate unique sorted workout days
        let uniqueDays = allWorkoutResults
            .map { Calendar.current.startOfDay(for: $0.startTime) }
            .sorted()
            .reduce(into: [Date]()) { (uniqueDays, date) in
                if uniqueDays.last != date {
                    uniqueDays.append(date)
                }
            }
        
        guard !uniqueDays.isEmpty else {
            currentWorkoutStreak = 0
            longestWorkoutStreak = 0
            return
        }
        
        let calendar = Calendar.current
        
        // Calculate Longest Streak
        var maxStreak = 0
        var currentConsStreak = 0
        var previousDay: Date? = nil
        
        for day in uniqueDays {
            if let prev = previousDay {
                if calendar.isDate(day, inSameDayAs: calendar.date(byAdding: .day, value: 1, to: prev)!) {
                    currentConsStreak += 1
                } else {
                    maxStreak = max(maxStreak, currentConsStreak)
                    currentConsStreak = 1 // Reset
                }
            } else {
                currentConsStreak = 1 // Start
            }
            previousDay = day
        }
        longestWorkoutStreak = max(maxStreak, currentConsStreak)
        
        // Calculate Current Streak
        let today = calendar.startOfDay(for: Date())
        let uniqueDaysSet = Set(uniqueDays)
        var currentStrk = 0
        var dateToFind = today

        if uniqueDaysSet.contains(dateToFind) {
            currentStrk += 1
            dateToFind = calendar.date(byAdding: .day, value: -1, to: dateToFind)!
            while uniqueDaysSet.contains(dateToFind) {
                currentStrk += 1
                dateToFind = calendar.date(byAdding: .day, value: -1, to: dateToFind)!
            }
        } else {
            dateToFind = calendar.date(byAdding: .day, value: -1, to: dateToFind)! // yesterday
            if uniqueDaysSet.contains(dateToFind) {
                 currentStrk += 1
                 dateToFind = calendar.date(byAdding: .day, value: -1, to: dateToFind)! // day before yesterday
                 while uniqueDaysSet.contains(dateToFind) {
                    currentStrk += 1
                    dateToFind = calendar.date(byAdding: .day, value: -1, to: dateToFind)!
                }
            }
        }
        currentWorkoutStreak = currentStrk
    }

    // Function to calculate and update chart data/label
    private func updateChartData() {
        let newChartData = workoutResults
            .compactMap { result -> ChartableDataPoint? in
                let date = result.startTime
                var value: Double? = nil
                
                switch filter {
                case .all: return nil
                case .run:
                    if let distance = result.distanceMeters, distance > 0 {
                        value = distance / 1000
                    }
                case .pushup, .situp, .pullup:
                    if let score = result.score, score > 0 {
                        value = score
                    } else if let reps = result.repCount, reps > 0 {
                        value = Double(reps)
                    }
                }
                
                if let val = value {
                    return ChartableDataPoint(date: date, value: val)
                }
                return nil
            }
            .sorted { $0.date < $1.date }
        currentChartData = newChartData

        // Calculate label based on new data and current filter
        var newYAxisLabel: String
        switch filter {
            case .all: newYAxisLabel = "N/A"
            case .run: newYAxisLabel = "Distance (km)"
            case .pushup, .situp, .pullup:
                if newChartData.first?.value != nil {
                     if newChartData.contains(where: { $0.value > 50 }) {
                         newYAxisLabel = "Score"
                     } else {
                         newYAxisLabel = "Reps"
                     }
                } else {
                    newYAxisLabel = "Value"
                }
        }
        currentYAxisLabel = newYAxisLabel
    }

    private func deleteWorkout(result: WorkoutResultSwiftData) {
        withAnimation {
            modelContext.delete(result)
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

// Custom button style for filter pills
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
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