import SwiftUI
import PTDesignSystem

// Use design system colors by default; reference SwiftUI.Color when needed
fileprivate typealias SColor = SwiftUI.Color

struct LeaderboardRowView: View {
    let entry: LeaderboardEntryView
    let isCurrentUser: Bool

    // Function to determine medal image and color based on rank
    private func rankDecoration(rank: Int) -> (image: String?, color: SColor) {
        switch rank {
        case 1: return ("medal.fill", SColor(.systemYellow))
        case 2: return ("medal.fill", SColor(.systemGray2))
        case 3: return ("medal.fill", SColor(UIColor.systemBrown))
        default: return (nil, SColor(.secondaryLabel))
        }
    }
    
    // Function to get initials from name
    private func getInitials(from name: String) -> String {
        let components = name.components(separatedBy: " ")
        
        if components.count > 1 {
            // If name has multiple parts (First Last), use first letter of each
            let firstInitial = components[0].prefix(1).uppercased()
            let secondInitial = components[1].prefix(1).uppercased()
            return "\(firstInitial)\(secondInitial)"
        } else if !name.isEmpty {
            // If single word (username), use first two letters
            if name.count > 1 {
                let firstTwo = name.prefix(2).uppercased()
                return String(firstTwo)
            }
            return name.prefix(1).uppercased()
        }
        
        return "U" // Default
    }
    
    var body: some View {
        let isTopThree = entry.rank <= 3
        let decoration = rankDecoration(rank: entry.rank)
        
        VStack(style: isCurrentUser ? .highlight : (isTopThree ? .custom(
            backgroundColor: decoration.color.opacity(0.05),
            cornerRadius: CornerRadius.card,
            shadowRadius: 2,
            borderColor: decoration.color.opacity(0.3),
            borderWidth: 1
        ) : .standard)) {
            HStack(spacing: Spacing.medium) {
                // Rank with decoration for top 3
                HStack(spacing: 4) {
                    Text("#\(entry.rank)")
                        .body(weight: .bold, design: .monospaced)
                        .foregroundColor(isTopThree ? decoration.color : (isCurrentUser ? .primary : .secondaryLabel))
                    
                    if let imageName = decoration.image {
                        Image(systemName: imageName)
                            .foregroundColor(decoration.color)
                            .small()
                    }
                }
                .frame(minWidth: 50, alignment: .leading)

                // Avatar with initials
                Circle()
                    .fill(SColor(.secondarySystemBackground))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text(getInitials(from: entry.name))
                            .caption(weight: .bold)
                            .foregroundColor(.secondaryLabel)
                    )

                Text(entry.name)
                    .bodyBold()
                    .foregroundColor(isCurrentUser ? .primary : .label)
                    .lineLimit(1)
                
                Spacer()
                
                Text("\(entry.score)")
                    .heading4(weight: .semibold, design: .monospaced)
                    .foregroundColor(isTopThree ? decoration.color : (isCurrentUser ? .primary : .label))
            }
            .padding(.vertical, Spacing.small)
        }
        .animation(.easeInOut(duration: 0.2), value: isCurrentUser)
    }
}

#if DEBUG
struct LeaderboardRowView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
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
        
        VStack(alignment: .leading, spacing: Spacing.small) {
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
