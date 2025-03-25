import Foundation
import Combine
import CoreLocation

class AuthViewModel: ObservableObject {
    // Published properties for UI updates
    @Published var user: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var error: String?
    
    // Location manager for getting user's location
    private var locationManager: CLLocationManager?
    
    init() {
        // Check for existing session on app launch
        checkCurrentSession()
    }
    
    // Check if user is already logged in
    private func checkCurrentSession() {
        isLoading = true
        
        NetworkService.shared.getCurrentUser { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let user):
                    self?.user = user
                    self?.isAuthenticated = true
                    // Initialize location services if needed
                    if !user.hasLocation {
                        self?.initializeLocationServices()
                    }
                case .failure:
                    // No active session, user needs to log in
                    self?.isAuthenticated = false
                }
            }
        }
    }
    
    // Login with username and password
    func login(username: String, password: String) {
        guard !username.isEmpty, !password.isEmpty else {
            self.error = "Username and password cannot be empty"
            return
        }
        
        isLoading = true
        error = nil
        
        NetworkService.shared.login(username: username, password: password) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let user):
                    self?.user = user
                    self?.isAuthenticated = true
                    // Initialize location services if needed
                    if !user.hasLocation {
                        self?.initializeLocationServices()
                    }
                case .failure(let error):
                    self?.error = error.localizedDescription
                }
            }
        }
    }
    
    // Register new user
    func register(username: String, password: String) {
        guard !username.isEmpty, !password.isEmpty else {
            self.error = "Username and password cannot be empty"
            return
        }
        
        isLoading = true
        error = nil
        
        NetworkService.shared.register(username: username, password: password) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let user):
                    self?.user = user
                    self?.isAuthenticated = true
                    // Initialize location services right after registration
                    self?.initializeLocationServices()
                case .failure(let error):
                    self?.error = error.localizedDescription
                }
            }
        }
    }
    
    // Logout current user
    func logout() {
        // Clear user data
        user = nil
        isAuthenticated = false
        
        // No need to call API for logout as we're using stateless JWT tokens
        // Simply clearing the local state is sufficient
    }
    
    // Initialize location services for getting user's position
    private func initializeLocationServices() {
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        
        // Request permission
        locationManager?.requestWhenInUseAuthorization()
        
        // Start updating location if authorized
        if CLLocationManager.locationServicesEnabled() {
            locationManager?.startUpdatingLocation()
        }
    }
    
    // Update user's location on the server
    func updateUserLocation(latitude: Double, longitude: Double) {
        isLoading = true
        
        NetworkService.shared.updateUserLocation(latitude: latitude, longitude: longitude) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let updatedUser):
                    self?.user = updatedUser
                case .failure(let error):
                    self?.error = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension AuthViewModel: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Stop updating location after we get a good fix
        locationManager?.stopUpdatingLocation()
        
        // Update the user's location on the server
        updateUserLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager error: \(error.localizedDescription)")
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        case .denied, .restricted:
            // Handle permission denied
            self.error = "Location access denied. Some features may be limited."
        case .notDetermined:
            // Wait for user decision
            break
        @unknown default:
            break
        }
    }
}