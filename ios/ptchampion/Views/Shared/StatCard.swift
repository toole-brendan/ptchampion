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
    let color: SwiftUI.Color
    let iconName: String? // Optional icon for the stat card

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                PTLabel(title, style: .subheading)
                    .foregroundColor(ThemeColor.textSecondary)
                Spacer()
                if let iconName = iconName {
                    Image(systemName: iconName)
                        .foregroundColor(color)
                }
            }
            Text(value)
                .font(.system(.largeTitle, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(ThemeColor.textPrimary)
            PTLabel(unit, style: .caption)
                .foregroundColor(ThemeColor.textTertiary)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 100) // Ensure a minimum height
        .background(ThemeColor.background) // Changed from backgroundSecondary
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
        HStack(spacing: Spacing.contentPadding) {
            // Rank with medal for top 3
            if rank <= 3 {
                ZStack {
                    Circle()
                        .fill(ThemeColor.brassGold.opacity(0.1))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "medal.fill")
                        .foregroundColor(ThemeColor.brassGold)
                        .heading4()
                }
            } else {
                Text("\(rank)")
                    .font(Typography.monospace)
                    .foregroundColor(ThemeColor.textTertiary)
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
                            .foregroundColor(ThemeColor.textTertiary.opacity(0.5))
                    @unknown default:
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .foregroundColor(ThemeColor.textTertiary.opacity(0.5))
                    }
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
                    .foregroundColor(ThemeColor.textTertiary.opacity(0.5))
            }
            
            // Name
            Text(name)
                .font(isCurrentUser ? .headline : .body)
                .foregroundColor(isCurrentUser ? ThemeColor.brassGold : ThemeColor.textPrimary)
            
            Spacer()
            
            // Score
            Text(score)
                .font(Typography.monospace)
                .foregroundColor(ThemeColor.textPrimary)
                .fontWeight(.medium)
        }
        .padding(Spacing.contentPadding)
        .background(isCurrentUser ? ThemeColor.brassGold.opacity(0.05) : ThemeColor.cardBackground)
        .cornerRadius(CornerRadius.card)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.card)
                .stroke(isCurrentUser ? ThemeColor.brassGold.opacity(0.5) : SwiftUI.Color.clear, lineWidth: 1)
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
        .background(ThemeColor.background) // Changed from backgroundPrimary
    }
}
#endif 