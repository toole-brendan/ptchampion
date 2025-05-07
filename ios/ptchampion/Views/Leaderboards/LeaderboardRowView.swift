import SwiftUI
import PTDesignSystem

struct LeaderboardRowView: View {
    let entry: LeaderboardEntryView
    let isCurrentUser: Bool

    var body: some View {
        HStack(spacing: AppTheme.GeneratedSpacing.medium) {
            Text("#\(entry.rank)")
                .font(AppTheme.GeneratedTypography.body(size: 16).weight(.bold))
                .foregroundColor(isCurrentUser ? AppTheme.GeneratedColors.primary : AppTheme.GeneratedColors.textSecondary)
                .frame(minWidth: 40, alignment: .leading)

            // Placeholder for an avatar if available in the future
            // Image(systemName: "person.circle.fill")
            //     .font(.title2)
            //     .foregroundColor(AppTheme.GeneratedColors.textTertiary)

            Text(entry.name)
                .font(AppTheme.GeneratedTypography.bodySemibold())
                .foregroundColor(AppTheme.GeneratedColors.textPrimary)
            
            Spacer()
            
            Text("\(entry.score)")
                .font(AppTheme.GeneratedTypography.body(size: 18).weight(.semibold))
                .foregroundColor(isCurrentUser ? AppTheme.GeneratedColors.primary : AppTheme.GeneratedColors.textPrimary)
        }
        .padding(.vertical, AppTheme.GeneratedSpacing.small)
        .padding(.horizontal, AppTheme.GeneratedSpacing.medium)
        .background(isCurrentUser ? AppTheme.GeneratedColors.primary.opacity(0.1) : Color.clear)
        .cornerRadius(AppTheme.GeneratedRadius.small)
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
    }
}
#endif 