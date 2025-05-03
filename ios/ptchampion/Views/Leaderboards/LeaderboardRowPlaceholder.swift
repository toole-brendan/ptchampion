import SwiftUI

/// A placeholder row shown during loading of leaderboard data
/// Uses a subtle animation to indicate the loading state
struct LeaderboardRowPlaceholder: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack {
            // Rank placeholder
            Text("#")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.clear)
                .frame(width: 32, alignment: .center)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(isAnimating ? 0.3 : 0.2))
                        .frame(width: 28, height: 28)
                )
            
            // Avatar placeholder
            Circle()
                .fill(Color.gray.opacity(isAnimating ? 0.3 : 0.2))
                .frame(width: 40, height: 40)
                .padding(.leading, 4)
            
            // Username placeholder
            VStack(alignment: .leading, spacing: 4) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(isAnimating ? 0.3 : 0.2))
                    .frame(width: 120, height: 16)
            }
            .padding(.leading, 8)
            
            Spacer()
            
            // Score placeholder
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(isAnimating ? 0.3 : 0.2))
                .frame(width: 50, height: 16)
        }
        .frame(height: 60)
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
        VStack {
            LeaderboardRowPlaceholder()
            LeaderboardRowPlaceholder()
            LeaderboardRowPlaceholder()
        }
        .padding()
        .previewLayout(.fixed(width: 375, height: 200))
    }
}
#endif 