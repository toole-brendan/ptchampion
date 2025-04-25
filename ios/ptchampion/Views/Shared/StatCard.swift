import SwiftUI

enum Trend {
    case up(percentage: Int)
    case down(percentage: Int)
    case none
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let trend: Trend
    let color: Color
    let isHighlighted: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppConstants.Spacing.sm) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.custom(AppFonts.body, size: AppConstants.FontSize.sm))
                    .foregroundColor(.tacticalGray)
            }
            
            Text(value)
                .font(.custom(AppFonts.heading, size: AppConstants.FontSize.xl))
                .foregroundColor(color)
            
            // Trend indicator if available
            if case .up(let percentage) = trend {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 12))
                        .foregroundColor(.deepOpsGreen)
                    
                    Text("+\(percentage)%")
                        .font(.custom(AppFonts.body, size: AppConstants.FontSize.xs))
                        .foregroundColor(.deepOpsGreen)
                }
            } else if case .down(let percentage) = trend {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down")
                        .font(.system(size: 12))
                        .foregroundColor(.tomahawkRed)
                    
                    Text("-\(percentage)%")
                        .font(.custom(AppFonts.body, size: AppConstants.FontSize.xs))
                        .foregroundColor(.tomahawkRed)
                }
            } else {
                Text("No change")
                    .font(.custom(AppFonts.body, size: AppConstants.FontSize.xs))
                    .foregroundColor(.tacticalGray)
                    .opacity(0.8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppConstants.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppConstants.Radius.md)
                .fill(isHighlighted ? color.opacity(0.1) : Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppConstants.Radius.md)
                .stroke(isHighlighted ? color : Color.clear, lineWidth: 1)
        )
    }
}

// MARK: - Leaderboard Row

struct LeaderboardRow: View {
    let rank: Int
    let name: String
    let score: String
    let avatarURL: URL?
    let isCurrentUser: Bool
    
    var body: some View {
        HStack(spacing: AppConstants.Spacing.md) {
            // Rank with medal for top 3
            if rank <= 3 {
                ZStack {
                    Circle()
                        .fill(Color.brassGold.opacity(0.1))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "medal.fill")
                        .foregroundColor(Color.brassGold)
                        .font(.system(size: 18))
                }
            } else {
                Text("\(rank)")
                    .font(.custom(AppFonts.mono, size: AppConstants.FontSize.lg))
                    .foregroundColor(.tacticalGray)
                    .frame(width: 36)
            }
            
            // Avatar
            if let avatarURL = avatarURL {
                AsyncImage(url: avatarURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure(_), .empty:
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .foregroundColor(Color.tacticalGray.opacity(0.5))
                    @unknown default:
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .foregroundColor(Color.tacticalGray.opacity(0.5))
                    }
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
                    .foregroundColor(Color.tacticalGray.opacity(0.5))
            }
            
            // Name
            Text(name)
                .font(.custom(AppFonts.body, size: AppConstants.FontSize.md))
                .foregroundColor(isCurrentUser ? .brassGold : .commandBlack)
                .fontWeight(isCurrentUser ? .bold : .regular)
            
            Spacer()
            
            // Score
            Text(score)
                .font(.custom(AppFonts.mono, size: AppConstants.FontSize.md))
                .foregroundColor(.commandBlack)
                .fontWeight(.medium)
        }
        .padding(AppConstants.Spacing.md)
        .background(isCurrentUser ? Color.brassGold.opacity(0.05) : Color.white)
        .cornerRadius(AppConstants.Radius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AppConstants.Radius.md)
                .stroke(isCurrentUser ? Color.brassGold.opacity(0.5) : Color.clear, lineWidth: 1)
        )
    }
}

// MARK: - Preview
struct StatCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            StatCard(
                title: "Best Session",
                value: "45",
                icon: "trophy.fill",
                trend: .none,
                color: .brassGold,
                isHighlighted: false
            )
            
            StatCard(
                title: "This Week",
                value: "120",
                icon: "calendar",
                trend: .up(percentage: 15),
                color: .deepOpsGreen,
                isHighlighted: true
            )
            
            StatCard(
                title: "Last Month",
                value: "430",
                icon: "chart.bar.fill",
                trend: .down(percentage: 5),
                color: .tacticalGray,
                isHighlighted: false
            )
        }
        .padding()
        .background(Color.tacticalCream.opacity(0.3))
        .previewLayout(.sizeThatFits)
    }
} 