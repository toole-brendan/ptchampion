import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    // Use AppStorage to persist unit preference
    // Key "distanceUnit" will store the rawValue of the selected DistanceUnit
    @AppStorage("distanceUnit") private var selectedUnit: DistanceUnit = .miles

    var body: some View {
        NavigationView {
            Form { // Use Form for standard settings layout
                // Section 1: Profile Information
                Section(header: Text("Profile")) {
                    if let user = authViewModel.currentUser {
                        HStack {
                            Text("Name")
                            Spacer()
                            Text("\(user.firstName) \(user.lastName)")
                                .foregroundColor(.gray)
                        }
                        HStack {
                            Text("Email")
                            Spacer()
                            Text(user.email)
                                .foregroundColor(.gray)
                        }
                    } else {
                        Text("Not logged in")
                    }
                }

                // Section 2: Preferences (e.g., Units)
                Section(header: Text("Preferences")) {
                    Picker("Distance Unit", selection: $selectedUnit) {
                        ForEach(DistanceUnit.allCases) { unit in
                            Text(unit.rawValue).tag(unit)
                        }
                    }
                    // Optional: Apply picker style if needed
                    // .pickerStyle(.segmented) // Example style
                }

                // Section 3: Account Actions
                Section {
                    Button("Log Out", role: .destructive) {
                        authViewModel.logout()
                    }
                    .foregroundColor(.red) // Emphasize destructive action
                }
            }
            .navigationTitle("Settings")
            .background(Color.tacticalCream.ignoresSafeArea())
             // Apply background to the Form content area if Form styling allows
             .scrollContentBackground(.hidden) // Make Form background transparent for custom color
        }
    }
}

#Preview {
    // Mock AuthViewModel for preview
    let mockAuth = AuthViewModel()
    mockAuth.isAuthenticated = true
    mockAuth.currentUser = User(id: "preview-id", email: "preview@user.com", firstName: "Preview", lastName: "User")

    return SettingsView()
        .environmentObject(mockAuth)
} 