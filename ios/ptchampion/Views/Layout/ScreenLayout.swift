import SwiftUI
import PTDesignSystem

/// Standardized layout constants for screen components
enum ScreenLayout {
    /// Padding that wraps *all* ScrollView content.
    static let contentPadding: CGFloat = AppTheme.GeneratedSpacing.contentPadding

    /// Vertical distance between the safe-area and the header.
    static let headerTopPadding: CGFloat = 12
    static let headerBottomPadding: CGFloat = 8

    /// Spacer inserted between header and first ScrollView item.
    static let firstItemSpacer: CGFloat = 16

    /// Default distance between sibling sections.
    static let sectionSpacing: CGFloat = AppTheme.GeneratedSpacing.large
}

/// Reusable container for consistent screen layout across the app
struct ScreenContainer<Content: View>: View {
    let title: String
    let subtitle: String
    let addNavigationStack: Bool
    @ViewBuilder let content: () -> Content
    
    init(title: String, subtitle: String, addNavigationStack: Bool = true, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.addNavigationStack = addNavigationStack
        self.content = content
    }

    var body: some View {
        let screenContent = screenContentView
            .background(AppTheme.GeneratedColors.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
        
        if addNavigationStack {
            NavigationStack {
                screenContent
            }
        } else {
            screenContent
        }
    }
    
    private var screenContentView: some View {
        ScrollView(.vertical, showsIndicators: true) {
            // Keeps the first item 16 pt below the header consistently
            Color.clear.frame(height: ScreenLayout.firstItemSpacer)
            
            VStack(spacing: ScreenLayout.sectionSpacing, content: content)
                .padding(.horizontal, ScreenLayout.contentPadding)
                .padding(.bottom, ScreenLayout.contentPadding)
        }
        .safeAreaInset(edge: .top) {
            VStack(spacing: 0) {
                Spacer().frame(height: ScreenLayout.headerTopPadding)
                ScreenHeader(title: title, subtitle: subtitle)
                Spacer().frame(height: ScreenLayout.headerBottomPadding)
            }
            .background(AppTheme.GeneratedColors.background)
        }
    }
} 