import SwiftUI
import PTDesignSystem

fileprivate typealias DSColor = PTDesignSystem.Color
fileprivate typealias SColor = SwiftUI.Color

enum Trend {
    case up(percentage: Int)
    case down(percentage: Int)
    case none
}

struct StatCard: View {
    let title: String
    let value: String
    let unit: String
    let color: SColor
    let iconName: String? // Optional icon for the stat card

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                PTLabel(title, style: .subheading)
                    .foregroundColor(DSColor.textSecondary)
                Spacer()
                if let iconName = iconName {
                    Image(systemName: iconName)
                        .foregroundColor(color)
                }
            }
            Text(value)
                .font(.system(.largeTitle, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(DSColor.textPrimary)
            PTLabel(unit, style: .caption)
                .foregroundColor(DSColor.textTertiary)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 100) // Ensure a minimum height
        .background(DSColor.background) // Changed from backgroundSecondary
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
                        .fill(DSColor.brassGold.opacity(0.1))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "medal.fill")
                        .foregroundColor(DSColor.brassGold)
                        .heading4()
                }
            } else {
                Text("\(rank)")
                    .font(Typography.monospace)
                    .foregroundColor(DSColor.textTertiary)
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
                            .foregroundColor(DSColor.textTertiary.opacity(0.5))
                    @unknown default:
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .foregroundColor(DSColor.textTertiary.opacity(0.5))
                    }
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
                    .foregroundColor(DSColor.textTertiary.opacity(0.5))
            }
            
            // Name
            Text(name)
                .font(isCurrentUser ? .body()Bold() : .body()())
                .foregroundColor(isCurrentUser ? DSColor.brassGold : DSColor.textPrimary)
            
            Spacer()
            
            // Score
            Text(score)
                .font(Typography.monospace)
                .foregroundColor(DSColor.textPrimary)
                .fontWeight(.medium)
        }
        .padding(Spacing.contentPadding)
        .background(isCurrentUser ? DSColor.brassGold.opacity(0.05) : DSColor.cardBackground)
        .cornerRadius(CornerRadius.card)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.card)
                .stroke(isCurrentUser ? DSColor.brassGold.opacity(0.5) : SColor.clear, lineWidth: 1)
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
        .background(DSColor.background) // Changed from backgroundPrimary
    }
}
#endif 