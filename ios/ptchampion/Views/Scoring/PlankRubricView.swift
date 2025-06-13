import SwiftUI
import PTDesignSystem

struct PlankRubricView: View {
    @Environment(\.dismiss) private var dismiss
    
    // USMC PFT Plank scoring note
    private let scoringNote = """
    USMC PFT Plank Scoring
    • Universal scoring for all ages and genders
    • Maximum time: 3:45 (100 points)
    • Minimum time: 1:03 (40 points)
    • Replaces sit-ups in USMC PFT
    """
    
    // Helper function to generate plank times
    private func generatePlankTimes() -> [(seconds: Int, score: Int)] {
        let maxSeconds = 225 // 3:45
        let minSeconds = 63  // 1:03
        
        var plankTimes: [(seconds: Int, score: Int)] = []
        var currentTime = maxSeconds
        while currentTime >= minSeconds {
            let score = USMCPFTScoring.scorePlank(seconds: currentTime)
            plankTimes.append((seconds: currentTime, score: score))
            currentTime -= 3 // Show every 3 seconds
        }
        return plankTimes
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                Text("USMC PLANK SCORING")
                    .militaryMonospaced(size: 18)
                    .foregroundColor(AppTheme.GeneratedColors.deepOps)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.95))
                
                // Scoring note
                Text(scoringNote)
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.GeneratedColors.deepOps)
                    .multilineTextAlignment(.leading)
                    .padding()
                    .background(Color.yellow.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                
                // Note about universal scoring
                Text("Universal scoring applies to all ages and genders")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.GeneratedColors.deepOps)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                
                // Scrollable scoring table
                ScrollView {
                    VStack(spacing: 0) {
                        // Table header
                        HStack(spacing: 0) {
                            Text("TIME")
                                .militaryMonospaced(size: 16)
                                .foregroundColor(AppTheme.GeneratedColors.brassGold)
                                .frame(width: 120, height: 44)
                                .background(Color.gray.opacity(0.1))
                                .border(Color.gray.opacity(0.3), width: 1)
                            
                            Text("POINTS")
                                .militaryMonospaced(size: 16)
                                .foregroundColor(AppTheme.GeneratedColors.brassGold)
                                .frame(width: 120, height: 44)
                                .background(Color.gray.opacity(0.1))
                                .border(Color.gray.opacity(0.3), width: 1)
                        }
                        
                        // Data rows
                        let plankTimes = generatePlankTimes()
                        ForEach(Array(plankTimes.enumerated()), id: \.offset) { index, timeData in
                            let minutes = timeData.seconds / 60
                            let seconds = timeData.seconds % 60
                            
                            HStack(spacing: 0) {
                                Text(String(format: "%d:%02d", minutes, seconds))
                                    .militaryMonospaced(size: 16)
                                    .foregroundColor(AppTheme.GeneratedColors.deepOps)
                                    .frame(width: 120, height: 40)
                                    .background(index % 2 == 0 ? Color.white : Color.gray.opacity(0.05))
                                    .border(Color.gray.opacity(0.3), width: 1)
                                
                                Text("\(timeData.score)")
                                    .militaryMonospaced(size: 16)
                                    .foregroundColor(AppTheme.GeneratedColors.deepOps)
                                    .frame(width: 120, height: 40)
                                    .background(index % 2 == 0 ? Color.white : Color.gray.opacity(0.05))
                                    .border(Color.gray.opacity(0.3), width: 1)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
} 