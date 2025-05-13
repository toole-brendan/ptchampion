import SwiftUI
import PTDesignSystem

fileprivate typealias DSColor = PTDesignSystem.Color
fileprivate typealias SColor = SwiftUI.Color

struct Spinner: View {
    enum Size: CGFloat {
        case tiny = 16
        case small = 24
        case medium = 36
        case large = 48
        
        var lineWidth: CGFloat {
            switch self {
            case .tiny: return 2
            case .small: return 2.5
            case .medium: return 3
            case .large: return 4
            }
        }
    }
    
    enum Variant {
        case primary
        case secondary
        case light
        
        var color: SColor {
            switch self {
            case .primary: return DSColor.primary
            case .secondary: return DSColor.textSecondary
            case .light: return DSColor.background
            }
        }
    }
    
    let size: Size
    let variant: Variant
    let speed: Double
    @State private var isAnimating = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    init(size: Size = .medium, variant: Variant = .primary, speed: Double = 0.75) {
        self.size = size
        self.variant = variant
        self.speed = speed
    }
    
    var body: some View {
        ZStack {
            // Track circle (background)
            Circle()
                .stroke(variant.color.opacity(0.15), lineWidth: size.lineWidth)
                .frame(width: size.rawValue, height: size.rawValue)
            
            // Spinning circle (foreground)
            Circle()
                .trim(from: 0, to: 0.75)
                .stroke(variant.color, style: StrokeStyle(
                    lineWidth: size.lineWidth,
                    lineCap: .round
                ))
                .frame(width: size.rawValue, height: size.rawValue)
                .rotationEffect(Angle(degrees: isAnimating && !reduceMotion ? 360 : 0))
                .animation(
                    reduceMotion ? nil : Animation.linear(duration: speed)
                        .repeatForever(autoreverses: false),
                    value: isAnimating
                )
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// Convenience constructors
extension Spinner {
    static func small(variant: Variant = .primary) -> Spinner {
        Spinner(size: .small, variant: variant)
    }
    
    static func large(variant: Variant = .primary) -> Spinner {
        Spinner(size: .large, variant: variant)
    }
    
    static func overlay() -> some View {
        ZStack {
            SColor.black.opacity(0.4)
            
            VStack(spacing: Spacing.medium) {
                Spinner(size: .large)
                
                PTLabel("Loading...", style: .body)
                    .foregroundColor(DSColor.background)
            }
            .padding(Spacing.large)
            .background(DSColor.primary.opacity(0.85))
            .cornerRadius(CornerRadius.large)
        }
        .ignoresSafeArea()
    }
}

// Container component wrapping any view with loading state
struct WithLoading<Content: View>: View {
    let isLoading: Bool
    let content: () -> Content
    
    init(isLoading: Bool, @ViewBuilder content: @escaping () -> Content) {
        self.isLoading = isLoading
        self.content = content
    }
    
    var body: some View {
        ZStack {
            content()
                .disabled(isLoading)
                .opacity(isLoading ? 0.5 : 1)
            
            if isLoading {
                VStack {
                    Spinner()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(SColor.black.opacity(0.05))
            }
        }
    }
}

// Preview Provider
struct Spinner_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            VStack(spacing: Spacing.large) {
                // Size variants
                HStack(spacing: Spacing.medium) {
                    Spinner(size: .tiny)
                    Spinner(size: .small)
                    Spinner(size: .medium)
                    Spinner(size: .large)
                }
                
                // Color variants
                HStack(spacing: Spacing.medium) {
                    Spinner(variant: .primary)
                    Spinner(variant: .secondary)
                    
                    ZStack {
                        DSColor.primary
                            .frame(width: 80, height: 80)
                            .cornerRadius(CornerRadius.medium)
                        Spinner(variant: .light)
                    }
                }
                
                // WithLoading example
                WithLoading(isLoading: true) {
                    VStack {
                        PTLabel("This content is loading", style: .body)
                            .padding()
                            .background(DSColor.cardBackground)
                            .cornerRadius(CornerRadius.medium)
                    }
                    .frame(width: 200, height: 100)
                }
            }
            .padding()
            .background(DSColor.background.opacity(0.5))
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Light Mode")
            
            // Dark mode preview
            Spinner()
                .padding()
                .background(SColor.black)
                .environment(\.colorScheme, .dark)
                .previewLayout(.sizeThatFits)
                .previewDisplayName("Dark Mode")
        }
    }
} 