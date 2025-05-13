import SwiftUI
import UIKit
import PTDesignSystem

/// Configure global app appearance settings to match web styling
struct AppAppearance {
    /// Configure all appearance settings at app start
    static func configureAppearance() {
        configureTabBarAppearance()
        configureNavigationBarAppearance()
    }
    
    /// Configure tab bar appearance to match web styling
    private static func configureTabBarAppearance() {
        // Create a custom appearance for iOS 15+
        let appearance = UITabBarAppearance()
        
        // Configure background - make it match the deepOpsGreen color
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.deepOps)
        
        // Remove the default separator line
        appearance.shadowColor = .clear
        
        // Configure selected item colors
        let selectedAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(Color.brassGold),
            .font: UIFont.systemFont(ofSize: 10, weight: .semibold)
        ]
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = selectedAttributes
        
        // Configure normal item colors
        let normalAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(Color.textTertiary),
            .font: UIFont.systemFont(ofSize: 10, weight: .semibold)
        ]
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = normalAttributes
        
        // Configure icons
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.brassGold)
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(Color.textTertiary)
        
        // Apply the appearance to both UITabBar.appearance() and standardAppearance
        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
    
    /// Configure navigation bar appearance to match web styling
    private static func configureNavigationBarAppearance() {
        // Create a custom appearance for iOS 15+
        let appearance = UINavigationBarAppearance()
        
        // Configure with transparent background
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        appearance.backgroundEffect = nil
        
        // Remove background image and shadow
        appearance.backgroundImage = UIImage()
        appearance.shadowImage = UIImage()
        appearance.shadowColor = .clear
        
        // Set button colors - still using gold for nav buttons
        UINavigationBar.appearance().tintColor = UIColor(Color.brassGold)
        
        // Apply the appearance to both UINavigationBar.appearance() and standardAppearance
        UINavigationBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
        }
    }
    
    /// Create a subtle grid pattern overlay for the navigation bar
    private static func createGridOverlayPattern() -> UIImage? {
        let size = CGSize(width: 100, height: 44) // Typical nav bar height
        
        // Create a renderer for the pattern
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        // Get the base color
        let baseColor = UIColor(Color.deepOps)
        baseColor.setFill()
        context.fill(CGRect(origin: .zero, size: size)
        
        // Set up the grid color (slightly lighter than the base)
        let gridColor = UIColor.white.withAlphaComponent(0.03) // Very subtle
        gridColor.setStroke()
        
        // Create the path
        let path = UIBezierPath()
        context.setLineWidth(0.5)
        
        // Draw vertical lines
        let spacing: CGFloat = 10
        for x in stride(from: 0, through: size.width, by: spacing) {
            path.move(to: CGPoint(x: x, y: 0)
            path.addLine(to: CGPoint(x: x, y: size.height)
        }
        
        // Draw horizontal lines
        for y in stride(from: 0, through: size.height, by: spacing) {
            path.move(to: CGPoint(x: 0, y: y)
            path.addLine(to: CGPoint(x: size.width, y: y)
        }
        
        path.stroke()
        
        // Get the image from the context
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
}

// Extension to initialize appearance in SwiftUI App
extension PTChampionApp {
    func configureAppAppearance() {
        AppAppearance.configureAppearance()
    }
}

// MARK: - Helper methods to call from AppDelegate in UIKit apps
extension AppAppearance {
    /// Call this from AppDelegate for UIKit apps
    static func setupAppearance() {
        configureAppearance()
    }
} 