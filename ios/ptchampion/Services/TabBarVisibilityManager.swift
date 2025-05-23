import SwiftUI
import Combine

class TabBarVisibilityManager: ObservableObject {
    @Published var isTabBarVisible = true
    
    static let shared = TabBarVisibilityManager()
    
    private init() {}
    
    func hideTabBar() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isTabBarVisible = false
        }
    }
    
    func showTabBar() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isTabBarVisible = true
        }
    }
} 