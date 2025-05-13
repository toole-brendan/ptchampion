import SwiftUI
import PTDesignSystem

/// A placeholder row shown during loading of leaderboard data
/// Uses a subtle animation to indicate the loading state
struct LeaderboardRowPlaceholder: View {
    @State private var isAnimating = false
    
    var body: some View {
VStack {
            HStack(spacing: Spacing.medium) {
                // Rank placeholder
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: CornerRadius.small)
                        .fill(Color.textTertiary.opacity(isAnimating ? 0.2 : 0.1))
                        .frame(width: 24, height: 20)
                    
                    Circle()
                        .fill(Color.textTertiary.opacity(isAnimating ? 0.2 : 0.1))
                        .frame(width: 14, height: 14)
                }
                .frame(width: 50, alignment: .leading)
                
                // Avatar placeholder
                Circle()
                    .fill(Color.textTertiary.opacity(isAnimating ? 0.3 : 0.15))
                    .frame(width: 32, height: 32)
                
                // Username placeholder
                RoundedRectangle(cornerRadius: CornerRadius.small)
                    .fill(Color.textTertiary.opacity(isAnimating ? 0.3 : 0.15))
                    .frame(height: 16)
                    .frame(maxWidth: .infinity)
                
                // Score placeholder
                RoundedRectangle(cornerRadius: CornerRadius.small)
                    .fill(Color.textTertiary.opacity(isAnimating ? 0.3 : 0.15))
                    .frame(width: 60, height: 18)
            }
            .padding(.vertical, Spacing.small)
        }
        .animation(.none, value: isAnimating) // Don't animate the card
        .onAppear {
            // Use a spring animation for the pulse effect
            withAnimation(Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

#if DEBUG
struct LeaderboardRowPlaceholder_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            VStack(spacing: Spacing.small) {
                LeaderboardRowPlaceholder()
                LeaderboardRowPlaceholder()
                LeaderboardRowPlaceholder()
            }
            .padding()
            .previewLayout(.fixed(width: 375, height: 200))
            .previewDisplayName("Light Mode")
            
            VStack(spacing: Spacing.small) {
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
