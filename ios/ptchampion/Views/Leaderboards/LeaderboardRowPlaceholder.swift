import SwiftUI
import PTDesignSystem

/// A placeholder row shown during loading of leaderboard data
/// Uses a smooth shimmer animation to indicate the loading state
struct LeaderboardRowPlaceholder: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Rank badge placeholder (circular to match new design)
            Circle()
                .fill(shimmerGradient)
                .frame(width: 44, height: 44)
            
            // User info placeholder
            VStack(alignment: .leading, spacing: 6) {
                // Name placeholder
                RoundedRectangle(cornerRadius: 4)
                    .fill(shimmerGradient)
                    .frame(width: 120, height: 16)
                
                // Location/details placeholder
                RoundedRectangle(cornerRadius: 4)
                    .fill(shimmerGradient)
                    .frame(width: 80, height: 12)
            }
            
            Spacer()
            
            // Score placeholder
            VStack(alignment: .trailing, spacing: 4) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(shimmerGradient)
                    .frame(width: 60, height: 20)
                
                // Subtitle placeholder
                RoundedRectangle(cornerRadius: 4)
                    .fill(shimmerGradient)
                    .frame(width: 40, height: 11)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
    }
    
    private var shimmerGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.gray.opacity(0.3),
                Color.gray.opacity(0.1),
                Color.gray.opacity(0.3)
            ]),
            startPoint: isAnimating ? .leading : .trailing,
            endPoint: isAnimating ? .trailing : .leading
        )
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
                LeaderboardRowPlaceholder()
                LeaderboardRowPlaceholder()
            }
            .padding()
            .background(Color.white)
            .previewLayout(.fixed(width: 375, height: 400))
            .previewDisplayName("Enhanced Shimmer - Light")
            
            VStack(spacing: AppTheme.GeneratedSpacing.small) {
                LeaderboardRowPlaceholder()
                LeaderboardRowPlaceholder()
                LeaderboardRowPlaceholder()
            }
            .padding()
            .background(AppTheme.GeneratedColors.background)
            .previewLayout(.fixed(width: 375, height: 300))
            .environment(\.colorScheme, .dark)
            .previewDisplayName("Enhanced Shimmer - Dark")
        }
    }
}
#endif 