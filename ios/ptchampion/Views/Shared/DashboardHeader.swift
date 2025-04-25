import SwiftUI

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
            HStack(alignment: .center, spacing: AppConstants.Spacing.md) {
                // Title and subtitle
                VStack(alignment: .leading, spacing: AppConstants.Spacing.xs) {
                    Text(title)
                        .font(.custom(AppFonts.heading, size: AppConstants.FontSize.xl))
                        .foregroundColor(.tacticalCream)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.custom(AppFonts.body, size: AppConstants.FontSize.sm))
                            .foregroundColor(Color.tacticalCream.opacity(0.7))
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
                                    .stroke(Color.brassGold, lineWidth: 2)
                            )
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 40, height: 40)
                                .foregroundColor(.brassGold)
                        }
                    }
                }
            }
            .padding(.horizontal, AppConstants.Spacing.lg)
            .padding(.vertical, AppConstants.Spacing.lg)
            .background(Color.deepOpsGreen)
            
            // Bottom decorative line
            Rectangle()
                .fill(Color.brassGold)
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
                            .foregroundColor(.brassGold)
                    }
                }
            )
            .previewDisplayName("Custom Right Accessory")
        }
        .previewLayout(.sizeThatFits)
    }
} 