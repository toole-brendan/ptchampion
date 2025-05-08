import SwiftUI
import PTDesignSystem

struct ExerciseDetailView: View {
    let exerciseType: String
    @StateObject private var viewModel = ExerciseDetailViewModel()
    @State private var isLoading = true
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.GeneratedSpacing.large) {
                // Header with title and icon
                HStack {
                    Text(exerciseType.capitalized)
                        .font(.system(size: AppTheme.GeneratedTypography.heading4, weight: .bold))
                        .foregroundColor(AppTheme.GeneratedColors.deepOps)
                    
                    Spacer()
                    
                    Image(systemName: exerciseIcon)
                        .font(.system(size: 24))
                        .foregroundColor(AppTheme.GeneratedColors.deepOps)
                }
                .padding(AppTheme.GeneratedSpacing.large)
                .background(Color.white)
                .cornerRadius(AppTheme.GeneratedRadius.large)
                
                // Stats summary
                HStack(spacing: AppTheme.GeneratedSpacing.medium) {
                    StatCard(
                        title: "Best Session",
                        value: "\(viewModel.personalBest)",
                        icon: "trophy.fill",
                        trend: .none,
                        color: AppTheme.GeneratedColors.brassGold,
                        isHighlighted: false
                    )
                    
                    StatCard(
                        title: "Last Week",
                        value: "\(viewModel.lastWeekTotal)",
                        icon: "calendar",
                        trend: viewModel.weeklyTrend,
                        color: AppTheme.GeneratedColors.deepOps,
                        isHighlighted: false
                    )
                }
                
                // Progress chart
                if isLoading {
                    Spinner()
                        .padding(.vertical, 100)
                } else {
                    WorkoutProgressChart(
                        dataPoints: viewModel.progressData,
                        title: exerciseType.capitalized
                    )
                }
                
                // Recent history
                VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.medium) {
                    Text(verbatim: "Recent History")
                        .font(.system(size: AppTheme.GeneratedTypography.heading4, weight: .semibold))
                        .foregroundColor(AppTheme.GeneratedColors.deepOps)
                    
                    ForEach(viewModel.recentSessions) { session in
                        historyRow(session: session)
                    }
                }
                .padding(AppTheme.GeneratedSpacing.large)
                .background(Color.white)
                .cornerRadius(AppTheme.GeneratedRadius.large)
                
                // Add exercise button
                PTButton(
                    "Record \(exerciseType.capitalized)",
                    style: .primary
                ) {
                    // Open recording modal
                }
                .padding(.vertical, AppTheme.GeneratedSpacing.medium)
            }
            .padding(AppTheme.GeneratedSpacing.medium)
        }
        .background(AppTheme.GeneratedColors.cream.opacity(0.5))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Simulate network loading
            viewModel.loadData(for: exerciseType)
            
            // Simulate network delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                isLoading = false
            }
        }
    }
    
    // Exercise icon based on type
    private var exerciseIcon: String {
        switch exerciseType.lowercased() {
        case "pushup": return "figure.strengthtraining.traditional"
        case "pullup": return "figure.gymnastics"
        case "situp": return "figure.core.training"
        case "running": return "figure.run"
        default: return "figure.highintensity.intervaltraining"
        }
    }
    
    // History row for a session
    private func historyRow(session: ExerciseSession) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(session.formattedDate)
                    .font(.system(size: AppTheme.GeneratedTypography.body, weight: .semibold))
                    .foregroundColor(AppTheme.GeneratedColors.deepOps)
                
                Text(session.notes)
                    .font(.system(size: AppTheme.GeneratedTypography.small))
                    .foregroundColor(AppTheme.GeneratedColors.tacticalGray)
            }
            
            Spacer()
            
            Text("\(session.value) \(session.unit)")
                .font(.system(size: AppTheme.GeneratedTypography.body, weight: .semibold))
                .foregroundColor(AppTheme.GeneratedColors.brassGold)
        }
        .padding(AppTheme.GeneratedSpacing.medium)
        .background(Color.white)
        .cornerRadius(AppTheme.GeneratedRadius.medium)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - View Model
class ExerciseDetailViewModel: ObservableObject {
    @Published var progressData: [ChartableDataPoint] = []
    @Published var recentSessions: [ExerciseSession] = []
    @Published var personalBest: Int = 0
    @Published var lastWeekTotal: Int = 0
    @Published var weeklyTrend: Trend = .none
    
    func loadData(for exerciseType: String) {
        // This would normally fetch from the NetworkService
        // Simulating data for now
        
        // Generate sample progress data as [ChartableDataPoint]
        let baseValue = exerciseType == "running" ? 3.0 : 25.0 // Use Double for value
        
        // Generate ChartableDataPoint array
        self.progressData = (0...6).map { day in
            let date = Date().addingTimeInterval(Double(-6 + day) * 86400)
            // Simulate value fluctuations
            let value = max(1.0, baseValue + Double(day * 3) + Double.random(in: -5.0...5.0))
            return ChartableDataPoint(date: date, value: value) // Create ChartableDataPoint
        }
        
        // Generate sample sessions using the generated progressData
        self.recentSessions = (0...4).map { i in
            let index = min(6 - i, progressData.count - 1)
            guard index >= 0 else { 
                // Handle edge case where progressData might be empty or index is invalid
                return ExerciseSession(date: Date(), value: 0, notes: "Error generating session", unit: "") 
            }
            let chartPoint = progressData[index]
            let value = Int(chartPoint.value) // Use value from ChartableDataPoint
            
            return ExerciseSession(
                date: chartPoint.date, // Use date from ChartableDataPoint
                value: value,
                notes: "Completed \(value) \(exerciseType.lowercased())\(value == 1 ? "" : "s")",
                unit: exerciseType == "running" ? "km" : "reps"
            )
        }
        
        // Calculate stats using progressData (which is [ChartableDataPoint])
        // Use .value property
        self.personalBest = Int(progressData.map(\.value).max() ?? 0.0)
        
        // Correct reduce calls, ensure Int conversion
        let thisWeek = progressData.suffix(3).reduce(0.0) { $0 + $1.value } // Reduce Doubles
        let lastWeek = progressData.prefix(3).reduce(0.0) { $0 + $1.value } // Reduce Doubles
        self.lastWeekTotal = Int(thisWeek) // Convert final sum to Int
        
        // Trend calculation remains similar
        if thisWeek > lastWeek {
            weeklyTrend = .up(percentage: 15)
        } else if thisWeek < lastWeek {
            weeklyTrend = .down(percentage: 8)
        } else {
            weeklyTrend = .none
        }
    }
}

// MARK: - Models
struct ExerciseSession: Identifiable {
    let id = UUID()
    let date: Date
    let value: Int
    let notes: String
    let unit: String
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Preview
struct ExerciseDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ExerciseDetailView(exerciseType: "pushup")
                .navigationTitle("Exercise Details")
        }
    }
} 