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
    let result: WorkoutResult
    let exerciseGrader: AnyExerciseGraderBox
    @Environment(\.dismiss) var dismiss
    @State private var showingShareSheet = false
    @State private var celebrationAnimation = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    result.exerciseType.color.opacity(0.8),
                    result.exerciseType.color.opacity(0.4)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 30) {
                    // Header with celebration
                    VStack(spacing: 20) {
                        // Celebration icon
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 120, height: 120)
                                .scaleEffect(celebrationAnimation ? 1.1 : 1.0)
                            
                            Image(systemName: "trophy.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.yellow)
                        }
                        .onAppear {
                            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                                celebrationAnimation = true
                            }
                        }
                        
                        VStack(spacing: 10) {
                            Text("Workout Complete!")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Great job on your \(result.exerciseType.displayName.lowercased())!")
                                .font(.title3)
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                    .padding(.top, 50)
                    
                    // Main stats cards
                    VStack(spacing: 20) {
                        // Rep count card
                        WorkoutStatCard(
                            title: "Total Reps",
                            value: "\(result.totalReps)",
                            icon: "number.circle.fill",
                            color: .white
                        )
                        
                        // Duration card
                        WorkoutStatCard(
                            title: "Duration",
                            value: formatDuration(result.duration),
                            icon: "clock.fill",
                            color: .white
                        )
                        
                        // Form score card
                        WorkoutStatCard(
                            title: "Average Form",
                            value: "\(Int(exerciseGrader.formQualityAverage * 100))%",
                            icon: "star.fill",
                            color: formScoreColor
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    // Detailed breakdown
                    if !result.repDetails.isEmpty {
                        VStack(spacing: 15) {
                            Text("Rep Breakdown")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            RepBreakdownChart(repDetails: result.repDetails)
                                .frame(height: 200)
                                .padding(.horizontal, 20)
                        }
                        .padding(.vertical, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white.opacity(0.1))
                        )
                        .padding(.horizontal, 20)
                    }
                    
                    // Personal best indicator
                    if result.isPersonalBest {
                        PersonalBestBanner()
                            .padding(.horizontal, 20)
                    }
                    
                    // Action buttons
                    VStack(spacing: 15) {
                        Button(action: {
                            showingShareSheet = true
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share Results")
                            }
                            .font(.headline)
                            .foregroundColor(result.exerciseType.color)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.white)
                            .cornerRadius(25)
                        }
                        
                        Button("Done") {
                            dismiss()
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(25)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 50)
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(activityItems: [createShareText()])
        }
    }
    
    private var formScoreColor: Color {
        let score = exerciseGrader.formQualityAverage
        if score >= 0.8 {
            return .green
        } else if score >= 0.6 {
            return .yellow
        } else {
            return .red
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func createShareText() -> String {
        let formPercentage = Int(exerciseGrader.formQualityAverage * 100)
        return """
        Just completed my \(result.exerciseType.displayName.lowercased()) workout! 💪
        
        📊 Results:
        • \(result.totalReps) reps
        • \(formatDuration(result.duration)) duration
        • \(formPercentage)% average form
        
        #PTChampion #Fitness #\(result.exerciseType.displayName.replacingOccurrences(of: "-", with: ""))
        """
    }
}

// MARK: - Supporting Views

struct WorkoutStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(color)
                .frame(width: 50, height: 50)
                .background(Circle().fill(color.opacity(0.2)))
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white.opacity(0.1))
        )
    }
}

struct RepBreakdownChart: View {
    let repDetails: [RepDetail]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Form Quality by Rep")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                HStack(spacing: 15) {
                    LegendItem(color: .green, label: "Good")
                    LegendItem(color: .yellow, label: "Fair")
                    LegendItem(color: .red, label: "Poor")
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(repDetails.enumerated()), id: \.offset) { index, rep in
                        VStack(spacing: 5) {
                            Rectangle()
                                .fill(qualityColor(for: rep.formQuality))
                                .frame(width: 20, height: CGFloat(rep.formQuality * 150))
                                .cornerRadius(2)
                            
                            Text("\(index + 1)")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }
                .padding(.horizontal, 10)
            }
        }
    }
    
    private func qualityColor(for quality: Double) -> Color {
        if quality >= 0.8 {
            return .green
        } else if quality >= 0.6 {
            return .yellow
        } else {
            return .red
        }
    }
}

struct LegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.8))
        }
    }
}

struct PersonalBestBanner: View {
    @State private var sparkleAnimation = false
    
    var body: some View {
        HStack {
            Image(systemName: "crown.fill")
                .foregroundColor(.yellow)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Personal Best!")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("You've set a new record!")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            Image(systemName: "sparkles")
                .foregroundColor(.yellow)
                .font(.title2)
                .scaleEffect(sparkleAnimation ? 1.2 : 1.0)
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                        sparkleAnimation = true
                    }
                }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.yellow.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.yellow.opacity(0.5), lineWidth: 2)
                )
        )
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    let sampleResult = WorkoutResult(
        id: UUID(),
        exerciseType: .pushup,
        totalReps: 25,
        duration: 180,
        timestamp: Date(),
        repDetails: [
            RepDetail(repNumber: 1, formQuality: 0.9, timestamp: Date()),
            RepDetail(repNumber: 2, formQuality: 0.8, timestamp: Date()),
            RepDetail(repNumber: 3, formQuality: 0.7, timestamp: Date())
        ],
        isPersonalBest: true
    )
    
    let grader = EnhancedPushupGrader()
    
    WorkoutCompleteView(
        result: sampleResult,
        exerciseGrader: AnyExerciseGraderBox(grader)
    )
} 