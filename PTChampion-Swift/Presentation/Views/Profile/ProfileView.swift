import SwiftUI
import Combine
import CoreLocation

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel = ProfileViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // User profile header
                userProfileHeader
                
                // Statistics summary
                statisticsSummary
                
                // Preferences section
                preferencesSection
                
                // Account section
                accountSection
                
                // About section
                aboutSection
                
                // Sign out button
                Button(action: {
                    viewModel.signOut(authManager: authManager)
                }) {
                    Text("Sign Out")
                        .font(.headline)
                }
                .ptStyle(.danger)
                .padding(.top, 16)
                .padding(.bottom, 30)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Profile")
        .onAppear {
            if let user = authManager.currentUser {
                viewModel.loadUserData(user: user)
            }
        }
        .alert(isPresented: $viewModel.showAlert) {
            Alert(
                title: Text(viewModel.alertTitle),
                message: Text(viewModel.alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .sheet(isPresented: $viewModel.showingEditProfile) {
            EditProfileView(viewModel: viewModel)
        }
    }
    
    private var userProfileHeader: some View {
        VStack(spacing: 16) {
            // Profile image
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Text(viewModel.initials)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.blue)
            }
            
            // User info
            VStack(spacing: 8) {
                Text(viewModel.displayName)
                    .font(.title2)
                    .fontWeight(.bold)
                
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.secondary)
                    
                    Text("Member since \(viewModel.memberSince)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            // Edit profile button
            Button(action: {
                viewModel.showingEditProfile = true
            }) {
                HStack {
                    Image(systemName: "pencil")
                    Text("Edit Profile")
                }
            }
            .ptStyle(.outline, isFullWidth: false)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    private var statisticsSummary: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Statistics")
                .font(.headline)
                .fontWeight(.bold)
            
            HStack(spacing: 20) {
                // Total exercises completed
                StatCard(
                    value: "\(viewModel.exercisesCompleted)",
                    label: "Exercises",
                    icon: "figure.run",
                    color: .blue
                )
                
                // Overall score
                StatCard(
                    value: "\(viewModel.overallScore)",
                    label: "Score",
                    icon: "star.fill",
                    color: .yellow
                )
                
                // Days streak
                StatCard(
                    value: "\(viewModel.daysStreak)",
                    label: "Streak",
                    icon: "flame.fill",
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Preferences")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(spacing: 0) {
                // Location services
                Toggle(isOn: $viewModel.locationEnabled) {
                    HStack {
                        Image(systemName: "location")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        
                        Text("Location Services")
                            .font(.body)
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: .blue))
                .padding()
                .onChange(of: viewModel.locationEnabled) { newValue in
                    if newValue {
                        viewModel.requestLocationPermission()
                    }
                }
                
                Divider()
                    .padding(.leading, 50)
                
                // Bluetooth connections
                Toggle(isOn: $viewModel.bluetoothEnabled) {
                    HStack {
                        Image(systemName: "wave.3.right")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        
                        Text("Bluetooth Connectivity")
                            .font(.body)
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: .blue))
                .padding()
                .onChange(of: viewModel.bluetoothEnabled) { newValue in
                    if newValue {
                        viewModel.checkBluetoothPermission()
                    }
                }
                
                Divider()
                    .padding(.leading, 50)
                
                // Notifications
                Toggle(isOn: $viewModel.notificationsEnabled) {
                    HStack {
                        Image(systemName: "bell")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        
                        Text("Push Notifications")
                            .font(.body)
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: .blue))
                .padding()
                .onChange(of: viewModel.notificationsEnabled) { newValue in
                    if newValue {
                        viewModel.requestNotificationPermission()
                    }
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
    }
    
    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Account")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(spacing: 0) {
                SettingsRow(
                    icon: "lock",
                    title: "Change Password",
                    action: { viewModel.showChangePassword = true }
                )
                
                Divider()
                    .padding(.leading, 50)
                
                SettingsRow(
                    icon: "icloud.and.arrow.down",
                    title: "Sync Data",
                    displayText: viewModel.lastSyncTimeFormatted,
                    action: { viewModel.syncData() }
                )
                
                Divider()
                    .padding(.leading, 50)
                
                SettingsRow(
                    icon: "trash",
                    title: "Delete Account",
                    textColor: .red,
                    action: { viewModel.showDeleteAccountConfirmation = true }
                )
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
    }
    
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("About")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(spacing: 0) {
                SettingsRow(
                    icon: "doc.text",
                    title: "Terms of Service",
                    action: { viewModel.showTermsOfService = true }
                )
                
                Divider()
                    .padding(.leading, 50)
                
                SettingsRow(
                    icon: "hand.raised",
                    title: "Privacy Policy",
                    action: { viewModel.showPrivacyPolicy = true }
                )
                
                Divider()
                    .padding(.leading, 50)
                
                SettingsRow(
                    icon: "info.circle",
                    title: "App Version",
                    displayText: "1.0.0 (101)",
                    action: {}
                )
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
    }
}

struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    var displayText: String?
    var textColor: Color = .primary
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                Text(title)
                    .foregroundColor(textColor)
                
                Spacer()
                
                if let displayText = displayText {
                    Text(displayText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
    }
}

struct EditProfileView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var displayName = ""
    @State private var username = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profile Information")) {
                    TextField("Display Name", text: $displayName)
                    
                    TextField("Username", text: $username)
                        .disabled(true) // Username cannot be changed
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text("Location")) {
                    Toggle("Enable Location Services", isOn: $viewModel.locationEnabled)
                        .onChange(of: viewModel.locationEnabled) { newValue in
                            if newValue {
                                viewModel.requestLocationPermission()
                            }
                        }
                }
            }
            .onAppear {
                displayName = viewModel.displayName
                username = viewModel.username
            }
            .navigationTitle("Edit Profile")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    viewModel.updateProfile(displayName: displayName)
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

class ProfileViewModel: ObservableObject {
    // User profile data
    @Published var username = ""
    @Published var displayName = ""
    @Published var memberSince = ""
    
    // Statistics
    @Published var exercisesCompleted = 0
    @Published var overallScore = 0
    @Published var daysStreak = 0
    
    // Preferences
    @Published var locationEnabled = false
    @Published var bluetoothEnabled = false
    @Published var notificationsEnabled = false
    
    // UI state
    @Published var showingEditProfile = false
    @Published var showChangePassword = false
    @Published var showDeleteAccountConfirmation = false
    @Published var showTermsOfService = false
    @Published var showPrivacyPolicy = false
    @Published var showAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    
    private var cancellables = Set<AnyCancellable>()
    private let locationManager = CLLocationManager()
    
    var initials: String {
        guard !displayName.isEmpty else { return username.prefix(1).uppercased() }
        
        let components = displayName.components(separatedBy: " ")
        if components.count > 1 {
            let first = components[0].prefix(1)
            let last = components[1].prefix(1)
            return "\(first)\(last)".uppercased()
        } else {
            return displayName.prefix(1).uppercased()
        }
    }
    
    var lastSyncTimeFormatted: String {
        if let lastSyncString = UserDefaults.standard.string(forKey: "last_sync_timestamp") {
            let formatter = ISO8601DateFormatter()
            if let date = formatter.date(from: lastSyncString) {
                let displayFormatter = DateFormatter()
                displayFormatter.dateStyle = .short
                displayFormatter.timeStyle = .short
                return displayFormatter.string(from: date)
            }
        }
        return "Never"
    }
    
    func loadUserData(user: User) {
        username = user.username
        displayName = user.displayName ?? user.username // Use display name if available, or username as fallback
        
        // Format the date
        if let createdAt = user.createdAt {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            memberSince = formatter.string(from: createdAt)
        } else {
            memberSince = "Unknown"
        }
        
        // Check if location is already enabled
        locationEnabled = user.latitude != nil && user.longitude != nil
        
        // Load exercise statistics
        loadExerciseStats()
        
        // Check for last sync time
        if let lastSyncedAt = user.lastSyncedAt {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            let formattedDate = formatter.string(from: lastSyncedAt)
            
            // Store in UserDefaults as ISO8601 string for consistency
            let isoFormatter = ISO8601DateFormatter()
            UserDefaults.standard.set(isoFormatter.string(from: lastSyncedAt), forKey: "last_sync_timestamp")
        }
    }
    
    func loadExerciseStats() {
        APIClient.shared.getUserExercises()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.showError("Error loading stats", message: error.localizedDescription)
                }
            }, receiveValue: { [weak self] exercises in
                self?.processExerciseStats(exercises)
            })
            .store(in: &cancellables)
    }
    
    private func processExerciseStats(_ exercises: [UserExercise]) {
        // Count completed exercises
        exercisesCompleted = exercises.count
        
        // Calculate average score
        let validScores = exercises.compactMap { $0.grade }
        overallScore = validScores.isEmpty ? 0 : validScores.reduce(0, +) / validScores.count
        
        // Calculate streak (days with at least one exercise)
        calculateStreak(from: exercises)
    }
    
    private func calculateStreak(from exercises: [UserExercise]) {
        guard !exercises.isEmpty else {
            daysStreak = 0
            return
        }
        
        // Group exercises by day
        let calendar = Calendar.current
        let exercisesByDay = Dictionary(grouping: exercises) { exercise in
            calendar.startOfDay(for: exercise.createdAt)
        }
        
        // Sort days in descending order
        let sortedDays = exercisesByDay.keys.sorted(by: >)
        
        // Calculate streak from most recent day
        var currentStreak = 1
        guard let mostRecentDay = sortedDays.first else {
            daysStreak = 0
            return
        }
        
        // Check each previous day
        var currentDay = calendar.date(byAdding: .day, value: -1, to: mostRecentDay)!
        
        for _ in 1..<30 { // Cap at 30 days to avoid excessive processing
            if exercisesByDay[calendar.startOfDay(for: currentDay)] != nil {
                currentStreak += 1
                currentDay = calendar.date(byAdding: .day, value: -1, to: currentDay)!
            } else {
                break
            }
        }
        
        daysStreak = currentStreak
    }
    
    func updateProfile(displayName: String) {
        // Create an update profile request
        let profileData = UpdateProfileRequest(
            displayName: displayName,
            profilePictureUrl: nil,
            location: nil
        )
        
        // Update the profile data
        APIClient.shared.updateProfile(profileData: profileData)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.showError("Update Failed", message: error.localizedDescription)
                    }
                },
                receiveValue: { [weak self] user in
                    guard let self = self else { return }
                    
                    // Update local display name
                    self.displayName = user.displayName ?? user.username
                    
                    // Show success message
                    self.showAlert = true
                    self.alertTitle = "Profile Updated"
                    self.alertMessage = "Your profile information has been updated successfully."
                }
            )
            .store(in: &cancellables)
    }
    
    func signOut(authManager: AuthManager) {
        authManager.signOut()
    }
    
    func syncData() {
        // Show syncing status
        showAlert = true
        alertTitle = "Syncing Data"
        alertMessage = "Synchronizing your data with the server..."
        
        // Generate a device ID if we don't have one
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        
        APIClient.shared.syncUserData(deviceId: deviceId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.showError("Sync Failed", message: error.localizedDescription)
                    }
                },
                receiveValue: { [weak self] response in
                    guard let self = self else { return }
                    
                    // Update last sync time in UserDefaults
                    UserDefaults.standard.set(response.timestamp, forKey: "last_sync_timestamp")
                    
                    // Process received data
                    if let profile = response.data?.profile {
                        self.updateProfileFromSync(profile)
                    }
                    
                    if let exercises = response.data?.userExercises {
                        self.updateLocalExercises(exercises)
                    }
                    
                    // Show success message
                    self.showAlert = true
                    self.alertTitle = "Data Synchronized"
                    self.alertMessage = "Your exercise data has been synchronized with the server."
                    
                    // Refresh exercise stats
                    self.loadExerciseStats()
                }
            )
            .store(in: &cancellables)
    }
    
    private func updateProfileFromSync(_ profile: User) {
        // Update profile data from sync response
        username = profile.username
        displayName = profile.displayName ?? profile.username
        
        // Update location if available
        locationEnabled = profile.latitude != nil && profile.longitude != nil
    }
    
    private func updateLocalExercises(_ exercises: [UserExercise]) {
        // In a real implementation, this would save the exercises to local storage
        // For now, we just process them for stats
        processExerciseStats(exercises)
    }
    
    func showError(_ title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
    
    // MARK: - Permission Handling
    
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
        
        // When permission is granted, update user location
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse ||
           CLLocationManager.authorizationStatus() == .authorizedAlways {
            
            locationManager.requestLocation()
        }
    }
    
    func checkBluetoothPermission() {
        // In a real app, you would check and request Bluetooth permissions
        bluetoothEnabled = true
    }
    
    func requestNotificationPermission() {
        // In a real app, you would request notification permissions
        notificationsEnabled = true
    }
}

// Preview
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ProfileView()
                .environmentObject(AuthManager())
        }
    }
}