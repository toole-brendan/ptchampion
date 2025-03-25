import SwiftUI
import Combine

class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = true
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Check for existing authentication session
        checkAuthStatus()
    }
    
    func checkAuthStatus() {
        isLoading = true
        
        APIClient.shared.getCurrentUser()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                
                if case .failure = completion {
                    self?.isAuthenticated = false
                    self?.currentUser = nil
                }
            }, receiveValue: { [weak self] user in
                self?.isAuthenticated = true
                self?.currentUser = user
            })
            .store(in: &cancellables)
    }
    
    func signOut() {
        isLoading = true
        
        APIClient.shared.logout()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    print("Logout error: \(error.localizedDescription)")
                }
                
                // Clear authentication state regardless of API success/failure
                self?.isAuthenticated = false
                self?.currentUser = nil
            }, receiveValue: { _ in
                // Logout successful
            })
            .store(in: &cancellables)
    }
}

struct AppCoordinator: View {
    @StateObject private var authManager = AuthManager()
    
    var body: some View {
        ZStack {
            if authManager.isLoading {
                LoadingView()
            } else if authManager.isAuthenticated {
                MainTabView()
                    .environmentObject(authManager)
            } else {
                LoginView()
                    .environmentObject(authManager)
            }
        }
    }
}

// Loading View
struct LoadingView: View {
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 70))
                    .foregroundColor(.blue)
                
                Text("PT Champion")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                ProgressView()
                    .scaleEffect(1.5)
                    .padding(.top, 20)
            }
        }
    }
}

// Preview
struct AppCoordinator_Previews: PreviewProvider {
    static var previews: some View {
        AppCoordinator()
    }
}