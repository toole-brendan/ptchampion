import SwiftUI
import Combine

class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = true
    @Published var apiHealthy = true
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Check API health and then auth status
        checkApiHealth()
    }
    
    // Check API health first
    private func checkApiHealth() {
        APIClient.shared.checkApiHealth()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure = completion {
                    self?.apiHealthy = false
                    self?.isLoading = false
                } else {
                    self?.apiHealthy = true
                    // After confirming API is healthy, check auth
                    self?.checkAuthStatus()
                }
            }, receiveValue: { _ in })
            .store(in: &cancellables)
    }
    
    // First try to validate token, then fetch user if successful
    func checkAuthStatus() {
        guard apiHealthy else {
            isLoading = false
            isAuthenticated = false
            return
        }
        
        // Check if we're already logged in via token
        isLoading = true
        
        // First validate the token
        APIClient.shared.validateToken()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] _ in
                // Completion handled by receive value
            }, receiveValue: { [weak self] isValid in
                if isValid {
                    // Token is valid, fetch current user
                    self?.fetchCurrentUser()
                } else {
                    // Not authenticated
                    self?.isLoading = false
                    self?.isAuthenticated = false
                    self?.currentUser = nil
                }
            })
            .store(in: &cancellables)
    }
    
    // Fetch current user after validating token
    private func fetchCurrentUser() {
        APIClient.shared.getCurrentUser()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                
                if case .failure = completion {
                    self?.isAuthenticated = false
                    self?.currentUser = nil
                }
            }, receiveValue: { [weak self] user in
                self?.isLoading = false
                self?.isAuthenticated = true
                self?.currentUser = user
            })
            .store(in: &cancellables)
    }
    
    // Login with username/password
    func login(username: String, password: String) -> AnyPublisher<User, Error> {
        isLoading = true
        
        return APIClient.shared.login(username: username, password: password)
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveOutput: { [weak self] user in
                self?.isLoading = false
                self?.isAuthenticated = true
                self?.currentUser = user
            }, receiveCompletion: { [weak self] completion in
                if case .failure = completion {
                    self?.isLoading = false
                }
            })
            .eraseToAnyPublisher()
    }
    
    // Register new user
    func register(username: String, password: String) -> AnyPublisher<User, Error> {
        isLoading = true
        
        return APIClient.shared.register(username: username, password: password)
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveOutput: { [weak self] user in
                self?.isLoading = false
                self?.isAuthenticated = true
                self?.currentUser = user
            }, receiveCompletion: { [weak self] completion in
                if case .failure = completion {
                    self?.isLoading = false
                }
            })
            .eraseToAnyPublisher()
    }
    
    // Sign out - clear token and state
    func signOut() {
        isLoading = true
        
        APIClient.shared.logout()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                self?.isAuthenticated = false
                self?.currentUser = nil
                
                if case .failure(let error) = completion {
                    print("Logout error: \(error.localizedDescription)")
                }
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
            } else if !authManager.apiHealthy {
                ApiErrorView(retryAction: {
                    authManager.checkAuthStatus()
                })
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

// API Error View
struct ApiErrorView: View {
    let retryAction: () -> Void
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 70))
                    .foregroundColor(.orange)
                
                Text("Connection Problem")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Cannot connect to the PT Champion server. Please check your internet connection and try again.")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                
                Button(action: retryAction) {
                    Text("Retry")
                        .fontWeight(.semibold)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(.top, 20)
            }
            .padding()
        }
    }
}

// Preview
struct AppCoordinator_Previews: PreviewProvider {
    static var previews: some View {
        AppCoordinator()
    }
}