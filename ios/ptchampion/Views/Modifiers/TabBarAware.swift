import SwiftUI
import UIKit

struct TabBarHeight {
    static var height: CGFloat {
        let tabBar = UITabBar()
        let height = tabBar.sizeThatFits(CGSize(width: UIScreen.main.bounds.width, height: .greatestFiniteMagnitude)).height
        return height > 0 ? height : 49 // Default to 49 if calculation fails
    }
}

// Create a view extension for proper tab bar handling
extension View {
    func tabBarAware() -> some View {
        self
            .safeAreaInset(edge: .bottom) {
                // Invisible spacer that matches tab bar height
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: TabBarHeight.height)
                    .allowsHitTesting(false)
            }
    }
} 