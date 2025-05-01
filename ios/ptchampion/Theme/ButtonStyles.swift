import SwiftUI

enum PTButtonVariant {
    case primary
    case secondary
    case outline
    case ghost
    case destructive
}

struct PTButtonStyle: ButtonStyle {
    var variant: PTButtonVariant = .primary
    var isFullWidth: Bool = false
    var isLoading: Bool = false
    var size: PTButtonSize = .medium
    
    func makeBody(configuration: Configuration) -> some View {
        let scale = configuration.isPressed ? 0.98 : 1.0
        
        switch variant {
        case .primary:
            return AnyView(
                configuration.label
                    .font(size.font)
                    .padding(.horizontal, size.horizontalPadding)
                    .padding(.vertical, size.verticalPadding)
                    .frame(maxWidth: isFullWidth ? .infinity : nil, minHeight: size.height)
                    .foregroundColor(AppTheme.Colors.deepOps)
                    .background(AppTheme.Colors.brassGold)
                    .cornerRadius(AppTheme.Radius.button)
                    .opacity(configuration.isPressed ? 0.9 : 1.0)
                    .overlay(
                        isLoading ? ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.deepOps))
                            .padding(8) : nil
                    )
                    .scaleEffect(scale)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
                    .disabled(isLoading)
            )
            
        case .secondary:
            return AnyView(
                configuration.label
                    .font(size.font)
                    .padding(.horizontal, size.horizontalPadding)
                    .padding(.vertical, size.verticalPadding)
                    .frame(maxWidth: isFullWidth ? .infinity : nil, minHeight: size.height)
                    .foregroundColor(AppTheme.Colors.cream)
                    .background(AppTheme.Colors.deepOps)
                    .cornerRadius(AppTheme.Radius.button)
                    .opacity(configuration.isPressed ? 0.9 : 1.0)
                    .overlay(
                        isLoading ? ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.cream))
                            .padding(8) : nil
                    )
                    .scaleEffect(scale)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
                    .disabled(isLoading)
            )
            
        case .outline:
            return AnyView(
                configuration.label
                    .font(size.font)
                    .padding(.horizontal, size.horizontalPadding)
                    .padding(.vertical, size.verticalPadding)
                    .frame(maxWidth: isFullWidth ? .infinity : nil, minHeight: size.height)
                    .foregroundColor(AppTheme.Colors.brassGold)
                    .background(Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.button)
                            .strokeBorder(AppTheme.Colors.brassGold, lineWidth: 1)
                    )
                    .opacity(configuration.isPressed ? 0.9 : 1.0)
                    .overlay(
                        isLoading ? ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.brassGold))
                            .padding(8) : nil
                    )
                    .scaleEffect(scale)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
                    .disabled(isLoading)
            )
            
        case .ghost:
            return AnyView(
                configuration.label
                    .font(size.font)
                    .padding(.horizontal, size.horizontalPadding)
                    .padding(.vertical, size.verticalPadding)
                    .frame(maxWidth: isFullWidth ? .infinity : nil, minHeight: size.height)
                    .foregroundColor(AppTheme.Colors.deepOps)
                    .background(configuration.isPressed ? AppTheme.Colors.brassGold.opacity(0.1) : Color.clear)
                    .cornerRadius(AppTheme.Radius.button)
                    .overlay(
                        isLoading ? ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.deepOps))
                            .padding(8) : nil
                    )
                    .scaleEffect(scale)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
                    .disabled(isLoading)
            )
            
        case .destructive:
            return AnyView(
                configuration.label
                    .font(size.font)
                    .padding(.horizontal, size.horizontalPadding)
                    .padding(.vertical, size.verticalPadding)
                    .frame(maxWidth: isFullWidth ? .infinity : nil, minHeight: size.height)
                    .foregroundColor(.white)
                    .background(AppTheme.Colors.error)
                    .cornerRadius(AppTheme.Radius.button)
                    .opacity(configuration.isPressed ? 0.9 : 1.0)
                    .overlay(
                        isLoading ? ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .padding(8) : nil
                    )
                    .scaleEffect(scale)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
                    .disabled(isLoading)
            )
        }
    }
}

enum PTButtonSize {
    case small
    case medium
    case large
    
    var font: Font {
        switch self {
        case .small: return AppTheme.Typography.body(size: 12)
        case .medium: return AppTheme.Typography.body(size: 14)
        case .large: return AppTheme.Typography.body(size: 16)
        }
    }
    
    var horizontalPadding: CGFloat {
        switch self {
        case .small: return 12
        case .medium: return 16
        case .large: return 20
        }
    }
    
    var verticalPadding: CGFloat {
        switch self {
        case .small: return 6
        case .medium: return 8
        case .large: return 10
        }
    }
    
    var height: CGFloat {
        switch self {
        case .small: return 32
        case .medium: return 40
        case .large: return 48
        }
    }
}

extension View {
    func ptButtonStyle(
        variant: PTButtonVariant = .primary,
        isFullWidth: Bool = false,
        isLoading: Bool = false,
        size: PTButtonSize = .medium
    ) -> some View {
        self.buttonStyle(PTButtonStyle(
            variant: variant,
            isFullWidth: isFullWidth,
            isLoading: isLoading,
            size: size
        ))
    }
} 