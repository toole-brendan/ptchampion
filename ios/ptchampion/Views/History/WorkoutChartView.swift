import SwiftUI
import Charts
import PTDesignSystem

struct WorkoutChartView: View {
    let chartData: [ChartableDataPoint]
    let chartYAxisLabel: String
    let filter: WorkoutFilter
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.medium) {
            if !chartData.isEmpty && filter != .all {
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
                        
                        Chart(chartData) { point in
                            LineMark(
                                x: .value("Date", point.date),
                                y: .value(chartYAxisLabel, point.value)
                            )
                            .foregroundStyle(AppTheme.GeneratedColors.brassGold)
                            .interpolationMethod(.catmullRom)
                            
                            PointMark(
                                x: .value("Date", point.date),
                                y: .value(chartYAxisLabel, point.value)
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
                                
                                Text(chartYAxisLabel)
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
}

// Sample data for preview
private func sampleChartData() -> [ChartableDataPoint] {
    let calendar = Calendar.current
    let today = Date()
    
    return (0..<5).map { day in
        let date = calendar.date(byAdding: .day, value: -day, to: today)!
        return ChartableDataPoint(
            date: date,
            value: Double.random(in: 10...30)
        )
    }.reversed()
}

#Preview {
    VStack {
        WorkoutChartView(
            chartData: sampleChartData(),
            chartYAxisLabel: "Reps",
            filter: .pushup
        )
        
        WorkoutChartView(
            chartData: [],
            chartYAxisLabel: "Reps",
            filter: .situp
        )
    }
    .previewLayout(.sizeThatFits)
    .padding()
} 