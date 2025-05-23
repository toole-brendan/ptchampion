import SwiftUI

struct SafeAreaTabView<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        GeometryReader { geometry in
            content
                .frame(width: geometry.size.width, height: geometry.size.height)
                .edgesIgnoringSafeArea(.bottom)
                .safeAreaInset(edge: .bottom) {
                    // This creates space for the tab bar
                    Color.clear.frame(height: 49) // Standard tab bar height
                }
        }
    }
} 