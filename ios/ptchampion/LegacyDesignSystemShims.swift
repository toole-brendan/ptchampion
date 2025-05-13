import SwiftUI
import PTDesignSystem

// MARK: - Legacy Typography Extensions

public extension Text {
    func heading1(weight: Font.Weight = .bold, design: Font.Design = .default) -> some View {
        self.font(.system(size: 28, weight: weight, design: design))
    }
    func heading4(weight: Font.Weight = .semibold, design: Font.Design = .default) -> some View {
        self.font(.system(size: 18, weight: weight, design: design))
    }
    func body(weight: Font.Weight = .regular, design: Font.Design = .default) -> some View {
        self.font(.system(size: 16, weight: weight, design: design))
    }
    func bodyBold(design: Font.Design = .default) -> some View {
        self.font(.system(size: 16, weight: .bold, design: design))
    }
    func caption(weight: Font.Weight = .regular, design: Font.Design = .default) -> some View {
        self.font(.system(size: 14, weight: weight, design: design))
    }
    func small(weight: Font.Weight = .regular, design: Font.Design = .default) -> some View {
        self.font(.system(size: 12, weight: weight, design: design))
    }
}

// MARK: - Legacy View Modifiers

public extension View {
    /// Mimics the old `.container()` modifier by applying a max width and standard horizontal padding
    func container(maxWidth: CGFloat = .infinity, horizontalPadding: CGFloat = 16) -> some View {
        self
            .frame(maxWidth: maxWidth, alignment: .center)
            .padding(.horizontal, horizontalPadding)
    }

    /// Lightweight shim for the old `.card()` modifier. Wraps the content in PTCard for visual parity.
    func card() -> some View {
        PTCard {
            self
        }
    }

    /// Previously used to apply responsive padding depending on size classes.
    /// Currently applies a default padding.
    func adaptivePadding(_ value: CGFloat = 16) -> some View {
        self.padding(value)
    }
} 