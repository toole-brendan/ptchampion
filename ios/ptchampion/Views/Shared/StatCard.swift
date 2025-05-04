import SwiftUI
import PTDesignSystem
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
        VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.itemSpacing) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                
                Text(title)
                    .font(AppTheme.GeneratedTypography.caption())
                    .foregroundColor(AppTheme.GeneratedColors.textTertiary)
            }
            
            Text(value)
                .font(AppTheme.GeneratedTypography.title())
                .foregroundColor(color)
            
            // Trend indicator if available
            if case .up(let percentage) = trend {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.GeneratedColors.success)
                    
                    Text("+\(percentage)%")
                        .font(AppTheme.GeneratedTypography.caption())
                        .foregroundColor(AppTheme.GeneratedColors.success)
                }
            } else if case .down(let percentage) = trend {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.GeneratedColors.error)
                    
                    Text("-\(percentage)%")
                        .font(AppTheme.GeneratedTypography.caption())
                        .foregroundColor(AppTheme.GeneratedColors.error)
                }
            } else {
                Text("No change")
                    .font(AppTheme.GeneratedTypography.caption())
                    .foregroundColor(AppTheme.GeneratedColors.textTertiary)
                    .opacity(0.8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.GeneratedSpacing.contentPadding)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.GeneratedRadius.card)
                .fill(isHighlighted ? color.opacity(0.1) : AppTheme.GeneratedColors.cardBackground)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.GeneratedRadius.card)
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
        HStack(spacing: AppTheme.GeneratedSpacing.contentPadding) {
            // Rank with medal for top 3
            if rank <= 3 {
                ZStack {
                    Circle()
                        .fill(AppTheme.GeneratedColors.brassGold.opacity(0.1))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "medal.fill")
                        .foregroundColor(AppTheme.GeneratedColors.brassGold)
                        .font(.system(size: 18))
                }
            } else {
                Text("\(rank)")
                    .font(AppTheme.GeneratedTypography.mono())
                    .foregroundColor(AppTheme.GeneratedColors.textTertiary)
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
                            .foregroundColor(AppTheme.GeneratedColors.textTertiary.opacity(0.5))
                    @unknown default:
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .foregroundColor(AppTheme.GeneratedColors.textTertiary.opacity(0.5))
                    }
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
                    .foregroundColor(AppTheme.GeneratedColors.textTertiary.opacity(0.5))
            }
            
            // Name
            Text(name)
                .font(isCurrentUser ? AppTheme.GeneratedTypography.bodyBold() : AppTheme.GeneratedTypography.body())
                .foregroundColor(isCurrentUser ? AppTheme.GeneratedColors.brassGold : AppTheme.GeneratedColors.textPrimary)
            
            Spacer()
            
            // Score
            Text(score)
                .font(AppTheme.GeneratedTypography.mono())
                .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                .fontWeight(.medium)
        }
        .padding(AppTheme.GeneratedSpacing.contentPadding)
        .background(isCurrentUser ? AppTheme.GeneratedColors.brassGold.opacity(0.05) : AppTheme.GeneratedColors.cardBackground)
        .cornerRadius(AppTheme.GeneratedRadius.card)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.GeneratedRadius.card)
                .stroke(isCurrentUser ? AppTheme.GeneratedColors.brassGold.opacity(0.5) : Color.clear, lineWidth: 1)
        )
    }
}

// MARK: - Preview
struct StatCard_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            VStack(spacing: AppTheme.GeneratedSpacing.itemSpacing) {
                StatCard(
                    title: "Best Session",
                    value: "45",
                    icon: "trophy.fill",
                    trend: .none,
                    color: AppTheme.GeneratedColors.brassGold,
                    isHighlighted: false
                )
                
                StatCard(
                    title: "This Week",
                    value: "120",
                    icon: "calendar",
                    trend: .up(percentage: 15),
                    color: AppTheme.GeneratedColors.deepOps,
                    isHighlighted: true
                )
                
                StatCard(
                    title: "Last Month",
                    value: "430",
                    icon: "chart.bar.fill",
                    trend: .down(percentage: 5),
                    color: AppTheme.GeneratedColors.tacticalGray,
                    isHighlighted: false
                )
            }
            .padding()
            .background(AppTheme.GeneratedColors.background)
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Light Mode")
            
            VStack(spacing: AppTheme.GeneratedSpacing.itemSpacing) {
                StatCard(
                    title: "Best Session",
                    value: "45",
                    icon: "trophy.fill",
                    trend: .none,
                    color: AppTheme.GeneratedColors.brassGold,
                    isHighlighted: false
                )
                
                StatCard(
                    title: "This Week",
                    value: "120",
                    icon: "calendar",
                    trend: .up(percentage: 15),
                    color: AppTheme.GeneratedColors.deepOps,
                    isHighlighted: true
                )
                
                StatCard(
                    title: "Last Month",
                    value: "430",
                    icon: "chart.bar.fill",
                    trend: .down(percentage: 5),
                    color: AppTheme.GeneratedColors.tacticalGray,
                    isHighlighted: false
                )
            }
            .padding()
            .background(AppTheme.GeneratedColors.background)
            .environment(\.colorScheme, .dark)
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Dark Mode")
        }
    }
} 