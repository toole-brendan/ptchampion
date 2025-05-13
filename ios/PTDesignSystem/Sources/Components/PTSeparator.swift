import SwiftUI
import DesignTokens

// Use DSColor from TypeAliases.swift

public struct PTSeparator: View {
    private let orientation: Orientation
    private let thickness: CGFloat
    private let color: SwiftUI.Color
    
    public enum Orientation {
        case horizontal, vertical
    }
    
    public init(
        orientation: Orientation = .horizontal,
        thickness: CGFloat = 1,
        color: SwiftUI.Color? = nil
    ) {
        self.orientation = orientation
        self.thickness = thickness
        self.color = color ?? DesignTokens.Color.textTertiary.opacity(0.3)
    }
    
    public var body: some View {
        Group {
            if orientation == .horizontal {
                Rectangle()
                    .fill(color)
                    .frame(height: thickness)
            } else {
                Rectangle()
                    .fill(color)
                    .frame(width: thickness)
            }
        }
    }
}

public struct PTSeparator_Previews: PreviewProvider {
    public static var previews: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                PTLabel("Horizontal Separator", style: .subheading)
                PTSeparator()
                Text("Content below separator")
            }
            
            HStack(spacing: 16) {
                Text("Left content")
                PTSeparator(orientation: .vertical, thickness: 2)
                Text("Right content")
            }
            .frame(height: 50)
            
            PTSeparator(thickness: 3, color: DesignTokens.Color.primary)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
} 