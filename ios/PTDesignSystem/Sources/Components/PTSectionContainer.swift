import SwiftUI

/// A reusable container component that provides dashboard-style section styling
/// with a dark header and light content area
public struct PTSectionContainer<HeaderContent: View, BodyContent: View>: View {
    private let headerTitle: String
    private let headerSubtitle: String?
    private let headerContent: HeaderContent?
    private let bodyContent: BodyContent
    private let headerColor: Color
    private let contentBackground: Color
    
    /// Creates a section container with title and optional subtitle
    public init(
        title: String,
        subtitle: String? = nil,
        headerColor: Color = Color(red: 0.29, green: 0.29, blue: 0.23), // deepOps equivalent
        contentBackground: Color = Color(red: 0.93, green: 0.91, blue: 0.86), // #EDE9DB equivalent
        @ViewBuilder content: () -> BodyContent
    ) where HeaderContent == EmptyView {
        self.headerTitle = title
        self.headerSubtitle = subtitle
        self.headerContent = nil
        self.bodyContent = content()
        self.headerColor = headerColor
        self.contentBackground = contentBackground
    }
    
    /// Creates a section container with custom header content
    public init(
        headerColor: Color = Color(red: 0.29, green: 0.29, blue: 0.23), // deepOps equivalent
        contentBackground: Color = Color(red: 0.93, green: 0.91, blue: 0.86), // #EDE9DB equivalent
        @ViewBuilder header: () -> HeaderContent,
        @ViewBuilder content: () -> BodyContent
    ) {
        self.headerTitle = ""
        self.headerSubtitle = nil
        self.headerContent = header()
        self.bodyContent = content()
        self.headerColor = headerColor
        self.contentBackground = contentBackground
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Dark header
            Group {
                if let headerContent = headerContent {
                    headerContent
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(headerTitle.uppercased())
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Color(red: 0.75, green: 0.66, blue: 0.38)) // brassGold equivalent
                            .padding(.bottom, 4)
                        
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(Color(red: 0.75, green: 0.66, blue: 0.38).opacity(0.3)) // brassGold with opacity
                            .padding(.bottom, 4)
                        
                        if let subtitle = headerSubtitle {
                            Text(subtitle.uppercased())
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(red: 0.75, green: 0.66, blue: 0.38)) // brassGold equivalent
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .background(headerColor)
            .clipShape(RoundedCorner(radius: 8, corners: [.topLeft, .topRight]))
            
            // Light content area
            bodyContent
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(contentBackground)
                .clipShape(RoundedCorner(radius: 8, corners: [.bottomLeft, .bottomRight]))
        }
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

/// Alternative white background version for cleaner sections
public extension PTSectionContainer {
    /// Creates a section container with white background instead of cream
    init(
        title: String,
        subtitle: String? = nil,
        whiteBackground: Bool,
        @ViewBuilder content: () -> BodyContent
    ) where HeaderContent == EmptyView {
        self.init(
            title: title,
            subtitle: subtitle,
            contentBackground: whiteBackground ? Color.white : Color(red: 0.93, green: 0.91, blue: 0.86),
            content: content
        )
    }
}

// MARK: - Helper Extensions

public extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

public struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    public func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

// MARK: - Usage Examples

#Preview("Basic Section") {
    ScrollView {
        VStack(spacing: 20) {
            PTSectionContainer(
                title: "Profile Settings",
                subtitle: "Update your personal information"
            ) {
                VStack(spacing: 16) {
                    Text("Form fields would go here")
                        .padding()
                }
            }
            
            PTSectionContainer(
                title: "Account Actions",
                subtitle: "Manage your account",
                whiteBackground: true
            ) {
                VStack(spacing: 16) {
                    Button("Log Out") { }
                        .foregroundColor(.red)
                        .padding()
                }
            }
        }
        .padding()
    }
    .background(Color.gray.opacity(0.1))
}

#Preview("Custom Header") {
    PTSectionContainer(
        headerColor: Color(red: 0.29, green: 0.29, blue: 0.23),
        contentBackground: Color.white,
        header: {
            HStack {
                Image(systemName: "person.circle")
                    .foregroundColor(Color(red: 0.75, green: 0.66, blue: 0.38))
                    .font(.system(size: 24))
                Text("Custom Header")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(red: 0.75, green: 0.66, blue: 0.38))
            }
        },
        content: {
            VStack(alignment: .leading, spacing: 12) {
                Text("This section uses a custom header")
                Text("You can put any content here")
            }
            .padding()
        }
    )
    .padding()
    .background(Color.gray.opacity(0.1))
}

#Preview("Danger Zone Style") {
    PTSectionContainer(
        title: "Danger Zone",
        subtitle: "Irreversible actions",
        headerColor: Color(red: 0.29, green: 0.29, blue: 0.23)
    ) {
        VStack(spacing: 16) {
            Text("Delete Account")
                .foregroundColor(.red)
                .padding()
        }
    }
    .padding()
    .background(Color.gray.opacity(0.1))
} 