import SwiftUI
import Charts
import PTDesignSystem

struct WorkoutChartView: View {
    let chartData: [ChartableDataPoint]
    let chartYAxisLabel: String
    let filter: WorkoutFilter
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            if !chartData.isEmpty && filter != .all {
                Text("PROGRESS CHART")
                    .militaryMonospaced(size: Spacing.small)
                    .foregroundColor(ThemeColor.textSecondary)
                    .padding(.horizontal, Spacing.contentPadding)
                
VStack {
                    VStack(alignment: .leading, spacing: Spacing.small) {
                        HStack {
                            Text(filter.rawValue)
                                .militaryMonospaced(size: Spacing.body)
                                .foregroundColor(ThemeColor.textPrimary)
                            
                            Spacer()
                            
                            Text(filter.rawValue)
                                .small(weight: .medium)
                                .foregroundColor(ThemeColor.brassGold)
                        }
                        
                        Chart(chartData) { point in
                            LineMark(
                                x: .value("Date", point.date),
                                y: .value(chartYAxisLabel, point.value)
                            )
                            .foregroundStyle(ThemeColor.brassGold)
                            .interpolationMethod(.catmullRom)
                            
                            PointMark(
                                x: .value("Date", point.date),
                                y: .value(chartYAxisLabel, point.value)
                            )
                            .foregroundStyle(ThemeColor.brassGold)
                            .symbolSize(CGSize(width: 8, height: 8))
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading) { _ in
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 3]))
                                    .foregroundStyle(ThemeColor.textTertiary.opacity(0.3))
                                AxisTick(stroke: StrokeStyle(lineWidth: 1))
                                    .foregroundStyle(ThemeColor.textTertiary)
                                AxisValueLabel()
                                    .foregroundStyle(ThemeColor.textSecondary)
                            }
                        }
                        .chartXAxis {
                            AxisMarks(values: .automatic(desiredCount: 5)) { value in
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 3]))
                                    .foregroundStyle(ThemeColor.textTertiary.opacity(0.3))
                                AxisTick(stroke: StrokeStyle(lineWidth: 1))
                                    .foregroundStyle(ThemeColor.textTertiary)
                                AxisValueLabel(format: .dateTime.month().day())
                                    .foregroundStyle(ThemeColor.textSecondary)
                            }
                        }
                        .frame(height: 200)
                        .padding(.top, Spacing.small)
                        
                        HStack {
                            Spacer()
                            
                            HStack(spacing: 4) {
                                Text("Y-Axis:")
                                    .caption()
                                    .foregroundColor(ThemeColor.textTertiary)
                                
                                Text(chartYAxisLabel)
                                    .militaryMonospaced(size: 12)
                                    .foregroundColor(ThemeColor.textSecondary)
                            }
                        }
                    }
                    .padding(Spacing.contentPadding)
                }
            } else if filter != .all {
                // Empty chart state
                Text("PROGRESS CHART")
                    .militaryMonospaced(size: Spacing.small)
                    .foregroundColor(ThemeColor.textSecondary)
                    .padding(.horizontal, Spacing.contentPadding)
                
VStack {
                    VStack(spacing: Spacing.medium) {
                        Image(systemName: "chart.line.downtrend.xyaxis")
                            .font(.system(size: 36))
                            .foregroundColor(ThemeColor.textTertiary.opacity(0.6))
                        
                        VStack(spacing: Spacing.small) {
                            Text("Not enough data to display chart")
                                .body(weight: .medium)
                                .foregroundColor(ThemeColor.textSecondary)
                            
                            Text("Complete more \(filter.rawValue) workouts to see your progress")
                                .small()
                                .foregroundColor(ThemeColor.textTertiary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 180)
                    .padding(Spacing.contentPadding)
                }
            }
        }
        .padding(.horizontal, filter != .all ? 0 : Spacing.contentPadding)
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
    .background(ThemeColor.background)
    .previewLayout(.sizeThatFits)
    .padding()
}
