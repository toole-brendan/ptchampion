import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Account")) {
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
                    }
                    
                    Button(action: {
                        authViewModel.logout()
                    }) {
                        Text("Logout")
                            .foregroundColor(.red)
                    }
                }
                
                Section(header: Text("Preferences")) {
                    Toggle("Dark Mode", isOn: .constant(false))
                    Toggle("Notifications", isOn: .constant(true))
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    let mockAuth = AuthViewModel()
    mockAuth.currentUser = User(id: "test", email: "test@example.com", firstName: "Test", lastName: "User", profilePictureUrl: nil)
    
    return SettingsView()
        .environmentObject(mockAuth)
} 