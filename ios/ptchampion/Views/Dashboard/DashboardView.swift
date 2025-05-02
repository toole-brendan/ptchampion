import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Welcome to PT Champion")
                    .font(.title)
                    .padding()
                
                if let user = authViewModel.currentUser {
                    Text("Hello, \(user.firstName)!")
                        .font(.headline)
                        .padding()
                }
                
                Spacer()
            }
            .navigationTitle("Dashboard")
        }
    }
}

#Preview {
    let mockAuth = AuthViewModel()
    mockAuth.currentUser = User(id: "test", email: "test@example.com", firstName: "Test", lastName: "User", profilePictureUrl: nil)
    
    return DashboardView()
        .environmentObject(mockAuth)
} 