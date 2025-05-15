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
struct ScreenContainer<Content: View, TrailingHeaderContent: View>: View {
    let title: String
    let subtitle: String
    let addNavigationStack: Bool
    let trailingHeaderContent: TrailingHeaderContent
    @ViewBuilder let content: () -> Content
    
    init(
        title: String, 
        subtitle: String, 
        addNavigationStack: Bool = true, 
        @ViewBuilder trailingHeaderContent: @escaping () -> TrailingHeaderContent = { EmptyView() },
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.addNavigationStack = addNavigationStack
        self.trailingHeaderContent = trailingHeaderContent()
        self.content = content
    }

    var body: some View {
        let screenContent = screenContentView
            .background(AppTheme.GeneratedColors.background.ignoresSafeArea())
        
        if addNavigationStack {
            NavigationStack {
                screenContent
            }
        } else {
            screenContent
        }
    }
    
    private var screenContentView: some View {
        ZStack(alignment: .top) {
            // Background color that extends behind the safe area
            AppTheme.GeneratedColors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header section with consistent positioning
                VStack(alignment: .leading, spacing: 0) {
                    // Explicit space to avoid navigation bar
                    Spacer().frame(height: ScreenLayout.headerTopPadding)
                    ScreenHeader(title: title, subtitle: subtitle) {
                        trailingHeaderContent
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, ScreenLayout.contentPadding)
                    Spacer().frame(height: ScreenLayout.headerBottomPadding)
                }
                .background(AppTheme.GeneratedColors.background)
                .zIndex(1) // Ensure header stays on top
                
                // Content area
                ScrollView(.vertical, showsIndicators: true) {
                    // Keeps the first item 16 pt below the header consistently
                    Color.clear.frame(height: ScreenLayout.firstItemSpacer)
                    
                    VStack(spacing: ScreenLayout.sectionSpacing, content: content)
                        .padding(.horizontal, ScreenLayout.contentPadding)
                        .padding(.bottom, ScreenLayout.contentPadding)
                }
            }
        }
        .navigationBarHidden(true) // Hide the navigation bar everywhere
    }
} 