import SwiftUI
import UIKit

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
        appearance.backgroundColor = UIColor(Color.deepOpsGreen)
        
        // Remove the default separator line
        appearance.shadowColor = .clear
        
        // Configure selected item colors
        let selectedAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(Color.brassGold),
            .font: UIFont(name: AppFonts.bodyBold, size: 10) ?? UIFont.systemFont(ofSize: 10, weight: .semibold)
        ]
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = selectedAttributes
        
        // Configure normal item colors
        let normalAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(Color.inactiveGray),
            .font: UIFont(name: AppFonts.bodyBold, size: 10) ?? UIFont.systemFont(ofSize: 10, weight: .semibold)
        ]
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = normalAttributes
        
        // Configure icons
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.brassGold)
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(Color.inactiveGray)
        
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
        
        // Configure with default background
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.deepOpsGreen)
        
        // Title text attributes - match the header style from web
        let titleTextAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(Color.tacticalCream),
            .font: UIFont(name: AppFonts.heading, size: 20) ?? UIFont.systemFont(ofSize: 20, weight: .bold)
        ]
        appearance.titleTextAttributes = titleTextAttributes
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(Color.tacticalCream),
            .font: UIFont(name: AppFonts.heading, size: 34) ?? UIFont.systemFont(ofSize: 34, weight: .bold)
        ]
        
        // Set button colors
        UINavigationBar.appearance().tintColor = UIColor(Color.brassGold)
        
        // Apply the appearance to both UINavigationBar.appearance() and standardAppearance
        UINavigationBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
        }
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