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
        VStack(alignment: .leading, spacing: AppTheme.Spacing.itemSpacing) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                
                Text(title)
                    .font(AppTheme.Typography.body(size: 13))
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }
            
            Text(value)
                .font(AppTheme.Typography.heading3())
                .foregroundColor(color)
            
            // Trend indicator if available
            if case .up(let percentage) = trend {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.Colors.success)
                    
                    Text("+\(percentage)%")
                        .font(AppTheme.Typography.body(size: 12))
                        .foregroundColor(AppTheme.Colors.success)
                }
            } else if case .down(let percentage) = trend {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.Colors.error)
                    
                    Text("-\(percentage)%")
                        .font(AppTheme.Typography.body(size: 12))
                        .foregroundColor(AppTheme.Colors.error)
                }
            } else {
                Text("No change")
                    .font(AppTheme.Typography.body(size: 12))
                    .foregroundColor(AppTheme.Colors.textTertiary)
                    .opacity(0.8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.Spacing.contentPadding)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                .fill(isHighlighted ? color.opacity(0.1) : AppTheme.Colors.cardBackground)
                .withShadow(AppTheme.Shadows.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.card)
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
        HStack(spacing: AppTheme.Spacing.contentPadding) {
            // Rank with medal for top 3
            if rank <= 3 {
                ZStack {
                    Circle()
                        .fill(AppTheme.Colors.brassGold.opacity(0.1))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "medal.fill")
                        .foregroundColor(AppTheme.Colors.brassGold)
                        .font(.system(size: 18))
                }
            } else {
                Text("\(rank)")
                    .font(AppTheme.Typography.mono(size: 16))
                    .foregroundColor(AppTheme.Colors.textTertiary)
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
                            .foregroundColor(AppTheme.Colors.textTertiary.opacity(0.5))
                    @unknown default:
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .foregroundColor(AppTheme.Colors.textTertiary.opacity(0.5))
                    }
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
                    .foregroundColor(AppTheme.Colors.textTertiary.opacity(0.5))
            }
            
            // Name
            Text(name)
                .font(isCurrentUser ? AppTheme.Typography.bodyBold() : AppTheme.Typography.body())
                .foregroundColor(isCurrentUser ? AppTheme.Colors.brassGold : AppTheme.Colors.textPrimary)
            
            Spacer()
            
            // Score
            Text(score)
                .font(AppTheme.Typography.mono())
                .foregroundColor(AppTheme.Colors.textPrimary)
                .fontWeight(.medium)
        }
        .padding(AppTheme.Spacing.contentPadding)
        .background(isCurrentUser ? AppTheme.Colors.brassGold.opacity(0.05) : AppTheme.Colors.cardBackground)
        .cornerRadius(AppTheme.Radius.card)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                .stroke(isCurrentUser ? AppTheme.Colors.brassGold.opacity(0.5) : Color.clear, lineWidth: 1)
        )
    }
}

// MARK: - Preview
struct StatCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: AppTheme.Spacing.cardGap) {
            StatCard(
                title: "Best Session",
                value: "45",
                icon: "trophy.fill",
                trend: .none,
                color: AppTheme.Colors.brassGold,
                isHighlighted: false
            )
            
            StatCard(
                title: "This Week",
                value: "120",
                icon: "calendar",
                trend: .up(percentage: 15),
                color: AppTheme.Colors.deepOps,
                isHighlighted: true
            )
            
            StatCard(
                title: "Last Month",
                value: "430",
                icon: "chart.bar.fill",
                trend: .down(percentage: 5),
                color: AppTheme.Colors.tacticalGray,
                isHighlighted: false
            )
        }
        .padding()
        .background(AppTheme.Colors.background.opacity(0.3))
        .previewLayout(.sizeThatFits)
    }
} 