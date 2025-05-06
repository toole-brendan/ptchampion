import SwiftUI
import PTDesignSystem

/// ValidationState enum to replace the removed validationState(_:) extension on PTTextField
enum ValidationState {
    case valid
    case invalid(message: String)
    
    var borderColor: Color {
        switch self {
        case .valid:
            return AppTheme.GeneratedColors.success
        case .invalid:
            return AppTheme.GeneratedColors.error
        }
    }
    
    var message: String? {
        switch self {
        case .valid:
            return nil
        case .invalid(let message):
            return message
        }
    }
}

/// Extension to add validation border functionality to views (especially text fields)
extension View {
    /// Adds a colored border based on validation state
    func ptValidationBorder(_ state: ValidationState) -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(state.borderColor, lineWidth: 1)
        )
        .overlay(
            Group {
                if let message = state.message {
                    VStack(alignment: .leading) {
                        Spacer()
                        Text(message)
                            .font(.caption)
                            .foregroundColor(state.borderColor)
                            .padding(.leading, 4)
                            .padding(.top, 4)
                    }
                }
            },
            alignment: .bottom
        )
    }
} 