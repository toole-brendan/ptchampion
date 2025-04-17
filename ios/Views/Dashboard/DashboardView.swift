import SwiftUI

struct DashboardView: View {
    var body: some View {
        NavigationView { // Each tab can have its own navigation stack
            ScrollView {
                VStack(alignment: .leading, spacing: AppConstants.cardGap) {
                    Text("Dashboard")
                        .headingStyle()
                        .padding(.bottom)

                    // Placeholder content - replace with actual dashboard components
                    Text("Quick Stats")
                        .subheadingStyle()
                    HStack {
                        MetricCard(label: "Recent Pushups", value: "45")
                        MetricCard(label: "Avg Run Pace", value: "8:15/mi")
                    }

                    Text("Start Workout")
                        .subheadingStyle()
                        .padding(.top)
                    Button("Begin New Session") {
                        // TODO: Navigate to workout selection
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    Spacer()
                }
                .padding(AppConstants.globalPadding)
            }
            .background(Color.tacticalCream.ignoresSafeArea())
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
                .labelStyle()
            Text(value)
                .statsNumberStyle()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle() // Use the card background modifier
    }
}

#Preview {
    DashboardView()
        .environmentObject(AuthViewModel()) // Add if needed for user info
} 