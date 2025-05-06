import SwiftUI
import PTDesignSystem
import SwiftData // For WorkoutResultSwiftData

struct WorkoutCompleteView: View {
    let result: WorkoutResultSwiftData? // Uncommented
    let exerciseGrader: any ExerciseGraderProtocol // Uncommented
    
    @Environment(\.dismiss) var dismiss
    @State private var isShowingShareSheet = false
    @State private var shareText: String = ""

    var body: some View {
        // Text("Workout Complete Placeholder") // Simplified body
        NavigationView { // Added NavigationView for a title and potential toolbar items
            ScrollView {
                VStack(spacing: AppTheme.GeneratedSpacing.large) {
                    PTLabel("Workout Complete!", style: .heading)
                        .padding(.vertical, AppTheme.GeneratedSpacing.large) // TODO: Consider adding .extraLarge to GeneratedSpacing or use .large

                    if let savedResult = result {
                        summaryCard(savedResult)
                        
                        // Badges Section (Placeholder)
                        badgesSection() // Restored call
                        
                    } else {
                        PTLabel("Could not retrieve workout details.", style: .body)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                    
                    Spacer(minLength: AppTheme.GeneratedSpacing.large)
                    
                    actionButtons()
                    
                }
                .padding(AppTheme.GeneratedSpacing.large)
            }
            .background(AppTheme.GeneratedColors.background.ignoresSafeArea())
            .navigationTitle(result != nil ? (ExerciseType(rawValue: result!.exerciseType)?.displayName ?? "Summary") : "Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.GeneratedColors.primary) // Use design system color
                }
            }
            .sheet(isPresented: $isShowingShareSheet) {
                if !shareText.isEmpty {
                    ActivityView(activityItems: [shareText])
                }
            }
        }
        .onAppear {
            if let savedResult = result { // Uncommented
                generateShareText(for: savedResult) // Uncommented
            }
        }
    }

    // Uncommenting methods that use the properties
    @ViewBuilder
    private func summaryCard(_ savedResult: WorkoutResultSwiftData) -> some View {
        PTCard() { 
            VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.medium) {
                PTLabel("Summary", style: .subheading)
                    .padding(.bottom, AppTheme.GeneratedSpacing.small)
                
                detailRow(label: "Exercise", value: ExerciseType(rawValue: savedResult.exerciseType)?.displayName ?? "N/A")
                detailRow(label: "Reps", value: "\(savedResult.repCount ?? 0)")
                detailRow(label: "Duration", value: formatDuration(savedResult.durationSeconds))
                
                if let score = savedResult.score {
                    detailRow(label: "Score", value: "\(Int(score))%", highlight: true)
                }
                
                let avgFormQuality = exerciseGrader.formQualityAverage // Uncommented
                if avgFormQuality > 0 { // Uncommented
                    detailRow(label: "Avg. Form Quality", value: "\(Int(avgFormQuality * 100))%", highlight: avgFormQuality > 0.8) // Uncommented
                }
            }
            .padding(AppTheme.GeneratedSpacing.medium)
        }
    }
    
    @ViewBuilder
    private func badgesSection() -> some View {
        VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.small) {
            PTLabel("Badges Earned", style: .subheading)
            // Placeholder for badges - replace with actual badge display logic
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    BadgePlaceholderView(icon: "star.fill", label: "New PR!")
                    BadgePlaceholderView(icon: "flame.fill", label: "3 Day Streak")
                    BadgePlaceholderView(icon: "figure.walk", label: "First Pushups")
                }
                .padding(.vertical, AppTheme.GeneratedSpacing.small)
            }
        }
        .padding(AppTheme.GeneratedSpacing.medium)
        .background(AppTheme.GeneratedColors.cardBackground)
        .cornerRadius(AppTheme.GeneratedRadius.card)
        // .modifier(PTCardStyleShadow()) // TODO: Define or import PTCardStyleShadow
    }
    
    @ViewBuilder
    private func actionButtons() -> some View {
        VStack(spacing: AppTheme.GeneratedSpacing.medium) {
            PTButton("Share Workout", style: .secondary, icon: Image(systemName: "square.and.arrow.up")) {
                if result != nil { // Uncommented
                    isShowingShareSheet = true // Uncommented
                } else {
                    // Optionally show an alert if there's nothing to share
                    print("No workout data to share.")
                }
            }
            
            PTButton("Done", style: .primary) {
                dismiss()
            }
        }
    }

    @ViewBuilder
    private func detailRow(label: String, value: String, highlight: Bool = false) -> some View {
        HStack {
            PTLabel(label, style: .body)
            Spacer()
            PTLabel(value, style: .bodyBold)
                .foregroundColor(highlight ? AppTheme.GeneratedColors.primary : AppTheme.GeneratedColors.textPrimary) 
        }
    }
    
    private func generateShareText(for savedResult: WorkoutResultSwiftData) {
        var text = "Check out my PT Champion workout!\n"
        text += "Exercise: \(ExerciseType(rawValue: savedResult.exerciseType)?.displayName ?? "N/A")\n"
        text += "Reps: \(savedResult.repCount ?? 0)\n"
        text += "Duration: \(formatDuration(savedResult.durationSeconds))\n"
        if let score = savedResult.score {
            text += "Score: \(Int(score))%\n"
        }
        let avgFormQuality = exerciseGrader.formQualityAverage // Uncommented
        if avgFormQuality > 0 { // Uncommented
            text += "Avg. Form: \(Int(avgFormQuality * 100))%\n" // Uncommented
        }
        // TODO: Add a link to the app or a relevant webpage if applicable
        shareText = text
    }

    private func formatDuration(_ totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// Placeholder for Badge View - to be replaced with actual Badge component if it exists
struct BadgePlaceholderView: View {
    let icon: String
    let label: String
    var body: some View {
        // Text("Placeholder") // Simplified to a single Text view
        VStack { // Restoring VStack and its content
            Image(systemName: icon)
             .font(.largeTitle)
             .foregroundColor(AppTheme.GeneratedColors.brassGold)
             .frame(width: 60, height: 60)
             .background(AppTheme.GeneratedColors.brassGold.opacity(0.1))
             .clipShape(Circle())
            Text(label).font(.caption) // Using Text view that worked before
        }
        .padding(AppTheme.GeneratedSpacing.small)
    }
}

// Preview
// Commenting out Preview as it depends on the properties
#if DEBUG
struct WorkoutCompleteView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a mock WorkoutResultSwiftData for preview
        let mockResult = WorkoutResultSwiftData(
            exerciseType: "pushup", 
            startTime: Date().addingTimeInterval(-300), 
            endTime: Date(), 
            durationSeconds: 300, 
            repCount: 25, 
            score: 88.0
        )
        let mockGrader = PlaceholderGrader() // Using PlaceholderGrader for stability
        // mockGrader.resetState() // Populate with some mock data if needed for form avg
        
        // Ensure ExerciseType is available for the preview context
        // For example, by having a simple version or mock within #if DEBUG
        WorkoutCompleteView(result: mockResult, exerciseGrader: mockGrader) // Restored preview call
        // Text("Preview disabled for debugging")
    }
}
#endif 