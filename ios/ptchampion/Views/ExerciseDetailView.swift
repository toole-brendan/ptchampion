import SwiftUI

struct ExerciseDetailView: View {
import PTDesignSystem
    let exerciseType: String
    @StateObject private var viewModel = ExerciseDetailViewModel()
    @State private var isLoading = true
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppConstants.Spacing.lg) {
                // Header with title and icon
                HStack {
                    Text(exerciseType.capitalized)
                        .font(.custom(AppFonts.heading, size: AppConstants.FontSize.xl))
                        .foregroundColor(.deepOpsGreen)
                    
                    Spacer()
                    
                    Image(systemName: exerciseIcon)
                        .font(.system(size: 24))
                        .foregroundColor(.deepOpsGreen)
                }
                .padding(AppConstants.Spacing.lg)
                .background(Color.white)
                .cornerRadius(AppConstants.Radius.lg)
                
                // Stats summary
                HStack(spacing: AppConstants.Spacing.md) {
                    StatCard(
                        title: "Best Session",
                        value: "\(viewModel.personalBest)",
                        icon: "trophy.fill",
                        trend: .none,
                        color: .brassGold,
                        isHighlighted: false
                    )
                    
                    StatCard(
                        title: "Last Week",
                        value: "\(viewModel.lastWeekTotal)",
                        icon: "calendar",
                        trend: viewModel.weeklyTrend,
                        color: .deepOpsGreen,
                        isHighlighted: false
                    )
                }
                
                // Progress chart
                if isLoading {
                    Spinner()
                        .padding(.vertical, 100)
                } else {
                    WorkoutProgressChart(
                        data: viewModel.progressData,
                        exerciseType: exerciseType
                    )
                }
                
                // Recent history
                VStack(alignment: .leading, spacing: AppConstants.Spacing.md) {
                    Text("Recent History")
                        .font(.custom(AppFonts.subheading, size: AppConstants.FontSize.lg))
                        .foregroundColor(.deepOpsGreen)
                    
                    ForEach(viewModel.recentSessions) { session in
                        historyRow(session: session)
                    }
                }
                .padding(AppConstants.Spacing.lg)
                .background(Color.white)
                .cornerRadius(AppConstants.Radius.lg)
                
                // Add exercise button
                PTButton(
                    title: "Record \(exerciseType.capitalized)",
                    variant: .primary,
                    fullWidth: true,
                    action: {
                        // Open recording modal
                    }
                )
                .padding(.vertical, AppConstants.Spacing.md)
            }
            .padding(AppConstants.Spacing.md)
        }
        .background(AppTheme.GeneratedColors.tacticalCream.opacity(0.5))
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
                    .font(.custom(AppFonts.subheading, size: AppConstants.FontSize.md))
                    .foregroundColor(.deepOpsGreen)
                
                Text(session.notes)
                    .font(.custom(AppFonts.body, size: AppConstants.FontSize.sm))
                    .foregroundColor(.tacticalGray)
            }
            
            Spacer()
            
            Text("\(session.value) \(session.unit)")
                .font(.custom(AppFonts.subheading, size: AppConstants.FontSize.md))
                .foregroundColor(.brassGold)
        }
        .padding(AppConstants.Spacing.md)
        .background(Color.white)
        .cornerRadius(AppConstants.Radius.md)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - View Model
class ExerciseDetailViewModel: ObservableObject {
    @Published var progressData: [WorkoutDataPoint] = []
    @Published var recentSessions: [ExerciseSession] = []
    @Published var personalBest: Int = 0
    @Published var lastWeekTotal: Int = 0
    @Published var weeklyTrend: Trend = .none
    
    func loadData(for exerciseType: String) {
        // This would normally fetch from the NetworkService
        // Simulating data for now
        
        // Generate sample progress data
        let baseValue = exerciseType == "running" ? 3 : 25
        let random = Int.random(in: -5...10)
        
        progressData = (0...6).map { day in
            let value = max(1, baseValue + day * 3 + Int.random(in: -5...5))
            return WorkoutDataPoint(
                date: Date().addingTimeInterval(Double(-6 + day) * 86400),
                value: value
            )
        }
        
        // Generate sample sessions
        recentSessions = (0...4).map { i in
            let date = Date().addingTimeInterval(Double(-i) * 86400 * 2)
            let value = progressData[min(6-i, progressData.count-1)].value
            
            return ExerciseSession(
                date: date,
                value: value,
                notes: "Completed \(value) \(exerciseType.lowercased())\(value == 1 ? "" : "s")",
                unit: exerciseType == "running" ? "km" : "reps"
            )
        }
        
        // Calculate stats
        personalBest = progressData.map { $0.value }.max() ?? 0
        
        let thisWeek = progressData.suffix(3).map { $0.value }.reduce(0, +)
        let lastWeek = progressData.prefix(3).map { $0.value }.reduce(0, +)
        lastWeekTotal = thisWeek
        
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