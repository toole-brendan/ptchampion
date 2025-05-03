import SwiftUI

extension View {
    func dynamicTypeSize(_ sizes: DynamicTypeSize...) -> some View {
        if #available(iOS 15.0, *) {
            return self.dynamicTypeSize(sizes.isEmpty ? .large : DynamicTypeSize.allCases)
        } else {
            return self
        }
    }
    
    func reduceMotionIfNeeded() -> some View {
        self.modifier(ReduceMotionViewModifier())
    }
}

struct ReduceMotionViewModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    func body(content: Content) -> some View {
        if reduceMotion {
            content.animation(nil)
        } else {
            content
        }
    }
} 