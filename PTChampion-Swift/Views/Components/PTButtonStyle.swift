import SwiftUI

struct PTButtonStyle: ButtonStyle {
    var backgroundColor: Color = .blue
    var foregroundColor: Color = .white
    var isFullWidth: Bool = true
    var height: CGFloat = 50
    var cornerRadius: CGFloat = 10
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(height: height)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .padding(.horizontal, isFullWidth ? 0 : 30)
            .background(backgroundColor.opacity(configuration.isPressed ? 0.8 : 1))
            .foregroundColor(foregroundColor)
            .cornerRadius(cornerRadius)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PTButtonStyle {
    static var primary: PTButtonStyle {
        PTButtonStyle(backgroundColor: Color.blue, foregroundColor: .white)
    }
    
    static var secondary: PTButtonStyle {
        PTButtonStyle(backgroundColor: Color(.systemGray5), foregroundColor: .black)
    }
    
    static var success: PTButtonStyle {
        PTButtonStyle(backgroundColor: Color.green, foregroundColor: .white)
    }
    
    static var danger: PTButtonStyle {
        PTButtonStyle(backgroundColor: Color.red, foregroundColor: .white)
    }
    
    static func custom(background: Color, foreground: Color, fullWidth: Bool = true, height: CGFloat = 50) -> PTButtonStyle {
        PTButtonStyle(
            backgroundColor: background,
            foregroundColor: foreground,
            isFullWidth: fullWidth,
            height: height
        )
    }
}