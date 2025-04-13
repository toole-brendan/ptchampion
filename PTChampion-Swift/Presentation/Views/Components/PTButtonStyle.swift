import SwiftUI

enum PTButtonType {
    case primary
    case secondary
    case success
    case danger
    case outline
}

struct PTButtonStyle: ButtonStyle {
    let type: PTButtonType
    let isFullWidth: Bool
    let isLoading: Bool
    
    init(type: PTButtonType = .primary, isFullWidth: Bool = true, isLoading: Bool = false) {
        self.type = type
        self.isFullWidth = isFullWidth
        self.isLoading = isLoading
    }
    
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .padding(.trailing, 8)
            }
            
            configuration.label
                .fontWeight(.medium)
        }
        .frame(maxWidth: isFullWidth ? .infinity : nil)
        .padding()
        .background(backgroundColor(isPressed: configuration.isPressed))
        .foregroundColor(foregroundColor())
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(borderColor(), lineWidth: type == .outline ? 2 : 0)
        )
        .opacity(configuration.isPressed ? 0.8 : 1.0)
        .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
    
    private func backgroundColor(isPressed: Bool) -> Color {
        let pressed = isPressed || isLoading
        
        switch type {
        case .primary:
            return pressed ? Color.blue.opacity(0.8) : Color.blue
        case .secondary:
            return pressed ? Color.gray.opacity(0.8) : Color.gray
        case .success:
            return pressed ? Color.green.opacity(0.8) : Color.green
        case .danger:
            return pressed ? Color.red.opacity(0.8) : Color.red
        case .outline:
            return pressed ? Color(.systemGray6) : Color(.systemBackground)
        }
    }
    
    private func foregroundColor() -> Color {
        switch type {
        case .outline:
            return .blue
        default:
            return .white
        }
    }
    
    private func borderColor() -> Color {
        switch type {
        case .primary, .outline:
            return .blue
        case .secondary:
            return .gray
        case .success:
            return .green
        case .danger:
            return .red
        }
    }
}

extension Button {
    func ptStyle(
        _ type: PTButtonType = .primary,
        isFullWidth: Bool = true,
        isLoading: Bool = false
    ) -> some View {
        self.buttonStyle(PTButtonStyle(type: type, isFullWidth: isFullWidth, isLoading: isLoading))
    }
}

// Preview
struct PTButtonStyle_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            Button("Primary Button") {}
                .ptStyle(.primary)
            
            Button("Secondary Button") {}
                .ptStyle(.secondary)
            
            Button("Success Button") {}
                .ptStyle(.success)
            
            Button("Danger Button") {}
                .ptStyle(.danger)
            
            Button("Outline Button") {}
                .ptStyle(.outline)
            
            Button("Loading...") {}
                .ptStyle(.primary, isLoading: true)
            
            Button("Not Full Width") {}
                .ptStyle(.primary, isFullWidth: false)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}