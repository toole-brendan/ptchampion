import SwiftUI
import PTDesignSystem

struct LeaderboardRowView: View {
    let entry: LeaderboardEntryView
    let isCurrentUser: Bool

    var body: some View {
        HStack(spacing: 16) {
            // Enhanced rank badge with proper medal colors
            ZStack {
                Circle()
                    .fill(rankBackgroundColor)
                    .frame(width: 44, height: 44)
                
                if entry.rank <= 3 {
                    Image(systemName: rankIcon)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(rankIconColor)
                } else {
                    Text("\(entry.rank)")
                        .militaryMonospaced(size: 16)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.GeneratedColors.deepOps)
                }
            }
            
            // User info with performance indicators
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(entry.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppTheme.GeneratedColors.deepOps)
                        .lineLimit(1)
                    
                    // Performance indicator (if available)
                    if let change = entry.performanceChange {
                        performanceIndicator(change)
                    }
                    
                    // Personal best indicator (if available)
                    if entry.isPersonalBest == true {
                        personalBestBadge
                    }
                }
                
                if entry.locationDescription != nil || entry.unit != nil {
                    HStack(spacing: 4) {
                        if let unit = entry.unit {
                            Text(unit)
                                .militaryMonospaced(size: 12)
                                .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                        }
                        if entry.unit != nil && entry.locationDescription != nil {
                            Text("•")
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                        }
                        if let location = entry.locationDescription {
                            Text(location)
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Score/metric with enhanced styling
            VStack(alignment: .trailing, spacing: 2) {
                Text(entry.displayValue)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(scoreColor)
                
                if let subtitle = entry.displaySubtitle {
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(
            isCurrentUser ? 
            AppTheme.GeneratedColors.brassGold.opacity(0.05) : 
            Color.clear
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(entry.userId != nil ? "Double tap to view profile" : "")
        .accessibilityAddTraits(entry.userId != nil ? .isButton : [])
    }
    
    // MARK: - Helper Views
    
    private func performanceIndicator(_ change: PerformanceChange) -> some View {
        Image(systemName: change.icon)
            .font(.system(size: 12))
            .foregroundColor(change.color)
    }
    
    private var personalBestBadge: some View {
        HStack(spacing: 2) {
            Image(systemName: "star.fill")
                .font(.system(size: 8))
            Text("PB")
                .militaryMonospaced(size: 8)
                .fontWeight(.bold)
        }
        .foregroundColor(AppTheme.GeneratedColors.brassGold)
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(
            Capsule()
                .fill(AppTheme.GeneratedColors.brassGold.opacity(0.2))
        )
    }
    
    // MARK: - Computed Properties
    
    private var rankBackgroundColor: Color {
        switch entry.rank {
        case 1: return goldColor.opacity(0.2)
        case 2: return silverColor.opacity(0.2)
        case 3: return bronzeColor.opacity(0.2)
        default: return AppTheme.GeneratedColors.oliveMist.opacity(0.2)
        }
    }
    
    private var rankIcon: String {
        switch entry.rank {
        case 1: return "trophy.fill"
        case 2: return "medal.fill"
        case 3: return "medal.fill"
        default: return ""
        }
    }
    
    private var rankIconColor: Color {
        switch entry.rank {
        case 1: return goldColor
        case 2: return silverColor
        case 3: return bronzeColor
        default: return AppTheme.GeneratedColors.deepOps
        }
    }
    
    private var scoreColor: Color {
        switch entry.rank {
        case 1: return goldColor
        case 2: return silverColor
        case 3: return bronzeColor
        default: return AppTheme.GeneratedColors.brassGold
        }
    }
    
    private var goldColor: Color {
        Color(red: 1.0, green: 0.84, blue: 0.0) // #FFD700
    }
    
    private var silverColor: Color {
        Color(red: 0.75, green: 0.75, blue: 0.75) // #C0C0C0
    }
    
    private var bronzeColor: Color {
        Color(red: 0.8, green: 0.5, blue: 0.2) // #CD7F32
    }
    
    private var accessibilityLabel: String {
        var label = "\(entry.name), ranked \(entry.rank)"
        
        switch entry.rank {
        case 1: label += ", gold medal"
        case 2: label += ", silver medal" 
        case 3: label += ", bronze medal"
        default: break
        }
        
        label += ", score \(entry.displayValue)"
        
        if entry.isPersonalBest == true {
            label += ", personal best"
        }
        
        if let change = entry.performanceChange {
            switch change {
            case .improved(let positions):
                label += ", improved \(positions) positions"
            case .declined(let positions):
                label += ", declined \(positions) positions"
            case .maintained:
                label += ", maintained position"
            }
        }
        
        return label
    }
}



#if DEBUG
struct LeaderboardRowView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.small) {
            LeaderboardRowView(
                entry: LeaderboardEntryView(
                    id: "1", 
                    rank: 1, 
                    userId: "user123", 
                    name: "Current User", 
                    score: 15000,
                    exerciseType: "pushup",
                    location: nil,
                    distance: nil,
                    isPersonalBest: true,
                    performanceChange: .improved(positions: 2)
                ),
                isCurrentUser: true
            )
            
            LeaderboardRowView(
                entry: LeaderboardEntryView(
                    id: "2", 
                    rank: 2, 
                    userId: "user456", 
                    name: "Alice Wonderland", 
                    score: 12500,
                    exerciseType: "pushup",
                    location: nil,
                    distance: nil,
                    isPersonalBest: false,
                    performanceChange: .maintained
                ),
                isCurrentUser: false
            )
            
            LeaderboardRowView(
                entry: LeaderboardEntryView(
                    id: "3", 
                    rank: 3, 
                    userId: "user789", 
                    name: "Bob The Builder", 
                    score: 11000,
                    exerciseType: "pushup",
                    location: nil,
                    distance: nil,
                    isPersonalBest: false,
                    performanceChange: .declined(positions: 1)
                ),
                isCurrentUser: false
            )
            
            LeaderboardRowView(
                entry: LeaderboardEntryView(
                    id: "4", 
                    rank: 100, 
                    userId: "user101", 
                    name: "VeryLongUserNameThatMightTruncate", 
                    score: 500,
                    exerciseType: "pushup",
                    location: "San Francisco",
                    distance: 5000,
                    isPersonalBest: false,
                    performanceChange: nil
                ),
                isCurrentUser: false
            )
        }
        .padding()
        .background(AppTheme.GeneratedColors.background)
        .previewLayout(.sizeThatFits)
        .preferredColorScheme(.light)
        .previewDisplayName("Enhanced Rows - Light")
        
        VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.small) {
            LeaderboardRowView(
                entry: LeaderboardEntryView(
                    id: "1", 
                    rank: 1, 
                    userId: "user123", 
                    name: "Gold Medalist", 
                    score: 15000,
                    exerciseType: "pushup",
                    location: nil,
                    distance: nil,
                    isPersonalBest: true,
                    performanceChange: nil
                ),
                isCurrentUser: false
            )
            
            LeaderboardRowView(
                entry: LeaderboardEntryView(
                    id: "2", 
                    rank: 2, 
                    userId: "user456", 
                    name: "Silver Medalist", 
                    score: 12500,
                    exerciseType: "pushup",
                    location: nil,
                    distance: nil,
                    isPersonalBest: false,
                    performanceChange: nil
                ),
                isCurrentUser: false
            )
            
            LeaderboardRowView(
                entry: LeaderboardEntryView(
                    id: "3", 
                    rank: 3, 
                    userId: "user789", 
                    name: "Bronze Medalist", 
                    score: 11000,
                    exerciseType: "pushup",
                    location: nil,
                    distance: nil,
                    isPersonalBest: false,
                    performanceChange: nil
                ),
                isCurrentUser: false
            )
        }
        .padding()
        .background(AppTheme.GeneratedColors.background)
        .previewLayout(.sizeThatFits)
        .environment(\.colorScheme, .dark)
        .previewDisplayName("Medal Winners - Dark")
    }
}
#endif 