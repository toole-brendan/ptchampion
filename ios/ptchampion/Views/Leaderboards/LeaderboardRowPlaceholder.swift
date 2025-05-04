import SwiftUI
import PTDesignSystem

/// A placeholder row shown during loading of leaderboard data
/// Uses a subtle animation to indicate the loading state
struct LeaderboardRowPlaceholder: View {
    @State private var isAnimating = false
    
    var body: some View {
        PTCard {
            HStack {
                // Rank placeholder
                Text("#")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.clear)
                    .frame(width: 32, alignment: .center)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.GeneratedRadius.small)
                            .fill(AppTheme.GeneratedColors.textTertiary.opacity(isAnimating ? 0.3 : 0.2))
                            .frame(width: 28, height: 28)
                    )
                
                // Avatar placeholder
                Circle()
                    .fill(AppTheme.GeneratedColors.textTertiary.opacity(isAnimating ? 0.3 : 0.2))
                    .frame(width: 40, height: 40)
                    .padding(.leading, 4)
                
                // Username placeholder
                VStack(alignment: .leading, spacing: 4) {
                    RoundedRectangle(cornerRadius: AppTheme.GeneratedRadius.small)
                        .fill(AppTheme.GeneratedColors.textTertiary.opacity(isAnimating ? 0.3 : 0.2))
                        .frame(width: 120, height: 16)
                }
                .padding(.leading, AppTheme.GeneratedSpacing.small)
                
                Spacer()
                
                // Score placeholder
                RoundedRectangle(cornerRadius: AppTheme.GeneratedRadius.small)
                    .fill(AppTheme.GeneratedColors.textTertiary.opacity(isAnimating ? 0.3 : 0.2))
                    .frame(width: 50, height: 16)
            }
            .padding(AppTheme.GeneratedSpacing.small)
        }
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 1.0).repeatForever()) {
                isAnimating = true
            }
        }
    }
}

#if DEBUG
struct LeaderboardRowPlaceholder_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            VStack(spacing: AppTheme.GeneratedSpacing.small) {
                LeaderboardRowPlaceholder()
                LeaderboardRowPlaceholder()
                LeaderboardRowPlaceholder()
            }
            .padding()
            .previewLayout(.fixed(width: 375, height: 200))
            .previewDisplayName("Light Mode")
            
            VStack(spacing: AppTheme.GeneratedSpacing.small) {
                LeaderboardRowPlaceholder()
                LeaderboardRowPlaceholder()
            }
            .padding()
            .previewLayout(.fixed(width: 375, height: 200))
            .environment(\.colorScheme, .dark)
            .previewDisplayName("Dark Mode")
        }
    }
}
#endif 