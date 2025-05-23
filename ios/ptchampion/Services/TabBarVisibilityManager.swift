import SwiftUI
import Combine

class TabBarVisibilityManager: ObservableObject {
    @Published var isTabBarVisible = true
    
    static let shared = TabBarVisibilityManager()
    
    private init() {}
    
    func hideTabBar() {
        print("DEBUG: [TabBarVisibilityManager] hideTabBar() called - current state: \(isTabBarVisible)")
        withAnimation(.easeInOut(duration: 0.2)) {
            isTabBarVisible = false
        }
        print("DEBUG: [TabBarVisibilityManager] hideTabBar() completed - new state: \(isTabBarVisible)")
    }
    
    func showTabBar() {
        print("DEBUG: [TabBarVisibilityManager] showTabBar() called - current state: \(isTabBarVisible)")
        withAnimation(.easeInOut(duration: 0.2)) {
            isTabBarVisible = true
        }
        print("DEBUG: [TabBarVisibilityManager] showTabBar() completed - new state: \(isTabBarVisible)")
    }
} 