import SwiftUI
import PTDesignSystem

// Use global DSColor and SColor aliases

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
    
    var bgColor: SwiftUI.Color {
        switch self {
        case .success: return ThemeColor.success.opacity(0.15)
        case .error: return ThemeColor.error.opacity(0.15)
        case .warning: return ThemeColor.warning.opacity(0.15)
        case .info: return ThemeColor.info.opacity(0.15)
        }
    }
    
    var iconColor: SwiftUI.Color {
        switch self {
        case .success: return ThemeColor.success
        case .error: return ThemeColor.error
        case .warning: return ThemeColor.warning
        case .info: return ThemeColor.info
        }
    }
    
    var textColor: SwiftUI.Color {
        return ThemeColor.textPrimary
    }
}

/// Toast notification view
struct Toast: View {
    let type: ToastType
    let title: String
    let message: String?
    var onDismiss: (() -> Void)?
    
    var body: some View {
        HStack(alignment: .top, spacing: Spacing.small) {
            // Icon
            Image(systemName: type.icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 20, height: 20)
                .foregroundColor(type.iconColor)
            
            // Content
            VStack(alignment: .leading, spacing: Spacing.extraSmall) {
                Text(title)
                    .body(weight: .medium)
                    .foregroundColor(type.textColor)
                
                if let message = message {
                    Text(message)
                        .caption()
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
                        .font(.system(size: Spacing.small, weight: .medium))
                }
                .padding(Spacing.extraSmall)
            }
        }
        .padding(Spacing.medium)
        .background(type.bgColor)
        .cornerRadius(CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.medium)
                .stroke(type.iconColor.opacity(0.1), lineWidth: 1)
        )
    }
}

/// Toast container for showing notifications in a stack
struct ToastContainer: View {
    @Binding var toasts: [ToastItem]
    
    var body: some View {
        VStack(spacing: Spacing.small) {
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
        .padding(Spacing.medium)
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
            VStack(spacing: Spacing.large) {
                // Individual toasts
                Toast(type: .success, title: "Success", message: "Your action was completed successfully.")
                Toast(type: .error, title: "Error", message: "Something went wrong. Please try again.")
                Toast(type: .warning, title: "Warning", message: "This action might have consequences.")
                Toast(type: .info, title: "Information", message: "Here is some helpful information for you.")
                
                // Toast without message
                Toast(type: .success, title: "Operation complete", message: nil)
                
                // Toast container example
                ToastExample()
            }
            .padding()
            .background(ThemeColor.background.opacity(0.5))
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Light Mode")
            
            // Dark mode preview
            VStack(spacing: Spacing.large) {
                Toast(type: .success, title: "Success", message: "Your action was completed successfully.")
                Toast(type: .error, title: "Error", message: "Something went wrong. Please try again.")
            }
            .padding()
            .background(ThemeColor.background.opacity(0.5))
            .environment(\.colorScheme, .dark)
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Dark Mode")
        }
    }
    
    struct ToastExample: View {
        @State private var toasts: [ToastItem] = []
        
        var body: some View {
            VStack {
                VStack(spacing: Spacing.medium) {
                    // Use a typed local variable to resolve ambiguity
                    let coreButtonStyle: PTButton.ButtonStyle = .primary
                    PTButton("Show Success Toast", style: coreButtonStyle) {
                        toasts.append(ToastItem(type: .success, title: "Success", message: "Operation completed"))
                    }
                    
                    let destructiveButtonStyle: PTButton.ButtonStyle = .destructive
                    PTButton("Show Error Toast", style: destructiveButtonStyle) {
                        toasts.append(ToastItem(type: .error, title: "Error", message: "Something went wrong"))
                    }
                }
                .padding()
            }
            .card()
            .toasts($toasts)
        }
    }
} 