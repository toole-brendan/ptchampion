import SwiftUI
import PTDesignSystem

// Enhanced empty state view with military styling
struct EmptyHistoryDisplayView: View {
    let currentFilter: WorkoutFilter
    
    var body: some View {
        let specificFilterText = currentFilter == .all ? "Workouts" : currentFilter.rawValue
        let titleString = "No \(specificFilterText) Yet"
        let imageForEmptyState: Image
        
        if let customIcon = currentFilter.customIconName {
            imageForEmptyState = Image(customIcon)
        } else {
            imageForEmptyState = Image(systemName: currentFilter.systemImage)
        }
        
        return PTCard(style: .elevated) {
            VStack(spacing: AppTheme.GeneratedSpacing.medium) {
                imageForEmptyState
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(AppTheme.GeneratedColors.brassGold.opacity(0.6))
                    .padding(.top, AppTheme.GeneratedSpacing.medium)
                
                VStack(spacing: AppTheme.GeneratedSpacing.small) {
                    PTLabel(titleString, style: .heading)
                        .multilineTextAlignment(.center)
                    
                    PTLabel("Complete a workout to see your progress here!", style: .body)
                        .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.bottom, AppTheme.GeneratedSpacing.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, AppTheme.GeneratedSpacing.medium)
        }
    }
}

#Preview {
    EmptyHistoryDisplayView(currentFilter: .all)
        .padding()
} 