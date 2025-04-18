import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {

                if let user = authViewModel.currentUser {
                    Text("Account")
                        .subheadingStyle()
                        .padding(.horizontal, AppConstants.globalPadding)

                    VStack(alignment: .leading) {
                        Text("\(user.firstName ?? "") \(user.lastName ?? "")")
                            .font(.headline)
                        Text(user.email)
                            .labelStyle()
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cardStyle()
                    .padding(.horizontal, AppConstants.globalPadding)

                } else {
                    Text("Loading user info...")
                        .padding(AppConstants.globalPadding)
                }

                // Add other settings options here (e.g., profile edit, notifications)
                List {
                    Section(header: Text("General").subheadingStyle()) {
                        Text("Edit Profile (Not Implemented)")
                        Text("Notification Settings (Not Implemented)")
                    }
                    
                    // Section for Device Management
                    Section(header: Text("Device Management").subheadingStyle()) {
                        NavigationLink("Scan for Bluetooth Devices") {
                            DeviceScanningView()
                        }
                    }

                    Section {
                         Button("Log Out") {
                             authViewModel.logout()
                         }
                         .foregroundColor(.red) // Standard color for destructive actions
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .frame(maxHeight: .infinity) // Allow list to take space
                .background(Color.tacticalCream)
            }
            .background(Color.tacticalCream.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    // Create a mock view model with a logged-in user for preview
    let mockAuth = AuthViewModel()
    mockAuth.isAuthenticated = true
    mockAuth.currentUser = User(id: "preview-id", email: "preview@user.com", firstName: "Preview", lastName: "User")

    return SettingsView()
        .environmentObject(mockAuth)
} 