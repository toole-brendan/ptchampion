import SwiftUI
import PTDesignSystem

struct ExerciseDetailView: View {
    let exerciseType: String
    @StateObject private var viewModel = ExerciseDetailViewModel()
    @State private var isLoading = true
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: Spacing.large) {
                // Header with title and icon
                HStack {
                    Text(exerciseType.capitalized)
                        .heading4(weight: .bold)
                        .foregroundColor(Color.textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: exerciseIcon)
                        .heading2()
                        .foregroundColor(Color.textPrimary)
                }
                .padding(Spacing.large)
                .background(Color.cardBackground)
                .cornerRadius(CornerRadius.large)
                
                // Stats summary
                VStack {
                    HStack(spacing: Spacing.medium) {
                        StatCard(
                            title: "Best Session",
                            value: "\(viewModel.personalBest)",
                            unit: viewModel.unitForExerciseType(exerciseType),
                            color: Color.brassGold,
                            iconName: "trophy.fill"
                        )
                        
                        StatCard(
                            title: "Last Week Total",
                            value: "\(viewModel.lastWeekTotal)",
                            unit: viewModel.unitForExerciseType(exerciseType),
                            color: Color.textPrimary,
                            iconName: "calendar"
                        )
                    }
                }
                .card()
                
                // Progress chart
                VStack {
                    if isLoading {
                        Spinner()
                            .padding(.vertical, 100)
                    } else {
                        WorkoutProgressChart(
                            dataPoints: viewModel.progressData,
                            title: exerciseType.capitalized
                        )
                    }
                }
                .card()
                
                // Recent history
                VStack {
                    VStack(alignment: .leading, spacing: Spacing.medium) {
                        Text(verbatim: "Recent History")
                            .heading4(weight: .semibold)
                            .foregroundColor(Color.textPrimary)
                        
                        ForEach(viewModel.recentSessions) { session in
                            historyRow(session: session)
                        }
                    }
                }
                .card()
                
                // Add exercise button
                let buttonStyle: PTButton.ExtendedStyle = .primary
                PTButton(
                    "Record \(exerciseType.capitalized)",
                    style: buttonStyle
                ) {
                    // Open recording modal
                }
                .padding(.vertical, Spacing.medium)
            }
            .frame(maxWidth: 600)
            .adaptivePadding()
        }
        .background(
            // Use a concrete color from UIKit to SwiftUI conversion to avoid ambiguity
            Color(uiColor: UIColor(red: 0.95, green: 0.95, blue: 0.9, alpha: 0.5))
        )
        .navigationBarTitleDisplayMode(.inline)
        .container()
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
                    .body(weight: .semibold)
                    .foregroundColor(Color.textPrimary)
                
                Text(session.notes)
                    .small()
                    .foregroundColor(Color.textSecondary)
            }
            
            Spacer()
            
            Text("\(session.value) \(session.unit)")
                .body(weight: .semibold)
                .foregroundColor(Color.brassGold)
        }
        .padding(Spacing.medium)
        .background(Color.cardBackground)
        .cornerRadius(CornerRadius.medium)
        .shadow(color: Color(uiColor: UIColor.black).opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - View Model
class ExerciseDetailViewModel: ObservableObject {
    @Published var progressData: [ChartableDataPoint] = []
    @Published var recentSessions: [ExerciseSession] = []
    @Published var personalBest: Int = 0
    @Published var lastWeekTotal: Int = 0
    @Published var weeklyTrend: Trend = .none
    
    func unitForExerciseType(_ exerciseType: String) -> String {
        return exerciseType.lowercased() == "running" ? "km" : "reps"
    }
    
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