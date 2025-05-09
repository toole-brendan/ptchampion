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
    
    // New computed property for custom icon names
    var customIconName: String? {
        switch self {
        case .pushup: return "pushup"
        case .situp: return "situp"
        case .pullup: return "pullup"
        case .run: return "running" // Corresponds to your "running.imageset"
        default: return nil // .all and any future types without custom icons
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

// New dedicated view for displaying the empty state content
private struct EmptyHistoryDisplayView: View {
    let currentFilter: WorkoutFilter
    
    // Duplicating the helper method here for now, or it could be made more globally accessible
    @ViewBuilder
    private func emptyStateLabelView(image: Image, title: String) -> some View {
        VStack {
            image
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .foregroundColor(AppTheme.GeneratedColors.brassGold)
            PTLabel(title, style: .heading)
        }
    }
    
    var body: some View {
        let specificFilterText = currentFilter == .all ? "Workouts" : currentFilter.rawValue
        let titleString = "No \(specificFilterText) Yet"
        let imageForEmptyState: Image
        if let customIcon = currentFilter.customIconName {
            imageForEmptyState = Image(customIcon)
        } else {
            imageForEmptyState = Image(systemName: currentFilter.systemImage)
        }
        
        return emptyStateLabelView(image: imageForEmptyState, title: titleString)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
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

    // Filter workout results based on selected filter
    private var workoutResults: [WorkoutResultSwiftData] {
        if filter == .all {
            return allWorkoutResults
        } else {
            return allWorkoutResults.filter { $0.exerciseType == filter.exerciseTypeString }
        }
    }
    
    // Computed property to transform workout results into chartable data points
    /*
    private var chartData: [ChartableDataPoint] {
        workoutResults
            .compactMap { result -> ChartableDataPoint? in
                let date = result.startTime
                var value: Double? = nil
                
                switch filter {
                case .all:
                    return nil
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
    }
    */
    
    /*
    private var yAxisChartLabel: String {
        switch filter {
        case .all:
            return "N/A"
        case .run:
            return "Distance (km)"
        case .pushup, .situp, .pullup:
            if chartData.first?.value != nil {
                if chartData.contains(where: { $0.value > 50 }) {
                    return "Score"
                } else {
                    return "Reps"
                }
            }
            return "Value"
        }
    }
    */

    // Helper to get unique, sorted workout days for streak calculation
    /*
    private var uniqueSortedWorkoutDays: [Date] {
        allWorkoutResults // Use all results for global streaks
            .map { Calendar.current.startOfDay(for: $0.startTime) }
            .sorted() // Sort ascending first
            .reduce(into: [Date]()) { (uniqueDays, date) in // Then get unique
                if uniqueDays.last != date {
                    uniqueDays.append(date)
                }
            }
    }
    */

    /*
    var currentStreak: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let uniqueDaysSet = Set(uniqueSortedWorkoutDays)

        guard !uniqueDaysSet.isEmpty else { return 0 }

        var streak = 0
        var dateToFind = today

        // Check if today was a workout day, then count backwards
        if uniqueDaysSet.contains(dateToFind) {
            streak += 1
            dateToFind = calendar.date(byAdding: .day, value: -1, to: dateToFind)!
            while uniqueDaysSet.contains(dateToFind) {
                streak += 1
                dateToFind = calendar.date(byAdding: .day, value: -1, to: dateToFind)!
            }
        } else {
            // If today was not a workout day, check if yesterday was, then count backwards
            dateToFind = calendar.date(byAdding: .day, value: -1, to: dateToFind)! // yesterday
            if uniqueDaysSet.contains(dateToFind) {
                 streak += 1
                 dateToFind = calendar.date(byAdding: .day, value: -1, to: dateToFind)! // day before yesterday
                 while uniqueDaysSet.contains(dateToFind) {
                    streak += 1
                    dateToFind = calendar.date(byAdding: .day, value: -1, to: dateToFind)!
                }
            } else {
                // Neither today nor yesterday had workouts
                return 0
            }
        }
        return streak
    }

    var longestStreak: Int {
        let days = uniqueSortedWorkoutDays
        guard !days.isEmpty else { return 0 }

        var currentMaxStreak = 0
        var currentConsecutiveStreak = 0
        var previousDay: Date? = nil
        let calendar = Calendar.current

        for day in days {
            if let prev = previousDay {
                if calendar.isDate(day, inSameDayAs: calendar.date(byAdding: .day, value: 1, to: prev)!) {
                    currentConsecutiveStreak += 1
                } else {
                    currentMaxStreak = max(currentMaxStreak, currentConsecutiveStreak)
                    currentConsecutiveStreak = 1 // Reset for the new day
                }
            } else {
                currentConsecutiveStreak = 1 // Start of the first streak
            }
            previousDay = day
        }
        currentMaxStreak = max(currentMaxStreak, currentConsecutiveStreak) // Final check
        return currentMaxStreak
    }
    */
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.GeneratedColors.background.ignoresSafeArea()
                
                VStack(spacing: AppTheme.GeneratedSpacing.contentPadding) {
                    Picker("Filter", selection: $filter) {
                        ForEach(WorkoutFilter.allCases) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal, AppTheme.GeneratedSpacing.contentPadding)

                    // Restore Streak Cards using state variables
                    HStack(spacing: AppTheme.GeneratedSpacing.medium) {
                        PTCard {
                            VStack(alignment: .center, spacing: AppTheme.GeneratedSpacing.small) {
                                PTLabel("Current Streak", style: .caption)
                                PTLabel("\(currentWorkoutStreak) days", style: .subheading).fontWeight(.bold)
                            }
                            .padding(AppTheme.GeneratedSpacing.medium)
                            .frame(maxWidth: .infinity)
                        }
                        PTCard {
                            VStack(alignment: .center, spacing: AppTheme.GeneratedSpacing.small) {
                                PTLabel("Longest Streak", style: .caption)
                                PTLabel("\(longestWorkoutStreak) days", style: .subheading).fontWeight(.bold)
                            }
                            .padding(AppTheme.GeneratedSpacing.medium)
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal, AppTheme.GeneratedSpacing.contentPadding)
                    
                    // Conditional display: Empty state or List with results
                    let resultsAreEmpty = workoutResults.isEmpty // Use a local constant for the condition
                    if resultsAreEmpty {
                        // Use the new dedicated view for the empty state
                        EmptyHistoryDisplayView(currentFilter: filter)
                    } else {
                        List {
                            // Restore the ForEach loop
                            ForEach(workoutResults) { result in
                                // Remove NavigationLink, make row tappable
                                WorkoutHistoryRow(result: result)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        selectedWorkout = result
                                    }
                                // Restore swipe actions
                                .swipeActions(edge: .trailing) {
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
                                } // End swipeActions
                            } // End ForEach
                        } // End List
                        .listStyle(PlainListStyle())
                        .scrollContentBackground(.hidden)
                        // Add navigation destination modifier here
                        .navigationDestination(item: $selectedWorkout) { workout in
                            WorkoutDetailView(workoutResult: workout)
                        }
                    } // End conditional display
                    
                    // Restore chart section using state variables
                    if !currentChartData.isEmpty && filter != .all { // Use currentChartData
                        VStack(alignment: .leading) {
                             PTLabel.sized("Progress Over Time - \\(filter.rawValue)", style: .heading, size: .medium)
                                .padding(.leading, AppTheme.GeneratedSpacing.contentPadding)
                            Chart(currentChartData) { point in // Use currentChartData
                                LineMark(
                                    x: .value("Date", point.date),
                                    y: .value(currentYAxisLabel, point.value) // Use currentYAxisLabel
                                )
                                .foregroundStyle(AppTheme.GeneratedColors.primary)
                                
                                PointMark(
                                    x: .value("Date", point.date),
                                    y: .value(currentYAxisLabel, point.value) // Use currentYAxisLabel
                                )
                                .foregroundStyle(AppTheme.GeneratedColors.primary)
                                .symbolSize(CGSize(width: 8, height: 8))
                            }
                            .chartYScale(domain: 0...(currentChartData.compactMap { $0.value }.max() ?? 50.0)) // Use currentChartData
                            .chartXAxis {
                                AxisMarks(values: .automatic(desiredCount: 5)) { value in
                                    AxisGridLine()
                                    AxisTick()
                                    AxisValueLabel(format: .dateTime.month().day())
                                }
                            }
                            .frame(height: 200)
                            .padding(AppTheme.GeneratedSpacing.medium)
                            .background(AppTheme.GeneratedColors.cardBackground)
                            .cornerRadius(AppTheme.GeneratedRadius.card)
                        }
                        .padding(.horizontal, AppTheme.GeneratedSpacing.contentPadding)
                    } else if filter != .all { // If currentChartData is empty but filter is not .all
                         VStack(spacing: AppTheme.GeneratedSpacing.small) {
                             Image(systemName: "chart.line.downtrend.xyaxis")
                                 .font(.largeTitle)
                                 .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                             PTLabel("Not enough data to display chart.", style: .body)
                                 .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                         }
                         .frame(maxWidth: .infinity, minHeight: 200)
                         .padding(AppTheme.GeneratedSpacing.medium)
                         .background(AppTheme.GeneratedColors.cardBackground)
                         .cornerRadius(AppTheme.GeneratedRadius.card)
                         .padding(.horizontal, AppTheme.GeneratedSpacing.contentPadding)
                    }
                }
                .sheet(isPresented: $isShowingShareSheet) {
                    ActivityView(activityItems: [shareText])
                }
                // Add modifiers to trigger chart and streak updates
                .onChange(of: filter) { // Use specific iOS 17+ syntax if applicable
                    updateChartData()
                    // Streaks are global, no need to update on filter change
                }
                .onChange(of: workoutResults) { // Use specific iOS 17+ syntax if applicable
                     updateChartData()
                     updateStreaks() // Update streaks when results change
                }
                .onAppear {
                    updateChartData() // Initial calculation
                    updateStreaks() // Initial calculation
                }
            }
            .navigationTitle("Workout History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                EditButton()
                    .tint(AppTheme.GeneratedColors.brassGold)
            }
        }
    }

    // Helper function for the empty state label view
    @ViewBuilder
    private func emptyStateLabelView(image: Image, title: String) -> some View {
        VStack {
            image
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .foregroundColor(AppTheme.GeneratedColors.brassGold)
            PTLabel(title, style: .heading)
        }
    }

    // Helper function for the empty state description view
    @ViewBuilder
    private func emptyStateDescriptionView() -> some View {
        Text("Complete a workout to see your history here.")
            .font(AppTheme.GeneratedTypography.body(size: AppTheme.GeneratedTypography.body))
            .foregroundColor(AppTheme.GeneratedColors.textSecondary)
    }

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
        modelContext.delete(result)
    }
    
    private func deleteWorkout(at offsets: IndexSet) {
        offsets.forEach { index in
            let resultToDelete = workoutResults[index]
            modelContext.delete(resultToDelete)
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

#Preview("Workout Row") {
     let sampleRun = WorkoutResultSwiftData(exerciseType: "run", startTime: Date().addingTimeInterval(-3600), endTime: Date().addingTimeInterval(-100), durationSeconds: 2600, distanceMeters: 5012.5)
    WorkoutHistoryRow(result: sampleRun)
        .padding(AppTheme.GeneratedSpacing.contentPadding)
        .background(AppTheme.GeneratedColors.cardBackground)
        .cornerRadius(AppTheme.GeneratedRadius.card)
} 