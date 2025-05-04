import SwiftUI
import PTDesignSystem

struct DashboardView: View {
    // Keep track of the constants we need
    private static let cardGap: CGFloat = AppTheme.GeneratedSpacing.itemSpacing
    private static let globalPadding: CGFloat = AppTheme.GeneratedSpacing.contentPadding
    
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationView { // Each tab can have its own navigation stack
            ScrollView {
                VStack(alignment: .leading, spacing: Self.cardGap) {
                    PTLabel("Dashboard", style: .heading)
                        .padding(.bottom)

                    // Placeholder content - replace with actual dashboard components
                    PTLabel("Quick Stats", style: .subheading)
                    HStack {
                        MetricCard(label: "Recent Pushups", value: "45")
                        MetricCard(label: "Avg Run Pace", value: "8:15/mi")
                    }

                    PTLabel("Start Workout", style: .subheading)
                        .padding(.top)
                    
                    PTButton("Begin New Session") {
                        // TODO: Navigate to workout selection
                    }
                    
                    Spacer()
                }
                .padding(Self.globalPadding)
            }
            .background(AppTheme.GeneratedColors.background.ignoresSafeArea())
            .navigationTitle("Dashboard") // Use large title or inline
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// Example Metric Card (move to Shared Views later)
struct MetricCard: View {
    let label: String
    let value: String

    var body: some View {
        PTCard {
            VStack(alignment: .leading) {
                PTLabel(label, style: .caption)
                    .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                
                PTLabel(value, style: .heading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    let previewAuth = AuthViewModel()
    return DashboardView()
        .environmentObject(previewAuth)
        .environment(\.colorScheme, .light)
} 