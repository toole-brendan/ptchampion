import SwiftUI
import Charts

struct WorkoutProgressChart: View {
    let data: [WorkoutDataPoint]
    let exerciseType: String
    
    init(data: [WorkoutDataPoint], exerciseType: String) {
        self.data = data
        self.exerciseType = exerciseType
    }
    
    // Helper for finding max value to determine Y-axis scale
    private var maxValue: Double {
        if data.isEmpty { return 100 }
        let max = data.map { $0.value }.max() ?? 0
        return Double(max * 12 / 10) // Add 20% padding
    }
    
    // Helper for formatted exercise name
    private var formattedExerciseType: String {
        switch exerciseType.lowercased() {
        case "pushup": return "Push-ups"
        case "pullup": return "Pull-ups"
        case "situp": return "Sit-ups"
        case "running": return "Running"
        default: return exerciseType.capitalized
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppConstants.Spacing.md) {
            // Chart header
            Text("Progress: \(formattedExerciseType)")
                .font(.custom(AppFonts.subheading, size: AppConstants.FontSize.lg))
                .foregroundColor(.deepOpsGreen)
            
            // The chart
            chart
                .frame(height: 200)
            
            // Legend
            HStack(spacing: AppConstants.Spacing.lg) {
                legendItem(color: .brassGold, label: "Your Progress")
                
                if exerciseType.lowercased() == "running" {
                    Text("Distance (km)")
                        .font(.custom(AppFonts.body, size: AppConstants.FontSize.sm))
                        .foregroundColor(.tacticalGray)
                } else {
                    Text("Repetitions")
                        .font(.custom(AppFonts.body, size: AppConstants.FontSize.sm))
                        .foregroundColor(.tacticalGray)
                }
            }
        }
        .padding(AppConstants.Spacing.lg)
        .background(Color.white)
        .cornerRadius(AppConstants.Radius.lg)
    }
    
    // Chart view using Swift Charts
    private var chart: some View {
        Chart {
            ForEach(data) { item in
                LineMark(
                    x: .value("Date", item.date),
                    y: .value("Value", item.value)
                )
                .foregroundStyle(Color.brassGold)
                .interpolationMethod(.catmullRom) // Smooth curve
                
                AreaMark(
                    x: .value("Date", item.date),
                    y: .value("Value", item.value)
                )
                .foregroundStyle(
                    .linearGradient(
                        colors: [Color.brassGold.opacity(0.3), Color.brassGold.opacity(0.01)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom) // Smooth curve
                
                PointMark(
                    x: .value("Date", item.date),
                    y: .value("Value", item.value)
                )
                .foregroundStyle(Color.brassGold)
                .symbolSize(30)
            }
        }
        .chartYScale(domain: 0...maxValue)
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [5, 5]))
                    .foregroundStyle(Color.tacticalGray.opacity(0.3))
                AxisTick(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color.tacticalGray.opacity(0.3))
                AxisValueLabel()
                    .font(.custom(AppFonts.body, size: AppConstants.FontSize.xs))
                    .foregroundStyle(Color.tacticalGray)
            }
        }
    }
    
    // Legend item helper
    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: AppConstants.Spacing.xs) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(label)
                .font(.custom(AppFonts.body, size: AppConstants.FontSize.sm))
                .foregroundColor(.tacticalGray)
        }
    }
}

// Data model for workout progress
struct WorkoutDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Int
    
    // Helper initializer with ISO date string
    init(dateString: String, value: Int) {
        let formatter = ISO8601DateFormatter()
        self.date = formatter.date(from: dateString) ?? Date()
        self.value = value
    }
    
    init(date: Date, value: Int) {
        self.date = date
        self.value = value
    }
}

// MARK: - Preview Provider
struct WorkoutProgressChart_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: AppConstants.Spacing.xl) {
                // Pushups example
                WorkoutProgressChart(
                    data: [
                        WorkoutDataPoint(date: Date().addingTimeInterval(-6 * 86400), value: 25),
                        WorkoutDataPoint(date: Date().addingTimeInterval(-5 * 86400), value: 28),
                        WorkoutDataPoint(date: Date().addingTimeInterval(-4 * 86400), value: 30),
                        WorkoutDataPoint(date: Date().addingTimeInterval(-3 * 86400), value: 32),
                        WorkoutDataPoint(date: Date().addingTimeInterval(-2 * 86400), value: 35),
                        WorkoutDataPoint(date: Date().addingTimeInterval(-1 * 86400), value: 40),
                        WorkoutDataPoint(date: Date(), value: 42)
                    ],
                    exerciseType: "pushup"
                )
                
                // Running example (distance in km)
                WorkoutProgressChart(
                    data: [
                        WorkoutDataPoint(date: Date().addingTimeInterval(-6 * 86400), value: 3),
                        WorkoutDataPoint(date: Date().addingTimeInterval(-5 * 86400), value: 2),
                        WorkoutDataPoint(date: Date().addingTimeInterval(-4 * 86400), value: 5),
                        WorkoutDataPoint(date: Date().addingTimeInterval(-3 * 86400), value: 4),
                        WorkoutDataPoint(date: Date().addingTimeInterval(-2 * 86400), value: 6),
                        WorkoutDataPoint(date: Date().addingTimeInterval(-1 * 86400), value: 5),
                        WorkoutDataPoint(date: Date(), value: 7)
                    ],
                    exerciseType: "running"
                )
            }
            .padding()
            .background(Color.tacticalCream.opacity(0.5))
        }
    }
} 