import SwiftUI
import CoreLocation // For CLAuthorizationStatus
import SwiftData // Import SwiftData
import CoreBluetooth // For CBManagerState
import PTDesignSystem

struct RunWorkoutView: View {
    // MARK: - Properties
    @StateObject private var viewModel: RunWorkoutViewModel
    @EnvironmentObject var tabBarVisibility: TabBarVisibilityManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var fitnessDeviceManagerViewModel: FitnessDeviceManagerViewModel
    @State private var workoutToNavigate: WorkoutResultSwiftData? = nil
    @State private var showingDeviceManagerSheet = false
    
    // MARK: - Constants
    private struct Constants {
        static let globalPadding: CGFloat = AppTheme.GeneratedSpacing.contentPadding
        static let cardGap: CGFloat = AppTheme.GeneratedSpacing.cardGap
        static let panelCornerRadius: CGFloat = AppTheme.GeneratedRadius.card
    }
    
    // Helper to check if running in simulator
    private var isRunningInSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
    
    // MARK: - Initialization
    init() {
        _viewModel = StateObject(wrappedValue: RunWorkoutViewModel())
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Ambient Background Gradient (matching Dashboard)
            RadialGradient(
                gradient: Gradient(colors: [
                    AppTheme.GeneratedColors.background.opacity(0.9),
                    AppTheme.GeneratedColors.background
                ]),
                center: .center,
                startRadius: 50,
                endRadius: UIScreen.main.bounds.height * 0.6
            )
            .ignoresSafeArea()
            
            // Main Content
            ScrollView {
                VStack(spacing: 20) {
                    // Device Connection Status Header
                    deviceStatusHeader()
                    
                    // Controls - standalone (now positioned between Device Status and Run Metrics)
                    startButtonSection()
                    
                    // Metrics Display
                    runMetricsHeader()
                    
                    // Add some space at the bottom
                    Spacer(minLength: 30)
                }
                .padding(.bottom, 20)
            }
            
            // Location Permission Request View
            if viewModel.runState == .requestingPermission {
                LocationPermissionRequestView(
                    onRequestPermission: {
                        viewModel.requestLocationPermission()
                    },
                    onCancel: {
                        dismiss()
                    }
                )
                .zIndex(2) // Ensure it's on top
            }
            
            // Permission Denied/Error Overlay
            if isInErrorOrPermissionDeniedState {
                permissionOrErrorOverlay()
                    .zIndex(1)
            }
        }
        .navigationTitle("Run Tracking")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .hideTabBar(!tabBarVisibility.isTabBarVisible)
        .navigationBarItems(leading: 
            Button("End") {
                handleEndWorkout()
            }
            .foregroundColor(AppTheme.GeneratedColors.error)
        )
        .onAppear {
            // Hide tab bar during run workout
            tabBarVisibility.hideTabBar()
            
            setupView()
            
            // Add location permission check with DispatchQueue.main.async
            DispatchQueue.main.async {
                if CLLocationManager.authorizationStatus() == .notDetermined {
                    viewModel.runState = .requestingPermission
                }
            }
        }
        .onChange(of: viewModel.completedWorkoutForDetail) { newWorkoutDetail in
            if let workout = newWorkoutDetail {
                DispatchQueue.main.async {
                    showingDeviceManagerSheet = false  // ensure modal is closed
                    self.workoutToNavigate = workout
                }
            }
        }
        .onChange(of: fitnessDeviceManagerViewModel.connectedBluetoothDevice) { newDevice in
            if newDevice != nil {
                DispatchQueue.main.async {
                    showingDeviceManagerSheet = false   // device paired, dismiss modal
                }
            }
        }
        .onChange(of: fitnessDeviceManagerViewModel.isHealthKitAuthorized) { authorized in
            if authorized {
                DispatchQueue.main.async {
                    showingDeviceManagerSheet = false   // watch authorized, dismiss modal
                }
            }
        }
        .background(
            NavigationLink(
                destination: workoutToNavigate.map { WorkoutDetailView(workoutResult: $0) }, 
                isActive: Binding<Bool>(
                    get: { workoutToNavigate != nil }, 
                    set: { isActive in if !isActive { workoutToNavigate = nil } }
                ),
                label: { EmptyView() }
            )
            .opacity(0) // Keep it hidden
        )
        // Replace the sheet with a full-screen cover for the device manager
        .fullScreenCover(isPresented: $showingDeviceManagerSheet) {
            NavigationView {
                FitnessDeviceManagerView()
                    .environmentObject(fitnessDeviceManagerViewModel)
                    .navigationBarBackButtonHidden(true)
                    .navigationBarItems(leading: 
                        Button("Cancel") { 
                            showingDeviceManagerSheet = false 
                        }
                    )
            }
        }
    }
    
    // MARK: - Setup
    private func setupView() {
        // Set the model context
        viewModel.modelContext = modelContext
    }
    
    private func handleEndWorkout() {
        // Always dismiss the pairing modal (if open) before exiting
        showingDeviceManagerSheet = false
        
        // Show tab bar when ending workout
        tabBarVisibility.showTabBar()
        
        if viewModel.runState == .finished {
            if let completedWorkout = viewModel.completedWorkoutForDetail {
                self.workoutToNavigate = completedWorkout
            } else {
                dismiss()
            }
        } else if viewModel.runState == .running || viewModel.runState == .paused {
            viewModel.stopRun()
        } else {
            dismiss()
        }
    }
    
    // MARK: - UI Components
    @ViewBuilder
    private func deviceStatusHeader() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with dark background and gold text (like dashboard)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("DEVICE STATUS")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(AppTheme.GeneratedColors.brassGold)
                    
                    Spacer()
                    
                    // GPS Source Indicator
                    HStack(spacing: 3) {
                        Image(systemName: viewModel.locationSource == .watch ? "applewatch" : "iphone")
                            .foregroundColor(.white)
                        Text("GPS")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppTheme.GeneratedColors.brassGold)
                    .cornerRadius(4)
                }
                
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(AppTheme.GeneratedColors.brassGold.opacity(0.3))
                    .padding(.vertical, 4)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(AppTheme.GeneratedColors.deepOps)
            .clipShape(RoundedCorner(radius: 8, corners: [.topLeft, .topRight]))
            
            // Device status content with cream background
            VStack(spacing: 12) {
                // Device connection status
                HStack {
                    // Status icon with circular background
                    ZStack {
                        Circle()
                            .fill(getStatusColor().opacity(0.15))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: getConnectionIcon())
                            .foregroundColor(getStatusColor())
                            .font(.system(size: 16))
                    }
                    
                    // Connection details
                    VStack(alignment: .leading, spacing: 2) {
                        // Connection status text
                        Text(getConnectionStatusText())
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(AppTheme.GeneratedColors.deepOps)
                        
                        if case .connected(let peripheral) = viewModel.deviceConnectionState {
                            Text("Connected to \(peripheral.name ?? "Device")")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        } else if case .connecting = viewModel.deviceConnectionState {
                            HStack {
                                Text("Establishing connection")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                ProgressView().scaleEffect(0.7)
                            }
                        } else {
                            Text("No heart rate data available")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Connect button if disconnected
                    if case .disconnected = viewModel.deviceConnectionState {
                        Button {
                            showingDeviceManagerSheet = true
                        } label: {
                            Text("Connect")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(AppTheme.GeneratedColors.brassGold)
                                .cornerRadius(6)
                        }
                    }
                }
                
                // Heart Rate Indicator Row if connected
                if case .connected = viewModel.deviceConnectionState, viewModel.currentHeartRate != nil {
                    Divider()
                        .background(Color.gray.opacity(0.2))
                    
                    HStack {
                        // Heart rate with pulsing animation
                        HStack(spacing: 8) {
                            Image(systemName: "heart.fill")
                                .foregroundColor(AppTheme.GeneratedColors.error)
                                .opacity(viewModel.currentHeartRate != nil ? 1.0 : 0.5)
                                .scaleEffect(viewModel.currentHeartRate != nil ? 1.0 : 0.9)
                                .font(.system(size: 16))
                                .animation(
                                    viewModel.currentHeartRate != nil ? 
                                        Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true) : 
                                        .default, 
                                    value: viewModel.currentHeartRate != nil
                                )
                            
                            Text("\(viewModel.currentHeartRate!) BPM")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppTheme.GeneratedColors.deepOps)
                        }
                        
                        Spacer()
                        
                        // Cadence display if available
                        if let cadence = viewModel.currentCadence {
                            HStack(spacing: 8) {
                                Image(systemName: "figure.walk")
                                    .foregroundColor(AppTheme.GeneratedColors.brassGold)
                                    .font(.system(size: 16))
                                
                                Text("\(cadence) SPM")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(AppTheme.GeneratedColors.deepOps)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(Color(red: 0.93, green: 0.91, blue: 0.86)) // cream-dark from web
            .clipShape(RoundedCorner(radius: 8, corners: [.bottomLeft, .bottomRight]))
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    // Helper methods for device status header
    private func getConnectionStatusText() -> String {
        switch viewModel.deviceConnectionState {
        case .disconnected:
            return "No Device Connected"
        case .connecting:
            return "Connecting..."
        case .connected:
            return "Connected"
        case .disconnecting:
            return "Disconnecting..."
        case .failed:
            return "Connection Failed"
        }
    }
    
    private func getConnectionIcon() -> String {
        switch viewModel.deviceConnectionState {
        case .disconnected:
            return "antenna.radiowaves.left.and.right.slash"
        case .connecting:
            return "antenna.radiowaves.left.and.right"
        case .connected:
            return "antenna.radiowaves.left.and.right"
        case .disconnecting:
            return "antenna.radiowaves.left.and.right.slash"
        case .failed:
            return "xmark.circle"
        }
    }
    
    private func getStatusColor() -> Color {
        switch viewModel.deviceConnectionState {
        case .disconnected:
            return AppTheme.GeneratedColors.textSecondary
        case .connecting:
            return AppTheme.GeneratedColors.warning
        case .connected:
            return AppTheme.GeneratedColors.success
        case .disconnecting:
            return AppTheme.GeneratedColors.textSecondary
        case .failed:
            return AppTheme.GeneratedColors.error
        }
    }
    
    @ViewBuilder
    private func runMetricsHeader() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with dark background and gold text (like dashboard)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("RUN METRICS")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(AppTheme.GeneratedColors.brassGold)
                    
                    Spacer()
                    
                    // Two Mile Auto-Stop Indicator
                    Text("Auto-Stop at 2 miles")
                        .font(.system(size: 12, weight: .medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppTheme.GeneratedColors.warning.opacity(0.3))
                        .foregroundColor(AppTheme.GeneratedColors.brassGold)
                        .cornerRadius(4)
                }
                .padding(.bottom, 4)
                
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(AppTheme.GeneratedColors.brassGold.opacity(0.3))
                    .padding(.bottom, 4)
                
                Text("CURRENT PROGRESS TRACKING")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.GeneratedColors.brassGold)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.GeneratedColors.deepOps)
            .clipShape(RoundedCorner(radius: 8, corners: [.topLeft, .topRight]))
            
            // Metrics content with cream background
            VStack(spacing: 20) {
                // First row: Distance and Time
                HStack(spacing: 16) {
                    // Distance
                    VStack {
                        ZStack {
                            Circle()
                                .fill(AppTheme.GeneratedColors.oliveMist.opacity(0.3))
                                .frame(width: 50, height: 50)
                            
                            Image(systemName: "figure.run")
                                .font(.system(size: 20))
                                .foregroundColor(AppTheme.GeneratedColors.deepOps)
                        }
                        
                        Text(viewModel.distanceFormatted)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(AppTheme.GeneratedColors.deepOps)
                        
                        Text("DISTANCE")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppTheme.GeneratedColors.deepOps)
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Time
                    VStack {
                        ZStack {
                            Circle()
                                .fill(AppTheme.GeneratedColors.oliveMist.opacity(0.3))
                                .frame(width: 50, height: 50)
                            
                            Image(systemName: "clock")
                                .font(.system(size: 20))
                                .foregroundColor(AppTheme.GeneratedColors.deepOps)
                        }
                        
                        Text(viewModel.elapsedTimeFormatted)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(AppTheme.GeneratedColors.deepOps)
                        
                        Text("TIME")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppTheme.GeneratedColors.deepOps)
                    }
                    .frame(maxWidth: .infinity)
                }
                
                // Second row: Avg Pace and Current Pace
                HStack(spacing: 16) {
                    // Avg Pace
                    VStack {
                        ZStack {
                            Circle()
                                .fill(AppTheme.GeneratedColors.brassGold.opacity(0.15))
                                .frame(width: 50, height: 50)
                            
                            Image(systemName: "speedometer")
                                .font(.system(size: 20))
                                .foregroundColor(AppTheme.GeneratedColors.deepOps)
                        }
                        
                        Text(viewModel.averagePaceFormatted)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(AppTheme.GeneratedColors.deepOps)
                        
                        Text("AVG PACE")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppTheme.GeneratedColors.deepOps)
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Current Pace
                    VStack {
                        ZStack {
                            Circle()
                                .fill(AppTheme.GeneratedColors.brassGold.opacity(0.15))
                                .frame(width: 50, height: 50)
                            
                            Image(systemName: "gauge.with.dots.needle.33percent")
                                .font(.system(size: 20))
                                .foregroundColor(AppTheme.GeneratedColors.deepOps)
                        }
                        
                        Text(viewModel.currentPaceFormatted)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(AppTheme.GeneratedColors.deepOps)
                        
                        Text("CUR PACE")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppTheme.GeneratedColors.deepOps)
                    }
                    .frame(maxWidth: .infinity)
                }
                
                // Third row: Heart Rate and Cadence
                HStack(spacing: 16) {
                    // Heart Rate
                    VStack {
                        ZStack {
                            Circle()
                                .fill(AppTheme.GeneratedColors.error.opacity(0.15))
                                .frame(width: 50, height: 50)
                            
                            Image(systemName: "heart.fill")
                                .font(.system(size: 20))
                                .foregroundColor(AppTheme.GeneratedColors.error)
                        }
                        
                        Text(viewModel.currentHeartRate != nil ? "\(viewModel.currentHeartRate!) BPM" : "-- BPM")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(AppTheme.GeneratedColors.deepOps)
                        
                        Text("HEART RATE")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppTheme.GeneratedColors.deepOps)
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Cadence
                    VStack {
                        ZStack {
                            Circle()
                                .fill(AppTheme.GeneratedColors.oliveMist.opacity(0.3))
                                .frame(width: 50, height: 50)
                            
                            Image(systemName: "metronome")
                                .font(.system(size: 20))
                                .foregroundColor(AppTheme.GeneratedColors.deepOps)
                        }
                        
                        Text(viewModel.currentCadence != nil ? "\(viewModel.currentCadence!) SPM" : "-- SPM")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(AppTheme.GeneratedColors.deepOps)
                        
                        Text("CADENCE")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppTheme.GeneratedColors.deepOps)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(Color(red: 0.93, green: 0.91, blue: 0.86)) // cream-dark from web
            .clipShape(RoundedCorner(radius: 8, corners: [.bottomLeft, .bottomRight]))
        }
        .padding(.horizontal, 16)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    // Helper for single metric display
    struct MetricDisplay: View {
        let label: String
        let value: String
        var icon: String? = nil
        var iconColor: Color? = nil
        
        var body: some View {
            VStack {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(iconColor ?? AppTheme.GeneratedColors.textPrimary)
                        .font(.system(size: 16))
                        .padding(.bottom, AppTheme.GeneratedSpacing.extraSmall / 2)
                }
                PTLabel(label, style: .caption)
                    .foregroundColor(AppTheme.GeneratedColors.textTertiary)
                    .padding(.bottom, 1)
                PTLabel(value, style: .heading)
                    .foregroundColor(AppTheme.GeneratedColors.cream)
            }
            .frame(maxWidth: .infinity) // Distribute horizontally
        }
    }
    
    @ViewBuilder
    private func startButtonSection() -> some View {
        HStack {
            Spacer()
            switch viewModel.runState {
            case .ready, .idle:
                Button { viewModel.startRun() }
                label: { 
                    VStack(spacing: 8) {
                        Text("START RUN")
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(AppTheme.GeneratedColors.deepOps)
                        
                        ZStack {
                            Circle()
                                .fill(AppTheme.GeneratedColors.brassGold)
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "play.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 30, height: 30)
                                .foregroundColor(AppTheme.GeneratedColors.deepOps)
                                .padding(.leading, 3) // Adjust visual centering due to triangle shape
                        }
                    }
                }
            case .running:
                Button { viewModel.pauseRun() }
                label: { 
                    VStack(spacing: 8) {
                        Text("PAUSE RUN")
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(AppTheme.GeneratedColors.deepOps)
                        
                        ZStack {
                            Circle()
                                .fill(AppTheme.GeneratedColors.warning)
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "pause.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 30, height: 30)
                                .foregroundColor(AppTheme.GeneratedColors.deepOps)
                        }
                    }
                }
            case .paused:
                HStack(spacing: 40) {
                    Button { viewModel.resumeRun() }
                    label: { 
                        VStack(spacing: 8) {
                            Text("RESUME")
                                .font(.system(size: 16, weight: .bold, design: .monospaced))
                                .foregroundColor(AppTheme.GeneratedColors.deepOps)
                            
                            ZStack {
                                Circle()
                                    .fill(AppTheme.GeneratedColors.brassGold)
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: "play.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(AppTheme.GeneratedColors.deepOps)
                            }
                        }
                    }

                    Button { viewModel.stopRun() }
                    label: { 
                        VStack(spacing: 8) {
                            Text("FINISH")
                                .font(.system(size: 16, weight: .bold, design: .monospaced))
                                .foregroundColor(AppTheme.GeneratedColors.deepOps)
                            
                            ZStack {
                                Circle()
                                    .fill(AppTheme.GeneratedColors.error)
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: "stop.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
            case .finished, .error:
                EmptyView() // Handled by navigation
            default: // requestingPermission, permissionDenied
                EmptyView()
            }
            Spacer()
        }
        .padding(.vertical, 16)
    }
    
    // Helper view for permission/error overlays
    @ViewBuilder
    private func permissionOrErrorOverlay() -> some View {
        VStack(spacing: AppTheme.GeneratedSpacing.medium) {
            // Use the isInPermissionDeniedState property for icon and text selection
            let isPermissionDenied = viewModel.runState == .permissionDenied
            
            Image(systemName: isPermissionDenied ? "location.slash.fill" : "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(isPermissionDenied ? 
                                 AppTheme.GeneratedColors.textPrimaryOnDark : 
                                 AppTheme.GeneratedColors.warning)
            
            PTLabel(isPermissionDenied ? 
                   "Location Access Denied" : "Error", 
                   style: .heading)
            
            PTLabel(viewModel.errorMessage ?? 
                   "This feature requires location access to track runs. Please enable location access in Settings.", 
                   style: .body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            let primaryButtonStyle: PTButton.ExtendedStyle = .primary
            if isPermissionDenied {
                PTButton("Open Settings", style: primaryButtonStyle) {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            } else {
                PTButton("Dismiss", style: primaryButtonStyle) {
                    viewModel.errorMessage = nil
                    dismiss()
                }
            }
        }
        .padding(AppTheme.GeneratedSpacing.large)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Color(uiColor: UIColor.black.withAlphaComponent(0.85))
                .edgesIgnoringSafeArea(.all)
        )
    }
    
    // Add a computed property to check if in error state
    private var isInErrorOrPermissionDeniedState: Bool {
        if case .permissionDenied = viewModel.runState { return true }
        if case .error = viewModel.runState { return true }
        return false
    }
}

// MapView Placeholder (Replace with actual MapKit view if desired)
struct MapViewPlaceholder: View {
    var body: some View {
        ZStack {
            Color.gray.opacity(0.2)
            Text("Map Area (Optional)")
                .foregroundColor(AppTheme.GeneratedColors.textSecondary)
        }
    }
}

#Preview {
    NavigationView {
        RunWorkoutView()
            .environmentObject(FitnessDeviceManagerViewModel())
    }
    .modelContainer(for: WorkoutResultSwiftData.self, inMemory: true)
} 