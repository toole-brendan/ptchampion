import SwiftUI
import Charts
import PTDesignSystem
import Foundation

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
        return max * 12 / 10 // Add 20% padding
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
        VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.medium) {
            // Chart header
            Text("Progress: \(formattedExerciseType)")
                .font(AppTheme.GeneratedTypography.bodySemibold(size: AppTheme.GeneratedTypography.heading4))
                .foregroundColor(AppTheme.GeneratedColors.deepOps)
            
            // The chart
            chart
                .frame(height: 200)
            
            // Legend
            HStack(spacing: AppTheme.GeneratedSpacing.large) {
                legendItem(color: AppTheme.GeneratedColors.brassGold, label: "Your Progress")
                
                if exerciseType.lowercased() == "running" {
                    Text("Distance (km)")
                        .font(AppTheme.GeneratedTypography.body(size: AppTheme.GeneratedTypography.small))
                        .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                } else {
                    Text("Repetitions")
                        .font(AppTheme.GeneratedTypography.body(size: AppTheme.GeneratedTypography.small))
                        .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                }
            }
        }
        .padding(AppTheme.GeneratedSpacing.large)
        .background(AppTheme.GeneratedColors.cardBackground)
        .cornerRadius(AppTheme.GeneratedRadius.large)
    }
    
    // Chart view using Swift Charts
    private var chart: some View {
        Chart {
            ForEach(data) { item in
                LineMark(
                    x: .value("Date", item.date),
                    y: .value("Value", item.value)
                )
                .foregroundStyle(AppTheme.GeneratedColors.brassGold)
                .interpolationMethod(.catmullRom) // Smooth curve
                
                AreaMark(
                    x: .value("Date", item.date),
                    y: .value("Value", item.value)
                )
                .foregroundStyle(
                    .linearGradient(
                        colors: [AppTheme.GeneratedColors.brassGold.opacity(0.3), AppTheme.GeneratedColors.brassGold.opacity(0.01)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom) // Smooth curve
                
                PointMark(
                    x: .value("Date", item.date),
                    y: .value("Value", item.value)
                )
                .foregroundStyle(AppTheme.GeneratedColors.brassGold)
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
                    .foregroundStyle(AppTheme.GeneratedColors.textTertiary.opacity(0.3))
                AxisTick(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(AppTheme.GeneratedColors.textTertiary.opacity(0.3))
                AxisValueLabel()
                    .font(AppTheme.GeneratedTypography.body(size: AppTheme.GeneratedTypography.tiny))
                    .foregroundStyle(AppTheme.GeneratedColors.textSecondary)
            }
        }
    }
    
    // Legend item helper
    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: AppTheme.GeneratedSpacing.small) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(label)
                .font(AppTheme.GeneratedTypography.body(size: AppTheme.GeneratedTypography.small))
                .foregroundColor(AppTheme.GeneratedColors.textSecondary)
        }
    }
}

// MARK: - Preview Provider
struct WorkoutProgressChart_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: AppTheme.GeneratedSpacing.section) {
                // Pushups example
                WorkoutProgressChart(
                    data: [
                        WorkoutDataPoint(date: Date().addingTimeInterval(-6 * 86400), value: 25.0),
                        WorkoutDataPoint(date: Date().addingTimeInterval(-5 * 86400), value: 28.0),
                        WorkoutDataPoint(date: Date().addingTimeInterval(-4 * 86400), value: 30.0),
                        WorkoutDataPoint(date: Date().addingTimeInterval(-3 * 86400), value: 32.0),
                        WorkoutDataPoint(date: Date().addingTimeInterval(-2 * 86400), value: 35.0),
                        WorkoutDataPoint(date: Date().addingTimeInterval(-1 * 86400), value: 40.0),
                        WorkoutDataPoint(date: Date(), value: 42.0)
                    ],
                    exerciseType: "pushup"
                )
                
                // Running example (distance in km)
                WorkoutProgressChart(
                    data: [
                        WorkoutDataPoint(date: Date().addingTimeInterval(-6 * 86400), value: 3.0),
                        WorkoutDataPoint(date: Date().addingTimeInterval(-5 * 86400), value: 2.0),
                        WorkoutDataPoint(date: Date().addingTimeInterval(-4 * 86400), value: 5.0),
                        WorkoutDataPoint(date: Date().addingTimeInterval(-3 * 86400), value: 4.0),
                        WorkoutDataPoint(date: Date().addingTimeInterval(-2 * 86400), value: 6.0),
                        WorkoutDataPoint(date: Date().addingTimeInterval(-1 * 86400), value: 5.0),
                        WorkoutDataPoint(date: Date(), value: 7.0)
                    ],
                    exerciseType: "running"
                )
            }
            .padding()
            .background(AppTheme.GeneratedColors.cream.opacity(0.5))
        }
    }
} 