import SwiftUI
import PTDesignSystem

struct WorkoutProgressChart: View {
    let dataPoints: [WorkoutDataPoint]
    let title: String
    let yAxisLabel: String?
    let showLabels: Bool
    
    init(dataPoints: [WorkoutDataPoint], 
         title: String, 
         yAxisLabel: String? = nil,
         showLabels: Bool = true) {
        self.dataPoints = dataPoints
        self.title = title
        self.yAxisLabel = yAxisLabel
        self.showLabels = showLabels
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.medium) {
            if showLabels {
                HStack {
                    PTLabel.sized(title, style: .heading, size: .medium)
                    Spacer()
                    if let yAxisLabel = yAxisLabel {
                        PTLabel(yAxisLabel, style: .caption)
                            .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                    }
                }
            }
            
            if dataPoints.isEmpty {
                VStack(spacing: AppTheme.GeneratedSpacing.small) {
                    Image(systemName: "chart.line.downtrend.xyaxis")
                        .font(.largeTitle)
                        .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                    PTLabel("No data available", style: .body)
                        .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                }
                .frame(maxWidth: .infinity, minHeight: 200)
            } else {
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
                        
                        // Chart
                        Path { path in
                            let width = geometry.size.width
                            let height = geometry.size.height
                            let maxValue = dataPoints.map { $0.value }.max() ?? 1
                            let xStep = width / CGFloat(max(1, dataPoints.count - 1))
                            
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
                        .stroke(AppTheme.GeneratedColors.primary, lineWidth: 2)
                        
                        // Data points
                        ForEach(dataPoints.indices, id: \.self) { i in
                            let maxValue = dataPoints.map { $0.value }.max() ?? 1
                            let width = geometry.size.width
                            let height = geometry.size.height
                            let xStep = width / CGFloat(max(1, dataPoints.count - 1))
                            let x = CGFloat(i) * xStep
                            let y = height - CGFloat(dataPoints[i].value / maxValue) * height
                            
                            Circle()
                                .fill(AppTheme.GeneratedColors.primary)
                                .frame(width: 8, height: 8)
                                .position(x: x, y: y)
                        }
                        
                        // X-axis labels
                        if showLabels && dataPoints.count > 1 {
                            HStack(alignment: .bottom, spacing: 0) {
                                ForEach(dataPoints.indices, id: \.self) { i in
                                    if i == 0 || i == dataPoints.count - 1 || i % max(1, (dataPoints.count / 4)) == 0 {
                                        let date = dataPoints[i].date
                                        let formatter = DateFormatter()
                                        formatter.dateFormat = "M/d"
                                        let text = formatter.string(from: date)
                                        
                                        Text(text)
                                            .font(.caption)
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
        }
        .padding(AppTheme.GeneratedSpacing.medium)
        .background(AppTheme.GeneratedColors.cardBackground)
        .cornerRadius(AppTheme.GeneratedRadius.card)
    }
} 