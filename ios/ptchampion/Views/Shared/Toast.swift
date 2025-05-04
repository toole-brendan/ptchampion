import SwiftUI
import PTDesignSystem

/// Toast notification types
enum ToastType {
    case success
    case error
    case warning
    case info
    
    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }
    
    var bgColor: Color {
        switch self {
        case .success: return AppTheme.GeneratedColors.success.opacity(0.15)
        case .error: return AppTheme.GeneratedColors.error.opacity(0.15)
        case .warning: return AppTheme.GeneratedColors.warning.opacity(0.15)
        case .info: return AppTheme.GeneratedColors.info.opacity(0.15)
        }
    }
    
    var iconColor: Color {
        switch self {
        case .success: return AppTheme.GeneratedColors.success
        case .error: return AppTheme.GeneratedColors.error
        case .warning: return AppTheme.GeneratedColors.warning
        case .info: return AppTheme.GeneratedColors.info
        }
    }
    
    var textColor: Color {
        return AppTheme.GeneratedColors.textPrimary
    }
}

/// Toast notification view
struct Toast: View {
    let type: ToastType
    let title: String
    let message: String?
    var onDismiss: (() -> Void)?
    
    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.GeneratedSpacing.small) {
            // Icon
            Image(systemName: type.icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 20, height: 20)
                .foregroundColor(type.iconColor)
            
            // Content
            VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.extraSmall) {
                PTLabel(title, style: .bodyBold)
                    .foregroundColor(type.textColor)
                
                if let message = message {
                    PTLabel(message, style: .body, size: .small)
                        .foregroundColor(type.textColor.opacity(0.7))
                        .lineLimit(3)
                }
            }
            
            Spacer()
            
            // Dismiss button
            if onDismiss != nil {
                Button(action: { onDismiss?() }) {
                    Image(systemName: "xmark")
                        .foregroundColor(type.textColor.opacity(0.6))
                        .font(.system(size: 14, weight: .medium))
                }
                .padding(AppTheme.GeneratedSpacing.extraSmall)
            }
        }
        .padding(AppTheme.GeneratedSpacing.medium)
        .background(type.bgColor)
        .cornerRadius(AppTheme.GeneratedRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.GeneratedRadius.medium)
                .stroke(type.iconColor.opacity(0.1), lineWidth: 1)
        )
    }
}

/// Toast container for showing notifications in a stack
struct ToastContainer: View {
    @Binding var toasts: [ToastItem]
    
    var body: some View {
        VStack(spacing: AppTheme.GeneratedSpacing.small) {
            ForEach(toasts) { toast in
                Toast(
                    type: toast.type,
                    title: toast.title,
                    message: toast.message,
                    onDismiss: {
                        withAnimation {
                            toasts.removeAll { $0.id == toast.id }
                        }
                    }
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
                .onAppear {
                    // Auto-dismiss after toast.duration
                    if toast.autoDismiss {
                        DispatchQueue.main.asyncAfter(deadline: .now() + toast.duration) {
                            withAnimation {
                                toasts.removeAll { $0.id == toast.id }
                            }
                        }
                    }
                }
            }
        }
        .padding(AppTheme.GeneratedSpacing.medium)
        .frame(maxWidth: .infinity)
    }
}

/// Toast item model
struct ToastItem: Identifiable {
    let id = UUID()
    let type: ToastType
    let title: String
    let message: String?
    let duration: TimeInterval
    let autoDismiss: Bool
    
    init(type: ToastType, title: String, message: String? = nil, duration: TimeInterval = 3, autoDismiss: Bool = true) {
        self.type = type
        self.title = title
        self.message = message
        self.duration = duration
        self.autoDismiss = autoDismiss
    }
}

// MARK: - View Extensions for adding toasts easily

struct ToastViewModifier: ViewModifier {
    @Binding var toasts: [ToastItem]
    let alignment: Alignment
    
    init(toasts: Binding<[ToastItem]>, alignment: Alignment = .top) {
        self._toasts = toasts
        self.alignment = alignment
    }
    
    func body(content: Content) -> some View {
        ZStack(alignment: alignment) {
            content
            
            if !toasts.isEmpty {
                ToastContainer(toasts: $toasts)
            }
        }
    }
}

extension View {
    func toasts(_ toasts: Binding<[ToastItem]>, alignment: Alignment = .top) -> some View {
        self.modifier(ToastViewModifier(toasts: toasts, alignment: alignment))
    }
}

// MARK: - Helper extensions for adding toasts from ViewModel/View

extension View {
    func showToast(type: ToastType, title: String, message: String? = nil, toasts: Binding<[ToastItem]>) -> some View {
        DispatchQueue.main.async {
            withAnimation {
                toasts.wrappedValue.append(ToastItem(type: type, title: title, message: message))
            }
        }
        return self
    }
}

// Preview Provider
struct Toast_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            VStack(spacing: AppTheme.GeneratedSpacing.large) {
                // Individual toasts
                Toast(type: .success, title: "Success", message: "Your action was completed successfully.")
                Toast(type: .error, title: "Error", message: "Something went wrong. Please try again.")
                Toast(type: .warning, title: "Warning", message: "This action might have consequences.")
                Toast(type: .info, title: "Information", message: "Here is some helpful information for you.")
                
                // Toast without message
                Toast(type: .success, title: "Operation complete")
                
                // Toast container example
                ToastExample()
            }
            .padding()
            .background(AppTheme.GeneratedColors.background.opacity(0.5))
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Light Mode")
            
            // Dark mode preview
            VStack(spacing: AppTheme.GeneratedSpacing.large) {
                Toast(type: .success, title: "Success", message: "Your action was completed successfully.")
                Toast(type: .error, title: "Error", message: "Something went wrong. Please try again.")
            }
            .padding()
            .background(AppTheme.GeneratedColors.background.opacity(0.5))
            .environment(\.colorScheme, .dark)
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Dark Mode")
        }
    }
    
    struct ToastExample: View {
        @State private var toasts: [ToastItem] = []
        
        var body: some View {
            PTCard {
                VStack(spacing: AppTheme.GeneratedSpacing.medium) {
                    PTButton("Show Success Toast") {
                        toasts.append(ToastItem(type: .success, title: "Success", message: "Operation completed"))
                    }
                    
                    PTButton("Show Error Toast", style: .destructive) {
                        toasts.append(ToastItem(type: .error, title: "Error", message: "Something went wrong"))
                    }
                }
                .padding()
            }
            .toasts($toasts)
        }
    }
} 