import SwiftUI

public struct BottomNavItem: Identifiable {
    public let id = UUID()
    let title: String
    let icon: Image
    let action: () -> Void
    
    public init(title: String, icon: Image, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }
}

public struct BottomNavBar: View {
    private let items: [BottomNavItem]
    @Binding private var selectedIndex: Int
    
    public init(items: [BottomNavItem], selectedIndex: Binding<Int>) {
        self.items = items
        self._selectedIndex = selectedIndex
    }
    
    public var body: some View {
        HStack(spacing: 0) {
            ForEach(items.indices, id: \.self) { index in
                Button {
                    withAnimation {
                        selectedIndex = index
                    }
                    items[index].action()
                } label: {
                    VStack(spacing: 4) {
                        items[index].icon
                            .font(.system(size: 22))
                            .foregroundColor(selectedIndex == index ? AppTheme.GeneratedColors.brassGold : .white)
                        
                        Text(items[index].title)
                            .font(AppTheme.GeneratedTypography.body(size: 12))
                            .foregroundColor(selectedIndex == index ? AppTheme.GeneratedColors.brassGold : .white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
                }
                .buttonStyle(BottomNavButtonStyle())
                .accessibilityLabel(items[index].title)
                .accessibilityAddTraits(selectedIndex == index ? .isSelected : [])
            }
        }
        .background(
            AppTheme.GeneratedColors.deepOps
                .edgesIgnoringSafeArea(.bottom)
                .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: -2)
        )
    }
}

struct BottomNavButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed && !reduceMotion ? 0.7 : 1.0)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.95 : 1.0)
            .animation(.spring(response: 0.2), value: configuration.isPressed)
    }
}

// For programmatic tab navigation
public class BottomNavCoordinator: ObservableObject {
    @Published public var selectedIndex: Int = 0
    
    public init(initialIndex: Int = 0) {
        self.selectedIndex = initialIndex
    }
    
    public func navigateTo(index: Int) {
        selectedIndex = index
    }
}

struct BottomNavBar_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Spacer() // Push nav to bottom
            
            BottomNavBar(
                items: [
                    BottomNavItem(
                        title: "Home",
                        icon: Image(systemName: "house.fill"),
                        action: {}
                    ),
                    BottomNavItem(
                        title: "Workouts",
                        icon: Image(systemName: "figure.run"),
                        action: {}
                    ),
                    BottomNavItem(
                        title: "Progress",
                        icon: Image(systemName: "chart.bar.fill"),
                        action: {}
                    ),
                    BottomNavItem(
                        title: "Profile",
                        icon: Image(systemName: "person.fill"),
                        action: {}
                    )
                ],
                selectedIndex: .constant(0)
            )
        }
        .previewLayout(.sizeThatFits)
        .preferredColorScheme(.dark)
    }
} 