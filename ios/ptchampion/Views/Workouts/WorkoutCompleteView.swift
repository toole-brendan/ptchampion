// ios/ptchampion/Views/Workouts/WorkoutCompleteView.swift

import SwiftUI
import SwiftData
import Charts
import PTDesignSystem

// Helper struct for chart data to ensure Identifiable conformance for ForEach in Chart
struct RepChartData: Identifiable {
    let id: UUID
    let repNumber: Int
    let formQuality: Double // 0.0 to 1.0
}

// Metric Card Component
struct MetricCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let iconName: String
    let color: Color
    
    init(title: String, value: String, subtitle: String? = nil, iconName: String, color: Color = AppTheme.GeneratedColors.deepOps) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.iconName = iconName
        self.color = color
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 12) {
            // Icon in circle
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: iconName)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(color)
            }
            
            // Value and title
            VStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppTheme.GeneratedColors.deepOps)
                
                Text(title)
                    .militaryMonospaced(size: 11)
                    .foregroundColor(AppTheme.GeneratedColors.deepOps.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 10))
                        .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct WorkoutCompleteView: View {
    let result: WorkoutResultSwiftData?
    let exerciseGrader: AnyExerciseGraderBox

    @EnvironmentObject var tabBarVisibility: TabBarVisibilityManager
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var repDetailsForChart: [RepChartData] = []
    @State private var isLoadingDetails: Bool = false
    @State private var fetchError: String? = nil
    
    // Animation states
    @State private var headerVisible = false
    @State private var metricsVisible = false
    @State private var chartVisible = false
    @State private var buttonsVisible = false
    @State private var celebrationVisible = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient matching dashboard
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
                    VStack(spacing: AppTheme.GeneratedSpacing.large) {
                        if let workoutResult = result {
                            // Celebration Header
                            celebrationHeaderView()
                                .opacity(headerVisible ? 1 : 0)
                                .offset(y: headerVisible ? 0 : -20)
                            
                            // Performance Metrics
                            performanceMetricsView(workoutResult: workoutResult)
                                .opacity(metricsVisible ? 1 : 0)
                                .offset(y: metricsVisible ? 0 : 20)
                            
                            // Form Feedback Section
                            if let lastIssue = exerciseGrader.lastFormIssue, !lastIssue.isEmpty {
                                formFeedbackView(feedback: lastIssue)
                                    .opacity(metricsVisible ? 1 : 0)
                                    .offset(y: metricsVisible ? 0 : 20)
                            }
                            
                            // Rep Analysis Chart
                            repAnalysisChartView()
                                .opacity(chartVisible ? 1 : 0)
                                .offset(y: chartVisible ? 0 : 20)
                            
                        } else {
                            // Error state
                            errorStateView()
                        }
                        
                        // Action buttons
                        actionButtonsView()
                            .opacity(buttonsVisible ? 1 : 0)
                            .offset(y: buttonsVisible ? 0 : 20)
                        
                        Spacer(minLength: 20)
                    }
                    .padding(AppTheme.GeneratedSpacing.contentPadding)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                tabBarVisibility.hideTabBar()
                animateContentIn()
                Task {
                    await fetchRepDetails()
                }
            }
            .onDisappear {
                tabBarVisibility.showTabBar()
            }
        }
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private func celebrationHeaderView() -> some View {
        VStack(spacing: 24) {
            // Success checkmark with animation
            ZStack {
                Circle()
                    .fill(AppTheme.GeneratedColors.success.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(AppTheme.GeneratedColors.success)
                    .scaleEffect(celebrationVisible ? 1.2 : 0.8)
                    .animation(.spring(response: 0.6, dampingFraction: 0.6), value: celebrationVisible)
            }
            
            VStack(spacing: 16) {
                Text("WORKOUT COMPLETE!")
                    .font(.system(size: 32, weight: .heavy))
                    .tracking(2)
                    .foregroundColor(AppTheme.GeneratedColors.deepOps)
                    .multilineTextAlignment(.center)
                
                Rectangle()
                    .frame(width: 120, height: 2)
                    .foregroundColor(AppTheme.GeneratedColors.brassGold)
                
                Text("MISSION ACCOMPLISHED")
                    .font(.system(size: 16, weight: .medium))
                    .tracking(1.5)
                    .foregroundColor(AppTheme.GeneratedColors.brassGold)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 40)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                celebrationVisible = true
            }
        }
    }
    
    @ViewBuilder
    private func performanceMetricsView(workoutResult: WorkoutResultSwiftData) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header section
            VStack(alignment: .leading, spacing: 4) {
                Text("PERFORMANCE METRICS")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppTheme.GeneratedColors.brassGold)
                    .padding(.bottom, 4)
                
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(AppTheme.GeneratedColors.brassGold.opacity(0.3))
                    .padding(.bottom, 4)
                
                Text("YOUR WORKOUT RESULTS AND PERFORMANCE DATA")
                    .militaryMonospaced(size: 12)
                    .foregroundColor(AppTheme.GeneratedColors.brassGold)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.GeneratedColors.deepOps)
            
            // Metrics content
            VStack(spacing: 16) {
                // 2x2 Grid of metrics
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 12) {
                    MetricCard(
                        title: "EXERCISE TYPE",
                        value: workoutResult.exerciseType.capitalized,
                        iconName: getExerciseIcon(workoutResult.exerciseType),
                        color: AppTheme.GeneratedColors.deepOps
                    )
                    
                    MetricCard(
                        title: "DURATION",
                        value: formatDuration(workoutResult.durationSeconds),
                        iconName: "timer",
                        color: AppTheme.GeneratedColors.deepOps
                    )
                    
                    MetricCard(
                        title: "TOTAL REPS",
                        value: "\(workoutResult.repCount ?? 0)",
                        iconName: "number",
                        color: AppTheme.GeneratedColors.deepOps
                    )
                    
                    MetricCard(
                        title: "FORM QUALITY",
                        value: String(format: "%.0f%%", exerciseGrader.formQualityAverage * 100),
                        iconName: "target",
                        color: getFormQualityColor(exerciseGrader.formQualityAverage)
                    )
                }
                
                // Overall score card (full width)
                if let score = workoutResult.score {
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "trophy.fill")
                                .font(.system(size: 24))
                                .foregroundColor(AppTheme.GeneratedColors.brassGold)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("OVERALL SCORE")
                                    .militaryMonospaced(size: 14)
                                    .foregroundColor(AppTheme.GeneratedColors.deepOps)
                                
                                Text(String(format: "%.1f", score))
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(AppTheme.GeneratedColors.deepOps)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text(getScoreInterpretation(score))
                                    .militaryMonospaced(size: 12)
                                    .foregroundColor(getScoreColor(score))
                                    .fontWeight(.medium)
                                
                                Text("GRADE")
                                    .militaryMonospaced(size: 10)
                                    .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                            }
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                }
            }
            .padding(16)
            .background(AppTheme.GeneratedColors.creamDark)
        }
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    @ViewBuilder
    private func formFeedbackView(feedback: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header section
            VStack(alignment: .leading, spacing: 4) {
                Text("FORM IMPROVEMENT")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppTheme.GeneratedColors.brassGold)
                    .padding(.bottom, 4)
                
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(AppTheme.GeneratedColors.brassGold.opacity(0.3))
                    .padding(.bottom, 4)
                
                Text("TECHNIQUE FEEDBACK AND RECOMMENDATIONS")
                    .militaryMonospaced(size: 12)
                    .foregroundColor(AppTheme.GeneratedColors.brassGold)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.GeneratedColors.deepOps)
            
            // Feedback content
            HStack(alignment: .top, spacing: 16) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(AppTheme.GeneratedColors.warning)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("TECHNIQUE TIP")
                        .militaryMonospaced(size: 12)
                        .foregroundColor(AppTheme.GeneratedColors.deepOps)
                        .fontWeight(.medium)
                    
                    Text(feedback)
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.GeneratedColors.deepOps)
                        .lineLimit(nil)
                }
                
                Spacer()
            }
            .padding(16)
            .background(Color.white)
        }
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    @ViewBuilder
    private func repAnalysisChartView() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header section
            VStack(alignment: .leading, spacing: 4) {
                Text("REP ANALYSIS")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppTheme.GeneratedColors.brassGold)
                    .padding(.bottom, 4)
                
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(AppTheme.GeneratedColors.brassGold.opacity(0.3))
                    .padding(.bottom, 4)
                
                Text("FORM QUALITY THROUGHOUT YOUR WORKOUT")
                    .militaryMonospaced(size: 12)
                    .foregroundColor(AppTheme.GeneratedColors.brassGold)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.GeneratedColors.deepOps)
            
            // Chart content
            VStack {
                if isLoadingDetails {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("ANALYZING REPS...")
                            .militaryMonospaced(size: 12)
                            .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                    }
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                } else if let error = fetchError {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 32))
                            .foregroundColor(AppTheme.GeneratedColors.error)
                        
                        Text("ANALYSIS UNAVAILABLE")
                            .militaryMonospaced(size: 12)
                            .foregroundColor(AppTheme.GeneratedColors.error)
                        
                        Text(error)
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                } else if !repDetailsForChart.isEmpty {
                    Chart(repDetailsForChart) { data in
                        // Target line
                        RuleMark(y: .value("Target Quality", 0.75))
                            .foregroundStyle(AppTheme.GeneratedColors.success.opacity(0.5))
                            .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 3]))
                        
                        // Quality bars
                        BarMark(
                            x: .value("Rep", "Rep \(data.repNumber)"),
                            y: .value("Quality", data.formQuality)
                        )
                        .foregroundStyle(data.formQuality >= 0.75 ? AppTheme.GeneratedColors.success : AppTheme.GeneratedColors.warning)
                        .cornerRadius(4)
                    }
                    .chartYScale(domain: 0...1)
                    .chartYAxis {
                        AxisMarks(position: .leading) { value in
                            AxisGridLine()
                            AxisValueLabel {
                                if let doubleValue = value.as(Double.self) {
                                    Text("\(Int(doubleValue * 100))%")
                                        .font(.system(size: 10))
                                        .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                                }
                            }
                        }
                    }
                    .chartXAxis {
                        AxisMarks(position: .bottom) { value in
                            AxisValueLabel {
                                if let stringValue = value.as(String.self) {
                                    Text(stringValue)
                                        .font(.system(size: 10))
                                        .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                                }
                            }
                        }
                    }
                    .frame(height: 200)
                    .padding(.top, 8)
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "chart.bar")
                            .font(.system(size: 32))
                            .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                        
                        Text("NO REP DATA AVAILABLE")
                            .militaryMonospaced(size: 12)
                            .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                        
                        Text("DETAILED REP ANALYSIS NOT FOUND FOR THIS SESSION")
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.GeneratedColors.textTertiary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(16)
            .background(Color.white)
        }
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    @ViewBuilder
    private func errorStateView() -> some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(AppTheme.GeneratedColors.error)
            
            VStack(spacing: 12) {
                Text("WORKOUT DATA UNAVAILABLE")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppTheme.GeneratedColors.error)
                    .multilineTextAlignment(.center)
                
                Text("There was an issue saving or loading the workout details.")
                    .font(.system(size: 16))
                    .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    @ViewBuilder
    private func actionButtonsView() -> some View {
        VStack(spacing: 16) {
            // Primary CTA
            PTButton(
                "VIEW WORKOUT HISTORY",
                style: PTButton.ButtonStyle.primary,
                size: .large,
                icon: Image(systemName: "chart.line.uptrend.xyaxis"),
                fullWidth: true
            ) {
                tabBarVisibility.showTabBar()
                // Navigate to workout history
                dismiss()
            }
            
            // Secondary action
            PTButton(
                "DONE",
                style: PTButton.ButtonStyle.secondary,
                size: .large,
                fullWidth: true
            ) {
                tabBarVisibility.showTabBar()
                dismiss()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func animateContentIn() {
        // Staggered animations
        withAnimation(.easeOut(duration: 0.6)) {
            headerVisible = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeOut(duration: 0.6)) {
                metricsVisible = true
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeOut(duration: 0.6)) {
                chartVisible = true
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeOut(duration: 0.6)) {
                buttonsVisible = true
            }
        }
    }
    
    private func getExerciseIcon(_ exerciseType: String) -> String {
        switch exerciseType.lowercased() {
        case "pushup", "push-up", "pushups":
            return "figure.strengthtraining.traditional"
        case "situp", "sit-up", "situps":
            return "figure.core.training"
        case "pullup", "pull-up", "pullups":
            return "figure.strengthtraining.functional"
        case "run", "running":
            return "figure.run"
        default:
            return "figure.strengthtraining.traditional"
        }
    }
    
    private func getFormQualityColor(_ quality: Double) -> Color {
        if quality >= 0.8 {
            return AppTheme.GeneratedColors.success
        } else if quality >= 0.6 {
            return AppTheme.GeneratedColors.warning
        } else {
            return AppTheme.GeneratedColors.error
        }
    }
    
    private func getScoreInterpretation(_ score: Double) -> String {
        switch score {
        case 90...100:
            return "EXCELLENT"
        case 80..<90:
            return "GOOD"
        case 70..<80:
            return "AVERAGE"
        case 60..<70:
            return "BELOW AVERAGE"
        default:
            return "NEEDS IMPROVEMENT"
        }
    }
    
    private func getScoreColor(_ score: Double) -> Color {
        switch score {
        case 90...100:
            return AppTheme.GeneratedColors.success
        case 80..<90:
            return AppTheme.GeneratedColors.brassGold
        case 70..<80:
            return AppTheme.GeneratedColors.warning
        default:
            return AppTheme.GeneratedColors.error
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
        let mockGrader = WorkoutSessionPlaceholderGrader()
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
        if let workoutID = mockResult.id as? UUID {
            mockRepDetails.forEach {
                let dp = WorkoutDataPoint(id: $0.id, exerciseName: "Pushup", repNumber: $0.repNumber, formQuality: $0.formQuality, workoutID: workoutID)
                container.mainContext.insert(dp)
            }
        }
        
        return WorkoutCompleteView(result: mockResult, exerciseGrader: mockGraderBox)
            .modelContainer(container)
            .environmentObject(TabBarVisibilityManager.shared)
    }
}
#endif 