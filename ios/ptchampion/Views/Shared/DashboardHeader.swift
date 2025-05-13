import SwiftUI
import PTDesignSystem

struct DashboardHeader: View {
    // Props
    let title: String
    let subtitle: String?
    var user: User?
    var onProfileTap: (() -> Void)?
    var rightAccessory: AnyView?
    
    // State for animations
    @State private var isLoaded = false
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    // Computed property to get user initials
    private var userInitials: String {
        guard let user = user else { return "U" }
        
        let firstInitial = user.firstName?.prefix(1).uppercased() ?? ""
        let lastInitial = user.lastName?.prefix(1).uppercased() ?? ""
        
        if !lastInitial.isEmpty {
            return "\(firstInitial)\(lastInitial)"
        } else if !firstInitial.isEmpty {
            // If only first name is available, use first two letters
            let firstName = user.firstName ?? ""
            if firstName.count > 1 {
                let secondLetter = String(firstName.dropFirst().prefix(1).uppercased())
                return "\(firstInitial)\(secondLetter)"
            }
            return firstInitial
        }
        return "U" // Default if no name available
    }
    
    init(
        title: String,
        subtitle: String? = nil,
        user: User? = nil,
        onProfileTap: (() -> Void)? = nil,
        rightAccessory: AnyView? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.user = user
        self.onProfileTap = onProfileTap
        self.rightAccessory = rightAccessory
    }
    
    // Convenience initializer for User objects
    init(title: String, subtitle: String? = nil, user: User?, onProfileTap: (() -> Void)? = nil) {
        self.init(
            title: title,
            subtitle: subtitle,
            user: user,
            onProfileTap: onProfileTap
        )
    }
    
    init<RightContent: View>(
        title: String,
        subtitle: String? = nil,
        user: User? = nil,
        onProfileTap: (() -> Void)? = nil,
        @ViewBuilder rightAccessory: () -> RightContent
    ) {
        self.init(
            title: title,
            subtitle: subtitle,
            user: user,
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
                    .fill(Color.deepOps)
                    .overlay(
                        Image(systemName: "circle.grid.3x3.fill")
                            .resizable(resizingMode: .tile)
                            .foregroundColor(Color.white.opacity(0.03))
                            .blendMode(.overlay)
                    )
                
                // Content
                VStack(spacing: 0) {
                    HStack(alignment: .center, spacing: Spacing.medium) {
                        // Title and subtitle
                        VStack(alignment: .leading, spacing: Spacing.small / 2) {
                            Text(title)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(Color.cream)
                                .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 1)
                                .offset(x: isLoaded || reduceMotion ? 0 : -10, y: 0)
                                .opacity(isLoaded ? 1 : 0)
                            
                            if let subtitle = subtitle {
                                Text(subtitle)
                                    .font(.system(size: Spacing.small))
                                    .foregroundColor(Color.cream.opacity(0.8))
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
                            // User initials avatar with animation
                            Button(action: { onProfileTap?() }) {
                                ZStack {
                                    Circle()
                                        .fill(Color.brassGold.opacity(0.2))
                                        .frame(width: 40, height: 40)
                                    
                                    Text(userInitials)
                                        .fontWeight(.bold)
                                        .foregroundColor(Color.brassGold)
                                }
                                .overlay(
                                    Circle()
                                        .stroke(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color.brassGold,
                                                    Color.brassGold.opacity(0.7)
                                                ]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 2
                                        )
                                )
                            }
                            .buttonStyle(ProfileButtonStyle())
                            .scaleEffect(isLoaded || reduceMotion ? 1 : 0.8)
                            .opacity(isLoaded ? 1 : 0)
                        }
                    }
                    .padding(.horizontal, Spacing.large)
                    .padding(.vertical, Spacing.large)
                }
            }
            
            // Bottom decorative line with gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.brassGold.opacity(0.7),
                    Color.brassGold,
                    Color.brassGold.opacity(0.7)
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
    static func greeting(userName: String, user: User? = nil, onProfileTap: (() -> Void)? = nil) -> DashboardHeader {
        DashboardHeader(
            title: "Welcome Back",
            subtitle: userName,
            user: user,
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
            DashboardHeader.greeting(
                userName: "John Doe",
                user: User(id: "123", email: "john@example.com", firstName: "John", lastName: "Doe", profilePictureUrl: nil),
                onProfileTap: {}
            )
            
            DashboardHeader.section(title: "Your Workouts", subtitle: "Recent history")
            
            DashboardHeader(
                title: "Dashboard",
                subtitle: "Your daily summary",
                rightAccessory: {
                    Button(action: {}) {
                        Image(systemName: "gear")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .foregroundColor(Color.brassGold)
                    }
                }
            )
        }
        .previewLayout(.sizeThatFits)
    }
} 
