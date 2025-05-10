import SwiftUI
import PTDesignSystem
import Charts

// Generic data point for charts
struct ChartableDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

struct WorkoutProgressChart: View {
    // Static date formatter
    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()
    
    // Chart data and configuration
    let dataPoints: [ChartableDataPoint]
    let title: String
    let yAxisLabel: String?
    let showLabels: Bool
    let accentColor: Color
    let showGradient: Bool
    let animateOnAppear: Bool
    
    // Animation state
    @State private var animationProgress: CGFloat = 0
    
    init(
        dataPoints: [ChartableDataPoint],
        title: String, 
        yAxisLabel: String? = nil,
        showLabels: Bool = true,
        accentColor: Color = AppTheme.GeneratedColors.brassGold,
        showGradient: Bool = true,
        animateOnAppear: Bool = true
    ) {
        self.dataPoints = dataPoints
        self.title = title
        self.yAxisLabel = yAxisLabel
        self.showLabels = showLabels
        self.accentColor = accentColor
        self.showGradient = showGradient
        self.animateOnAppear = animateOnAppear
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.medium) {
            if showLabels {
                HStack {
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                    
                    Spacer()
                    
                    if let yAxisLabel = yAxisLabel {
                        Text(yAxisLabel)
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(accentColor.opacity(0.1))
                            )
                    }
                }
            }
            
