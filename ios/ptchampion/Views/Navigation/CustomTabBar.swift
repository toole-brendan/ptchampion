import SwiftUI
import PTDesignSystem

struct CustomTabBar: View {
    @Binding var selectedTab: Tab
    @ObservedObject var visibilityManager = TabBarVisibilityManager.shared
    
    var body: some View {
        if visibilityManager.isTabBarVisible {
            HStack(spacing: 0) {
                TabBarButton(
                    tab: .home,
                    selectedTab: $selectedTab,
                    icon: "house.fill",
                    label: "Home"
                )
                
                TabBarButton(
                    tab: .history,
                    selectedTab: $selectedTab,
                    icon: "clock.arrow.circlepath",
                    label: "History"
                )
                
                TabBarButton(
                    tab: .leaderboards,
                    selectedTab: $selectedTab,
                    icon: "rosette",
                    label: "Leaders"
                )
                
                TabBarButton(
                    tab: .profile,
                    selectedTab: $selectedTab,
                    icon: "person.crop.circle",
                    label: "Profile"
                )
            }
            .frame(height: 49)
            .background(AppTheme.GeneratedColors.deepOps)
            .overlay(
                Rectangle()
                    .frame(height: 0.5)
                    .foregroundColor(Color.gray.opacity(0.3)),
                alignment: .top
            )
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}

struct TabBarButton: View {
    let tab: Tab
    @Binding var selectedTab: Tab
    let icon: String
    let label: String
    
    var isSelected: Bool {
        selectedTab == tab
    }
    
    var body: some View {
        Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? AppTheme.GeneratedColors.brassGold : .gray)
                
                Text(label)
                    .font(.caption2)
                    .foregroundColor(isSelected ? AppTheme.GeneratedColors.brassGold : .gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 6)
        }
    }
} 