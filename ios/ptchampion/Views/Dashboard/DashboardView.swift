import SwiftUI

struct DashboardView: View {
    // Keep track of the constants we need
    private static let cardGap: CGFloat = 12
    private static let globalPadding: CGFloat = 16
    
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationView { // Each tab can have its own navigation stack
            ScrollView {
                VStack(alignment: .leading, spacing: Self.cardGap) {
                    Text("Dashboard")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.bottom)

                    // Placeholder content - replace with actual dashboard components
                    Text("Quick Stats")
                        .font(.headline)
                    HStack {
                        MetricCard(label: "Recent Pushups", value: "45")
                        MetricCard(label: "Avg Run Pace", value: "8:15/mi")
                    }

                    Text("Start Workout")
                        .font(.headline)
                        .padding(.top)
                    Button("Begin New Session") {
                        // TODO: Navigate to workout selection
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .font(.headline)
                    .cornerRadius(8)

                    Spacer()
                }
                .padding(Self.globalPadding)
            }
            .background(Color(red: 0.957, green: 0.945, blue: 0.902).ignoresSafeArea())
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
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title3)
                .fontWeight(.medium)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 0.957, green: 0.945, blue: 0.902))
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
    }
}

#Preview {
    DashboardView()
        .environmentObject(AuthViewModel()) // Add if needed for user info
} 