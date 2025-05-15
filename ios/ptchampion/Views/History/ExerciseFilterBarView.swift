import SwiftUI
import PTDesignSystem

struct ExerciseFilterBarView: View {
    @Binding var filter: WorkoutFilter
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.GeneratedSpacing.itemSpacing) {
                ForEach(WorkoutFilter.allCases) { filterOption in
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            filter = filterOption
                        }
                    } label: {
                        HStack(spacing: 6) {
                            if let customIcon = filterOption.customIconName {
                                Image(customIcon)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 16, height: 16)
                            } else {
                                Image(systemName: filterOption.systemImage)
                                    .font(.system(size: 12))
                            }
                            
                            Text(filterOption.rawValue)
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(filter == filterOption ? 
                                      AppTheme.GeneratedColors.primary : 
                                      AppTheme.GeneratedColors.cardBackground)
                                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                        )
                        .foregroundColor(filter == filterOption ? 
                                         AppTheme.GeneratedColors.textOnPrimary : 
                                         AppTheme.GeneratedColors.textPrimary)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding(.horizontal, AppTheme.GeneratedSpacing.contentPadding)
        }
    }
}

// Custom button style for filter pills
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

#Preview {
    ExerciseFilterBarView(filter: .constant(.all))
        .previewLayout(.sizeThatFits)
        .padding()
} 