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
    let unit: String
    let color: Color
    let iconName: String? // Optional icon for the stat card

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                PTLabel(title, style: .subheading)
                    .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                Spacer()
                if let iconName = iconName {
                    Image(systemName: iconName)
                        .foregroundColor(color)
                }
            }
            Text(value)
                .font(.system(.largeTitle, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(AppTheme.GeneratedColors.textPrimary)
            PTLabel(unit, style: .caption)
                .foregroundColor(AppTheme.GeneratedColors.textTertiary)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 100) // Ensure a minimum height
        .background(AppTheme.GeneratedColors.background) // Changed from backgroundSecondary
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.5), lineWidth: 1) // Subtle border
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

#if DEBUG
struct StatCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            StatCard(title: "Total Workouts", value: "125", unit: "Sessions", color: .blue, iconName: "figure.walk")
            StatCard(title: "Avg. Score", value: "88.5", unit: "%", color: .green, iconName: "star.fill")
            StatCard(title: "Time Trial", value: "03:45", unit: "min", color: .orange, iconName: "timer")
        }
        .padding()
        .background(AppTheme.GeneratedColors.background)
    }
}
#endif 