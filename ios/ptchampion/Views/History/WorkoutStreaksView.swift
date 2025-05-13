import SwiftUI
import PTDesignSystem

struct WorkoutStreaksView: View {
    let currentStreak: Int
    let longestStreak: Int
    
    var body: some View {
        HStack(spacing: Spacing.medium) {
            // Current streak card
VStack {
                VStack(alignment: .center, spacing: Spacing.small) {
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(ThemeColor.brassGold)
                            .small()
                        
                        Text("Current Streak")
                            .small(weight: .medium)
                            .foregroundColor(ThemeColor.textSecondary)
                    }
                    
                    Text("\(currentStreak)")
                        .font(.system(size: 36, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundColor(ThemeColor.textPrimary)
                    
                    Text("days")
                        .small(weight: .medium)
                        .foregroundColor(ThemeColor.textTertiary)
                        .offset(y: -5)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.medium)
            }
            
            // Longest streak card
VStack {
                VStack(alignment: .center, spacing: Spacing.small) {
                    HStack(spacing: 6) {
                        Image(systemName: "crown.fill")
                            .foregroundColor(ThemeColor.brassGold)
                            .small()
                        
                        Text("Longest Streak")
                            .small(weight: .medium)
                            .foregroundColor(ThemeColor.textSecondary)
                    }
                    
                    Text("\(longestStreak)")
                        .font(.system(size: 36, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundColor(ThemeColor.textPrimary)
                    
                    Text("days")
                        .small(weight: .medium)
                        .foregroundColor(ThemeColor.textTertiary)
                        .offset(y: -5)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.medium)
            }
        }
        .padding(.horizontal, Spacing.contentPadding)
    }
}

#Preview {
    WorkoutStreaksView(currentStreak: 3, longestStreak: 7)
        .previewLayout(.sizeThatFits)
        .padding()
}
