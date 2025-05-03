import SwiftUI

struct DashboardView: View {
    // Keep track of the constants we need
    private static let cardGap: CGFloat = AppTheme.GeneratedSpacing.itemSpacing
    private static let globalPadding: CGFloat = AppTheme.GeneratedSpacing.contentPadding
    
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationView { // Each tab can have its own navigation stack
            ScrollView {
                VStack(alignment: .leading, spacing: Self.cardGap) {
                    Text("Dashboard")
                        .font(AppTheme.GeneratedTypography.heading())
                        .fontWeight(.bold)
                        .padding(.bottom)

                    // Placeholder content - replace with actual dashboard components
                    Text("Quick Stats")
                        .font(AppTheme.GeneratedTypography.subheading())
                    HStack {
                        MetricCard(label: "Recent Pushups", value: "45")
                        MetricCard(label: "Avg Run Pace", value: "8:15/mi")
                    }

                    Text("Start Workout")
                        .font(AppTheme.GeneratedTypography.subheading())
                        .padding(.top)
                    Button("Begin New Session") {
                        // TODO: Navigate to workout selection
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(AppTheme.GeneratedColors.primary)
                    .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                    .font(AppTheme.GeneratedTypography.buttonText())
                    .cornerRadius(AppTheme.GeneratedRadius.button)

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
        VStack(alignment: .leading) {
            Text(label)
                .font(AppTheme.GeneratedTypography.caption())
                .foregroundColor(AppTheme.GeneratedColors.textSecondary)
            Text(value)
                .font(AppTheme.GeneratedTypography.title())
                .fontWeight(.medium)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.GeneratedColors.cardBackground)
        .cornerRadius(AppTheme.GeneratedRadius.card)
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
    }
}

#Preview {
    let previewAuth = AuthViewModel()
    return DashboardView()
        .environmentObject(previewAuth)
        .environment(\.colorScheme, .light)
} 