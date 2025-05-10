import SwiftUI
import PTDesignSystem

struct DashboardHeader: View {
    // Props
    let title: String
    let subtitle: String?
    let userImageURL: URL?
    var onProfileTap: (() -> Void)?
    var rightAccessory: AnyView?
    
    // State for animations
    @State private var isLoaded = false
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
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
        // Profile picture URL feature was intentionally removed, using placeholder avatar instead
        self.init(
            title: title,
            subtitle: subtitle,
            userImageURL: nil,
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
            ZStack {
                // Background with subtle pattern overlay for texture
                Rectangle()
                    .fill(AppTheme.GeneratedColors.deepOps)
                    .overlay(
                        Image(systemName: "circle.grid.3x3.fill")
                            .resizable(resizingMode: .tile)
                            .foregroundColor(Color.white.opacity(0.03))
                            .blendMode(.overlay)
                    )
                
                // Content
                VStack(spacing: 0) {
                    HStack(alignment: .center, spacing: AppTheme.GeneratedSpacing.medium) {
                        // Title and subtitle
                        VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.small / 2) {
                            Text(title)
                                .font(.system(size: AppTheme.GeneratedTypography.heading3, weight: .bold))
                                .foregroundColor(AppTheme.GeneratedColors.cream)
                                .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 1)
                                .offset(x: isLoaded || reduceMotion ? 0 : -10, y: 0)
                                .opacity(isLoaded ? 1 : 0)
                            
                            if let subtitle = subtitle {
                                Text(subtitle)
                                    .font(.system(size: AppTheme.GeneratedTypography.small))
                                    .foregroundColor(AppTheme.GeneratedColors.cream.opacity(0.8))
                                    .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 1)
                                    .offset(x: isLoaded || reduceMotion ? 0 : -10, y: 0)
                                    .opacity(isLoaded ? 1 : 0.7)
                            }
                        }
                        
                        Spacer()
                        
                        // Right accessory or user avatar with animation
                        if let rightAccessory = rightAccessory {
                            rightAccessory
                                .scaleEffect(isLoaded || reduceMotion ? 1 : 0.9)
                                .opacity(isLoaded ? 1 : 0)
                        } else if onProfileTap != nil {
                            // User avatar with animation
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
                                            .stroke(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [
                                                        AppTheme.GeneratedColors.brassGold,
                                                        AppTheme.GeneratedColors.brassGold.opacity(0.7)
                                                    ]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 2
                                            )
                                    )
                                } else {
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .frame(width: 40, height: 40)
                                        .foregroundColor(AppTheme.GeneratedColors.brassGold)
                                        .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 1)
                                }
                            }
                            .buttonStyle(ProfileButtonStyle())
                            .scaleEffect(isLoaded || reduceMotion ? 1 : 0.8)
                            .opacity(isLoaded ? 1 : 0)
                        }
                    }
                    .padding(.horizontal, AppTheme.GeneratedSpacing.large)
                    .padding(.vertical, AppTheme.GeneratedSpacing.large)
                }
            }
            
            // Bottom decorative line with gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    AppTheme.GeneratedColors.brassGold.opacity(0.7),
                    AppTheme.GeneratedColors.brassGold,
                    AppTheme.GeneratedColors.brassGold.opacity(0.7)
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 2)
        }
        .onAppear {
            if !isLoaded && !reduceMotion {
                withAnimation(.easeOut(duration: 0.4)) {
                    isLoaded = true
                }
            } else {
                isLoaded = true
            }
        }
    }
}

// Button style for the profile button
struct ProfileButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.95 : 1)
            .brightness(configuration.isPressed ? 0.05 : 0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
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