            if dataPoints.isEmpty {
                emptyStateView
            } else {
                chartContent
            }
        }
        .padding(AppTheme.GeneratedSpacing.contentPadding)
        .background(AppTheme.GeneratedColors.cardBackground)
        .cornerRadius(AppTheme.GeneratedRadius.card)
        .onAppear {
            if animateOnAppear {
                withAnimation(.easeInOut(duration: 1.2)) {
                    animationProgress = 1.0
                }
            } else {
                animationProgress = 1.0
            }
        }
    }
    
    // Empty state view
    private var emptyStateView: some View {
        VStack(spacing: AppTheme.GeneratedSpacing.medium) {
            Image(systemName: "chart.line.downtrend.xyaxis")
                .font(.system(size: 36))
                .foregroundColor(AppTheme.GeneratedColors.textTertiary.opacity(0.5))
            
            VStack(spacing: AppTheme.GeneratedSpacing.small) {
                Text("No data available")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                
                Text("Complete more workouts to see your progress")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.GeneratedColors.textTertiary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
    
    // Main chart content
    @ViewBuilder
    private var chartContent: some View {
        if #available(iOS 16.0, *) {
            modernChartView
        } else {
            legacyChartView
        }
    }
    
    // Modern chart using Charts framework
    @available(iOS 16.0, *)
    private var modernChartView: some View {
        Chart {
            ForEach(dataPoints) { point in
                // Line mark
                LineMark(
                    x: .value("Date", point.date),
                    y: .value(yAxisLabel ?? "Value", point.value * animationProgress)
                )
                .foregroundStyle(accentColor)
                .interpolationMethod(.catmullRom)
                
                // Area mark for gradient
                if showGradient {
                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value(yAxisLabel ?? "Value", point.value * animationProgress)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                accentColor.opacity(0.3),
                                accentColor.opacity(0.05)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }
                
                // Data points
                PointMark(
                    x: .value("Date", point.date),
                    y: .value(yAxisLabel ?? "Value", point.value * animationProgress)
                )
                .foregroundStyle(accentColor)
                .symbolSize(CGSize(width: 8, height: 8))
            }
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
                if let date = value.as(Date.self) {
                    AxisValueLabel {
                        Text(Self.dayFormatter.string(from: date))
                            .font(.system(size: 12))
                            .foregroundStyle(AppTheme.GeneratedColors.textSecondary)
                    }
                }
            }
        }
        .frame(height: 200)
    }
    
    // Legacy custom chart for older iOS versions
    private var legacyChartView: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomLeading) {
                // Y-axis grid lines
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(0..<5) { i in
                        Divider()
                            .background(AppTheme.GeneratedColors.textTertiary.opacity(0.3))
                        Spacer()
                    }
                    Divider()
                        .background(AppTheme.GeneratedColors.textTertiary.opacity(0.3))
                }
                
                // Area fill for gradient
                if showGradient && dataPoints.count > 1 {
                    gradientPath(in: geometry)
                        .fill(
                            LinearGradient(
                                colors: [
                                    accentColor.opacity(0.3),
                                    accentColor.opacity(0.05)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                
                // Line chart
                linePath(in: geometry)
                    .trim(from: 0, to: animationProgress)
                    .stroke(accentColor, lineWidth: 2)
                
                // Data points
                ForEach(dataPoints.indices, id: \.self) { i in
                    let maxValue = dataPoints.map { $0.value }.max() ?? 1.0
                    let width = geometry.size.width
                    let height = geometry.size.height
                    let xStep = width / CGFloat(max(1, dataPoints.count - 1))
                    let x = CGFloat(i) * xStep
                    let y = height - CGFloat(dataPoints[i].value / maxValue) * height * animationProgress
                    
                    Circle()
                        .fill(accentColor)
                        .frame(width: 8, height: 8)
                        .position(x: x, y: y)
                }
                
                // X-axis labels
                if showLabels && dataPoints.count > 1 {
                    HStack(alignment: .bottom, spacing: 0) {
                        ForEach(dataPoints.indices, id: \.self) { i in
                            if i == 0 || i == dataPoints.count - 1 || i % max(1, (dataPoints.count / 4)) == 0 {
                                let date = dataPoints[i].date
                                let text = Self.dayFormatter.string(from: date)
                                
                                Text(text)
                                    .font(.system(size: 12))
                                    .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                                    .frame(width: geometry.size.width / CGFloat(dataPoints.count))
                            } else {
                                Spacer()
                                    .frame(width: geometry.size.width / CGFloat(dataPoints.count))
                            }
                        }
                    }
                    .padding(.top, geometry.size.height)
                }
            }
        }
        .frame(height: 200)
    }
    
    // Helper function to create the line path
    private func linePath(in geometry: GeometryProxy) -> Path {
        Path { path in
            let width = geometry.size.width
            let height = geometry.size.height
            let maxValue = dataPoints.map { $0.value }.max() ?? 1.0
            let xStep = width / CGFloat(max(1, dataPoints.count - 1))
            
            if dataPoints.isEmpty { return }
            
            path.move(
                to: CGPoint(
                    x: 0,
                    y: height - CGFloat(dataPoints[0].value / maxValue) * height
                )
            )
            
            for i in 1..<dataPoints.count {
                let point = CGPoint(
                    x: CGFloat(i) * xStep,
                    y: height - CGFloat(dataPoints[i].value / maxValue) * height
                )
                path.addLine(to: point)
            }
        }
    }
    
    // Helper function to create the gradient area path
    private func gradientPath(in geometry: GeometryProxy) -> Path {
        Path { path in
            let width = geometry.size.width
            let height = geometry.size.height
            let maxValue = dataPoints.map { $0.value }.max() ?? 1.0
            let xStep = width / CGFloat(max(1, dataPoints.count - 1))
            
            if dataPoints.isEmpty { return }
            
            // Start at the bottom left
            path.move(to: CGPoint(x: 0, y: height))
            
            // Move to the first data point
            path.addLine(
                to: CGPoint(
                    x: 0,
                    y: height - CGFloat(dataPoints[0].value / maxValue) * height
                )
            )
            
            // Add lines through all points
            for i in 1..<dataPoints.count {
                let point = CGPoint(
                    x: CGFloat(i) * xStep,
                    y: height - CGFloat(dataPoints[i].value / maxValue) * height
                )
                path.addLine(to: point)
            }
            
            // Add line to bottom right
            path.addLine(to: CGPoint(x: width, y: height))
            
            // Close the path
            path.closeSubpath()
        }
    }
}

// MARK: - Previews
struct WorkoutProgressChart_Previews: PreviewProvider {
    static var sampleData: [ChartableDataPoint] {
        let calendar = Calendar.current
        let today = Date()
        
        return (0..<7).map { day in
            let date = calendar.date(byAdding: .day, value: -day, to: today)!
            return ChartableDataPoint(
                date: date,
                value: Double.random(in: 10...50)
            )
        }.reversed()
    }
    
    static var previews: some View {
        Group {
            // Standard chart
            WorkoutProgressChart(
                dataPoints: sampleData,
                title: "Weekly Push-ups",
                yAxisLabel: "Reps"
            )
            .padding()
            .previewDisplayName("Standard Chart")
            
            // Empty chart
            WorkoutProgressChart(
                dataPoints: [],
                title: "Empty Chart",
                yAxisLabel: "No Data"
            )
            .padding()
            .previewDisplayName("Empty Chart")
            
            // Dark mode chart
            WorkoutProgressChart(
                dataPoints: sampleData,
                title: "Weekly Progress",
                yAxisLabel: "Score",
                accentColor: Color.green
            )
            .padding()
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode Chart")
        }
        .background(Color(.systemBackground))
        .previewLayout(.sizeThatFits)
    }
} 