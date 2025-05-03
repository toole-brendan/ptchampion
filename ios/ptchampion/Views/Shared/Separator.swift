import SwiftUI

public struct Separator: View {
    public enum Orientation {
        case horizontal, vertical
    }
    
    private let orientation: Orientation
    private let color: Color
    private let thickness: CGFloat
    private let insets: EdgeInsets
    
    public init(
        orientation: Orientation = .horizontal,
        color: Color = AppTheme.GeneratedColors.tacticalGray.opacity(0.2),
        thickness: CGFloat = 1,
        insets: EdgeInsets = EdgeInsets()
    ) {
        self.orientation = orientation
        self.color = color
        self.thickness = thickness
        self.insets = insets
    }
    
    public var body: some View {
        Rectangle()
            .fill(color)
            .frame(
                width: orientation == .vertical ? thickness : nil,
                height: orientation == .horizontal ? thickness : nil
            )
            .padding(insets)
    }
}

extension Separator {
    /// Creates a horizontal separator with leading and trailing insets
    public static func horizontal(
        inset: CGFloat = 0,
        color: Color = AppTheme.GeneratedColors.tacticalGray.opacity(0.2)
    ) -> Separator {
        Separator(
            orientation: .horizontal,
            color: color,
            insets: EdgeInsets(top: 0, leading: inset, bottom: 0, trailing: inset)
        )
    }
    
    /// Creates a vertical separator with top and bottom insets
    public static func vertical(
        inset: CGFloat = 0,
        color: Color = AppTheme.GeneratedColors.tacticalGray.opacity(0.2)
    ) -> Separator {
        Separator(
            orientation: .vertical,
            color: color,
            insets: EdgeInsets(top: inset, leading: 0, bottom: inset, trailing: 0)
        )
    }
}

struct Separator_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            Text("Horizontal Separator")
            Separator()
                .padding(.horizontal)
            
            Text("Horizontal Separator with insets")
            Separator.horizontal(inset: 32)
            
            HStack {
                Text("Vertical")
                Separator.vertical(inset: 8)
                    .frame(height: 40)
                Text("Separator")
            }
            .padding()
        }
    }
} 