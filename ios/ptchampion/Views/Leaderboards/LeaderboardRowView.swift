import SwiftUI
import PTDesignSystem

struct LeaderboardRowView: View {
    let entry: LeaderboardEntryView
    let isCurrentUser: Bool

    // Function to determine medal image and color based on rank
    private func rankDecoration(rank: Int) -> (image: String?, color: Color) {
        switch rank {
        case 1: return ("medal.fill", AppTheme.GeneratedColors.brassGold)
        case 2: return ("medal.fill", Color(.systemGray2))
        case 3: return ("medal.fill", Color(UIColor.systemBrown))
        default: return (nil, AppTheme.GeneratedColors.textSecondary)
        }
    }
    
    var body: some View {
        let isTopThree = entry.rank <= 3
        let decoration = rankDecoration(rank: entry.rank)
        
        PTCard(style: isCurrentUser ? .highlight : (isTopThree ? .custom(
            backgroundColor: decoration.color.opacity(0.05),
            cornerRadius: AppTheme.GeneratedRadius.card,
            shadowRadius: 2,
            borderColor: decoration.color.opacity(0.3),
            borderWidth: 1
        ) : .standard)) {
            HStack(spacing: AppTheme.GeneratedSpacing.medium) {
                // Rank with decoration for top 3
                HStack(spacing: 4) {
                    Text("#\(entry.rank)")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(isTopThree ? decoration.color : (isCurrentUser ? AppTheme.GeneratedColors.primary : AppTheme.GeneratedColors.textSecondary))
                    
                    if let imageName = decoration.image {
                        Image(systemName: imageName)
                            .foregroundColor(decoration.color)
                            .font(.system(size: 14))
                    }
                }
                .frame(minWidth: 50, alignment: .leading)

                // Avatar (placeholder for now)
                Circle()
                    .fill(AppTheme.GeneratedColors.textSecondary.opacity(0.2))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text(entry.name.prefix(1).uppercased())
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                    )

                Text(entry.name)
                    .font(AppTheme.GeneratedTypography.bodyBold())
                    .foregroundColor(isCurrentUser ? AppTheme.GeneratedColors.primary : AppTheme.GeneratedColors.textPrimary)
                    .lineLimit(1)
                
                Spacer()
                
                Text("\(entry.score)")
                    .font(.system(size: 18, weight: .semibold, design: .monospaced))
                    .foregroundColor(isTopThree ? decoration.color : (isCurrentUser ? AppTheme.GeneratedColors.primary : AppTheme.GeneratedColors.textPrimary))
            }
            .padding(.vertical, AppTheme.GeneratedSpacing.small)
        }
        .animation(.easeInOut(duration: 0.2), value: isCurrentUser)
    }
}

#if DEBUG
struct LeaderboardRowView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.small) {
            LeaderboardRowView(
                entry: LeaderboardEntryView(id: "1", rank: 1, userId: "user123", name: "Current User", score: 15000),
                isCurrentUser: true
            )
            LeaderboardRowView(
                entry: LeaderboardEntryView(id: "2", rank: 2, userId: "user456", name: "Alice Wonderland", score: 12500),
                isCurrentUser: false
            )
            LeaderboardRowView(
                entry: LeaderboardEntryView(id: "3", rank: 3, userId: "user789", name: "Bob The Builder", score: 11000),
                isCurrentUser: false
            )
            LeaderboardRowView(
                entry: LeaderboardEntryView(id: "4", rank: 100, userId: "user101", name: "VeryLongUserNameThatMightTruncate", score: 500),
                isCurrentUser: false
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
        .preferredColorScheme(.light)
        
        VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.small) {
            LeaderboardRowView(
                entry: LeaderboardEntryView(id: "1", rank: 1, userId: "user123", name: "Gold Medalist", score: 15000),
                isCurrentUser: false
            )
            LeaderboardRowView(
                entry: LeaderboardEntryView(id: "2", rank: 2, userId: "user456", name: "Silver Medalist", score: 12500),
                isCurrentUser: false
            )
            LeaderboardRowView(
                entry: LeaderboardEntryView(id: "3", rank: 3, userId: "user789", name: "Bronze Medalist", score: 11000),
                isCurrentUser: false
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
        .preferredColorScheme(.dark)
    }
}
#endif 