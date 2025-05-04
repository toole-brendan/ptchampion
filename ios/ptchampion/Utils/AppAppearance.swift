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
        appearance.backgroundColor = UIColor(AppTheme.GeneratedColors.deepOps)
        
        // Remove the default separator line
        appearance.shadowColor = .clear
        
        // Configure selected item colors
        let selectedAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(AppTheme.GeneratedColors.brassGold),
            .font: UIFont(name: AppTheme.GeneratedTypography.bodyBold(size: 10).font.name, size: 10) ?? UIFont.systemFont(ofSize: 10, weight: .semibold)
        ]
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = selectedAttributes
        
        // Configure normal item colors
        let normalAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(AppTheme.GeneratedColors.inactiveGray),
            .font: UIFont(name: AppTheme.GeneratedTypography.bodyBold(size: 10).font.name, size: 10) ?? UIFont.systemFont(ofSize: 10, weight: .semibold)
        ]
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = normalAttributes
        
        // Configure icons
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(AppTheme.GeneratedColors.brassGold)
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(AppTheme.GeneratedColors.inactiveGray)
        
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
        appearance.backgroundColor = UIColor(AppTheme.GeneratedColors.deepOps)
        
        // Title text attributes - match the header style from web
        let titleTextAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(AppTheme.GeneratedColors.cream),
            .font: UIFont(name: AppTheme.GeneratedTypography.heading(size: 20).font.name, size: 20) ?? UIFont.systemFont(ofSize: 20, weight: .bold)
        ]
        appearance.titleTextAttributes = titleTextAttributes
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(AppTheme.GeneratedColors.cream),
            .font: UIFont(name: AppTheme.GeneratedTypography.heading(size: 34).font.name, size: 34) ?? UIFont.systemFont(ofSize: 34, weight: .bold)
        ]
        
        // Set button colors
        UINavigationBar.appearance().tintColor = UIColor(AppTheme.GeneratedColors.brassGold)
        
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