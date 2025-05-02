import SwiftUI
import Foundation
import CoreLocation

struct SettingsView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @State private var showLogoutConfirmation = false
    @State private var isLoggingOut = false
    
    // Helper functions for direct styling
    private func applySubheadingStyle(to text: Text) -> some View {
        text.font(.headline)
            .foregroundColor(Color.gray)
    }
    
    private func applyLabelStyle(to text: Text) -> some View {
        text.font(.subheadline)
            .foregroundColor(Color.gray)
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {

                if let user = auth.authState.user {
                    applySubheadingStyle(to: Text("Account"))
                        .padding(.horizontal, 16)

                    VStack(alignment: .leading) {
                        Text("\(user.firstName ?? "") \(user.lastName ?? "")")
                            .font(.headline)
                        applyLabelStyle(to: Text(user.email))
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
                    Section(header: applySubheadingStyle(to: Text("General"))) {
                        Text("Edit Profile (Not Implemented)")
                        Text("Notification Settings (Not Implemented)")
                    }
                    
                    // Section for Device Management
                    Section(header: applySubheadingStyle(to: Text("Device Management"))) {
                        NavigationLink("Scan for Bluetooth Devices") {
                            Text("Device Scanning View Placeholder")
                        }
                    }

                    Section {
                         Button(action: {
                             // Show confirmation before logout
                             showLogoutConfirmation = true
                         }) {
                             HStack {
                                 Text("Log Out")
                                 if isLoggingOut {
                                     Spacer()
                                     ProgressView()
                                 }
                             }
                         }
                         .foregroundColor(.red) // Standard color for destructive actions
                         .disabled(isLoggingOut)
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .frame(maxHeight: .infinity) // Allow list to take space
                .background(Color.white.opacity(0.1)) // Use lighter background
            }
            .background(Color(red: 0.957, green: 0.945, blue: 0.902).ignoresSafeArea()) // Use standard color extension
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Log Out", isPresented: $showLogoutConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Log Out", role: .destructive) {
                    performLogout()
                }
            } message: {
                Text("Are you sure you want to log out?")
            }
        }
    }
    
    // Safe logout implementation
    private func performLogout() {
        // Set loading state
        isLoggingOut = true
        
        // Use Task to perform logout after a small delay to allow UI to update
        Task {
            // Add a small delay to ensure UI updates
            try? await Task.sleep(nanoseconds: 500_000_000) // 500ms
            
            // Perform logout on main actor
            await MainActor.run {
                print("🔄 SettingsView - Performing logout")
                // Clear authentication
                auth.logout()
                isLoggingOut = false
            }
        }
    }
}

#Preview {
    // Directly create and configure the view within the preview
    SettingsView()
        .environmentObject(AuthViewModel())
} 