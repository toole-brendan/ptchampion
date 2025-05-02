import SwiftUI
import Foundation
import CoreLocation

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {

                if let user = authViewModel.currentUser {
                    Text("Account")
                        .subheadingStyle()
                        .padding(.horizontal, 16)

                    VStack(alignment: .leading) {
                        Text("\(user.firstName ?? "") \(user.lastName ?? "")")
                            .font(.headline)
                        Text(user.email)
                            .labelStyle()
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(8)
                    .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
                    .padding(.horizontal, 16)

                } else {
                    Text("Loading user info...")
                        .padding(16)
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
                .background(Color.cream) // Use standard color extension
            }
            .background(Color.cream.ignoresSafeArea()) // Use standard color extension
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    // Directly create and configure the view within the preview
    SettingsView()
        .environmentObject({ // Use a closure to configure the mock object inline
            let mockAuth = AuthViewModel()
            mockAuth._isAuthenticatedInternal = true // Set internal state for preview
            mockAuth.currentUser = User(id: "test", email: "test@example.com", firstName: "Test", lastName: "User", profilePictureUrl: nil)
            return mockAuth
        }())
} 