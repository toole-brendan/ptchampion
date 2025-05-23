import SwiftUI
import PTDesignSystem

struct ContentContainer: ViewModifier {
    let addTabBarPadding: Bool
    
    init(addTabBarPadding: Bool = true) {
        self.addTabBarPadding = addTabBarPadding
    }
    
    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if addTabBarPadding {
                    // Create invisible spacing for tab bar
                    Color.clear
                        .frame(height: 49) // Standard tab bar height
                }
            }
    }
}

extension View {
    func contentContainer(addTabBarPadding: Bool = true) -> some View {
        modifier(ContentContainer(addTabBarPadding: addTabBarPadding))
    }
} 