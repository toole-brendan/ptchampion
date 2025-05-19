import SwiftUI
import PTDesignSystem

struct WorkoutStreaksView: View {
    let currentStreak: Int
    let longestStreak: Int
    
    var body: some View {
        HStack(spacing: AppTheme.GeneratedSpacing.medium) {
            // Current streak card
            PTCard(style: .elevated) {
                VStack(alignment: .center, spacing: AppTheme.GeneratedSpacing.small) {
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(AppTheme.GeneratedColors.brassGold)
                            .font(.system(size: 14))
                        
                        Text("Current Streak")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                    }
                    
                    Text("\(currentStreak)")
                        .font(.system(size: 36, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                    
                    Text("days")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppTheme.GeneratedColors.textTertiary)
                        .offset(y: -5)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.GeneratedSpacing.medium)
            }
            
            // Longest streak card
            PTCard(style: .elevated) {
                VStack(alignment: .center, spacing: AppTheme.GeneratedSpacing.small) {
                    HStack(spacing: 6) {
                        Image(systemName: "crown.fill")
                            .foregroundColor(AppTheme.GeneratedColors.brassGold)
                            .font(.system(size: 14))
                        
                        Text("Longest Streak")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                    }
                    
                    Text("\(longestStreak)")
                        .font(.system(size: 36, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                    
                    Text("days")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppTheme.GeneratedColors.textTertiary)
                        .offset(y: -5)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.GeneratedSpacing.medium)
            }
        }
    }
}

#Preview {
    WorkoutStreaksView(currentStreak: 3, longestStreak: 7)
        .previewLayout(.sizeThatFits)
        .padding()
} 