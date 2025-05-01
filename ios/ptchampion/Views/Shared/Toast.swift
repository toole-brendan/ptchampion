import SwiftUI

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
        case .success: return LegacyColor.fromHex("#10B981").opacity(0.15) // emerald-500
        case .error: return LegacyColor.fromHex("#DC2626").opacity(0.15) // red-600
        case .warning: return LegacyColor.fromHex("#F59E0B").opacity(0.15) // amber-500
        case .info: return LegacyColor.fromHex("#3B82F6").opacity(0.15) // blue-500
        }
    }
    
    var iconColor: Color {
        switch self {
        case .success: return LegacyColor.fromHex("#10B981") // emerald-500
        case .error: return LegacyColor.fromHex("#DC2626") // red-600
        case .warning: return LegacyColor.fromHex("#F59E0B") // amber-500
        case .info: return LegacyColor.fromHex("#3B82F6") // blue-500
        }
    }
    
    var textColor: Color {
        return .commandBlack
    }
}

/// Toast notification view
struct Toast: View {
    let type: ToastType
    let title: String
    let message: String?
    var onDismiss: (() -> Void)?
    
    var body: some View {
        HStack(alignment: .top, spacing: AppConstants.Spacing.sm) {
            // Icon
            Image(systemName: type.icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 20, height: 20)
                .foregroundColor(type.iconColor)
            
            // Content
            VStack(alignment: .leading, spacing: AppConstants.Spacing.xs) {
                Text(title)
                    .font(.custom(AppFonts.bodyBold, size: AppConstants.FontSize.md))
                    .foregroundColor(type.textColor)
                
                if let message = message {
                    Text(message)
                        .font(.custom(AppFonts.body, size: AppConstants.FontSize.sm))
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
                .padding(AppConstants.Spacing.xs)
            }
        }
        .padding(AppConstants.Spacing.md)
        .background(type.bgColor)
        .cornerRadius(AppConstants.Radius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AppConstants.Radius.md)
                .stroke(type.iconColor.opacity(0.1), lineWidth: 1)
        )
    }
}

/// Toast container for showing notifications in a stack
struct ToastContainer: View {
    @Binding var toasts: [ToastItem]
    
    var body: some View {
        VStack(spacing: AppConstants.Spacing.sm) {
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
        .padding(AppConstants.Spacing.md)
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
        VStack(spacing: AppConstants.Spacing.xl) {
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
        .background(Color.tacticalCream.opacity(0.5))
        .previewLayout(.sizeThatFits)
    }
    
    struct ToastExample: View {
        @State private var toasts: [ToastItem] = []
        
        var body: some View {
            VStack(spacing: AppConstants.Spacing.lg) {
                Button("Show Success Toast") {
                    toasts.append(ToastItem(type: .success, title: "Success", message: "Operation completed"))
                }
                .primaryButtonStyle()
                
                Button("Show Error Toast") {
                    toasts.append(ToastItem(type: .error, title: "Error", message: "Something went wrong"))
                }
                .secondaryButtonStyle()
            }
            .padding()
            .background(Color.white)
            .cornerRadius(AppConstants.Radius.md)
            .toasts($toasts)
        }
    }
} 