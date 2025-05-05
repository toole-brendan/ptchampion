import SwiftUI
import PTDesignSystem

struct DashboardHeader: View {
    // Props
    let title: String
    let subtitle: String?
    let userImageURL: URL?
    var onProfileTap: (() -> Void)?
    var rightAccessory: AnyView?
    
    init(
        title: String,
        subtitle: String? = nil,
        userImageURL: URL? = nil,
        onProfileTap: (() -> Void)? = nil,
        rightAccessory: AnyView? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.userImageURL = userImageURL
        self.onProfileTap = onProfileTap
        self.rightAccessory = rightAccessory
    }
    
    // Convenience initializer for User objects
    init(title: String, subtitle: String? = nil, user: User?, onProfileTap: (() -> Void)? = nil) {
        // Get profile picture URL if available from user
        let profilePictureUrl: URL? = user?.profilePictureUrl != nil ? URL(string: user!.profilePictureUrl!) : nil
        
        self.init(
            title: title,
            subtitle: subtitle,
            userImageURL: profilePictureUrl,
            onProfileTap: onProfileTap
        )
    }
    
    init<RightContent: View>(
        title: String,
        subtitle: String? = nil,
        userImageURL: URL? = nil,
        onProfileTap: (() -> Void)? = nil,
        @ViewBuilder rightAccessory: () -> RightContent
    ) {
        self.init(
            title: title,
            subtitle: subtitle,
            userImageURL: userImageURL,
            onProfileTap: onProfileTap,
            rightAccessory: AnyView(rightAccessory())
        )
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header content
            HStack(alignment: .center, spacing: AppTheme.GeneratedSpacing.medium) {
                // Title and subtitle
                VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.small) {
                    Text(title)
                        .font(.system(size: AppTheme.GeneratedTypography.heading3, weight: .bold))
                        .foregroundColor(AppTheme.GeneratedColors.cream)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: AppTheme.GeneratedTypography.small))
                            .foregroundColor(AppTheme.GeneratedColors.cream.opacity(0.7))
                    }
                }
                
                Spacer()
                
                // Right accessory or user avatar
                if let rightAccessory = rightAccessory {
                    rightAccessory
                } else if onProfileTap != nil {
                    // User avatar
                    Button(action: { onProfileTap?() }) {
                        if let imageURL = userImageURL {
                            AsyncImage(url: imageURL) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                case .failure(_), .empty:
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                @unknown default:
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                }
                            }
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(AppTheme.GeneratedColors.brassGold, lineWidth: 2)
                            )
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 40, height: 40)
                                .foregroundColor(AppTheme.GeneratedColors.brassGold)
                        }
                    }
                }
            }
            .padding(.horizontal, AppTheme.GeneratedSpacing.large)
            .padding(.vertical, AppTheme.GeneratedSpacing.large)
            .background(AppTheme.GeneratedColors.deepOps)
            
            // Bottom decorative line
            Rectangle()
                .fill(AppTheme.GeneratedColors.brassGold)
                .frame(height: 2)
        }
    }
}

// Common configuration variant
extension DashboardHeader {
    static func greeting(userName: String, userImageURL: URL? = nil, onProfileTap: (() -> Void)? = nil) -> DashboardHeader {
        DashboardHeader(
            title: "Welcome Back",
            subtitle: userName,
            userImageURL: userImageURL,
            onProfileTap: onProfileTap
        )
    }
    
    static func section(title: String, subtitle: String? = nil) -> DashboardHeader {
        DashboardHeader(
            title: title,
            subtitle: subtitle
        )
    }
}

// Preview provider
struct DashboardHeader_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            DashboardHeader.greeting(userName: "John Doe")
                .previewDisplayName("Greeting Header")
            
            DashboardHeader.section(title: "Your Workouts", subtitle: "Recent history")
                .previewDisplayName("Section Header")
            
            DashboardHeader(
                title: "Dashboard",
                subtitle: "Your daily summary",
                rightAccessory: {
                    Button(action: {}) {
                        Image(systemName: "gear")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .foregroundColor(AppTheme.GeneratedColors.brassGold)
                    }
                }
            )
            .previewDisplayName("Custom Right Accessory")
        }
        .previewLayout(.sizeThatFits)
    }
} 