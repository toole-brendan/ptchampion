import SwiftUI
import PTDesignSystem

struct PlankRubricView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Scrollable content area
                ScrollView {
                    VStack(spacing: 0) {
                        // Spacer to push content below the header
                        Spacer()
                            .frame(height: 120)
                        
                        // USMC Plank Details
                        VStack(alignment: .leading, spacing: 12) {
                            Text("USMC PFT Plank Scoring")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(AppTheme.GeneratedColors.deepOps)
                            
                            Text("• Universal scoring for all ages and genders")
                                .font(.system(size: 16))
                                .foregroundColor(AppTheme.GeneratedColors.deepOps)
                            
                            Text("• Maximum time: 3:45 (100 points)")
                                .font(.system(size: 16))
                                .foregroundColor(AppTheme.GeneratedColors.deepOps)
                            
                            Text("• Minimum time: 1:03 (40 points)")
                                .font(.system(size: 16))
                                .foregroundColor(AppTheme.GeneratedColors.deepOps)
                            
                            Text("• Replaces sit-ups in USMC PFT")
                                .font(.system(size: 16))
                                .foregroundColor(AppTheme.GeneratedColors.deepOps)
                        }
                        .padding()
                        .padding(.horizontal)
                        
                        // Table Header
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
                        
                        // Show scoring data
                        // Generate plank times from 3:45 down to 1:03 (every 3 seconds for display)
                        let maxSeconds = 225 // 3:45
                        let minSeconds = 63  // 1:03
                        
                        var plankTimes: [(seconds: Int, score: Int)] = []
                        var currentTime = maxSeconds
                        while currentTime >= minSeconds {
                            let score = USMCPFTScoring.scorePlank(seconds: currentTime)
                            plankTimes.append((seconds: currentTime, score: score))
                            currentTime -= 3 // Show every 3 seconds
                        }
                        
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
                        
                        Spacer(minLength: 20)
                    }
                    .frame(maxWidth: .infinity)
                }
                
                // Fixed header that stays at the top
                VStack {
                    Text("USMC PLANK SCORING")
                        .militaryMonospaced(size: 16)
                        .foregroundColor(AppTheme.GeneratedColors.deepOps)
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity)
                        .background(Color.white.opacity(0.95))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
} 