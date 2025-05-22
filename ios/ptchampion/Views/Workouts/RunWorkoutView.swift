import SwiftUI
import CoreLocation // For CLAuthorizationStatus
import SwiftData // Import SwiftData
import CoreBluetooth // For CBManagerState
import PTDesignSystem

// Run-specific text style extensions
extension Text {
    func runLabelStyle(size: CGFloat = 14, color: Color = AppTheme.GeneratedColors.textSecondary) -> some View { 
        self.font(.system(size: size)).foregroundColor(color) 
    }
    
    func statsNumberStyle(size: CGFloat = 32, color: Color = AppTheme.GeneratedColors.textPrimary) -> some View { 
        self.font(.system(size: size, weight: .bold)).foregroundColor(color) 
    }
}

struct RunWorkoutView: View {
    // MARK: - Properties
    @StateObject private var viewModel: RunWorkoutViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var fitnessDeviceManagerViewModel: FitnessDeviceManagerViewModel
    @State private var workoutToNavigate: WorkoutResultSwiftData? = nil
    @State private var showingDeviceManagerSheet = false
    @State private var showDeviceConnectionBanner = false
    
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
            // Main Content
            VStack(spacing: 0) {
                // Device Connection Banner (visible when needed)
                if showDeviceConnectionBanner {
                    deviceConnectionBanner()
                }
                
                // Device Connection Status Header
                deviceStatusHeader()
                
                // Top Metrics Display
                runMetricsHeader()
                
                Spacer() // Pushes controls to bottom
                
                // Bottom Controls
                runControls()
            }
            .background(AppTheme.GeneratedColors.cream.ignoresSafeArea())
            
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
        .navigationBarItems(leading: 
            Button("End") {
                handleEndWorkout()
            }
            .foregroundColor(AppTheme.GeneratedColors.error)
        )
        .onAppear {
            setupView()
            
            // Add location permission check with DispatchQueue.main.async
            DispatchQueue.main.async {
                if CLLocationManager.authorizationStatus() == .notDetermined {
                    viewModel.runState = .requestingPermission
                }
            }
            
            // Avoid automatic device detection in simulator
            if isRunningInSimulator {
                // Show banner instead of auto sheet presentation - wrap in async
                DispatchQueue.main.async { 
                    showDeviceConnectionBanner = true 
                }
            } else {
                // Only do this check on real device after a slight delay
                if #available(iOS 15, *) {
                    // Defer to .task for iOS 15+ (no immediate modal presentation here)
                } else {
                    // iOS 14 fallback: schedule modal presentation after view appears
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        let noDeviceConnected = (fitnessDeviceManagerViewModel.connectedBluetoothDevice == nil
                                               && !fitnessDeviceManagerViewModel.isHealthKitAuthorized)
                        if noDeviceConnected {
                            DispatchQueue.main.async {
                                showDeviceConnectionBanner = true
                            }
                        }
                    }
                }
            }
        }
        .task {
            if #available(iOS 15, *) {
                // On iOS 15+, run after the view appears
                if !isRunningInSimulator {
                    // Add a small delay to ensure the view is fully loaded
                    try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
                    let noDeviceConnected = (fitnessDeviceManagerViewModel.connectedBluetoothDevice == nil
                                         && !fitnessDeviceManagerViewModel.isHealthKitAuthorized)
                    if noDeviceConnected {
                        // Ensure UI updates are on the main thread
                        await MainActor.run {
                            showDeviceConnectionBanner = true   // Show banner instead of immediate sheet
                        }
                    }
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
                    showDeviceConnectionBanner = false  // hide banner
                }
            }
        }
        .onChange(of: fitnessDeviceManagerViewModel.isHealthKitAuthorized) { authorized in
            if authorized {
                DispatchQueue.main.async {
                    showingDeviceManagerSheet = false   // watch authorized, dismiss modal
                    showDeviceConnectionBanner = false  // hide banner
                }
            }
        }
        .onChange(of: showingDeviceManagerSheet) { isPresented in
            print("DEBUG: showingDeviceManagerSheet changed to \(isPresented)")
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
        .fullScreenCover(isPresented: $showingDeviceManagerSheet, onDismiss: {
            print("DEBUG: [RunWorkoutView] FullScreenCover dismissing")
            print("DEBUG: [RunWorkoutView] FullScreenCover was dismissed")
            print("DEBUG: [RunWorkoutView] showingDeviceManagerSheet is now \(showingDeviceManagerSheet)")
            print("DEBUG: [RunWorkoutView] showDeviceConnectionBanner is now \(showDeviceConnectionBanner)")
            
            // Add extra debug info about the device connection state
            let hasBTDevice = fitnessDeviceManagerViewModel.connectedBluetoothDevice != nil
            let hasHealthKit = fitnessDeviceManagerViewModel.isHealthKitAuthorized
            print("DEBUG: [RunWorkoutView] After dismiss - Connected device: \(hasBTDevice), HealthKit authorized: \(hasHealthKit)")
        }) {
            NavigationView {
                FitnessDeviceManagerView()
                    .environmentObject(fitnessDeviceManagerViewModel)
                    .navigationBarBackButtonHidden(true)
                    .navigationBarItems(leading: 
                        Button("Cancel") { 
                            print("DEBUG: [RunWorkoutView] Cancel button tapped in FitnessDeviceManagerView")
                            print("DEBUG: [RunWorkoutView] About to set showingDeviceManagerSheet = false")
                            showingDeviceManagerSheet = false 
                            print("DEBUG: [RunWorkoutView] showingDeviceManagerSheet set to false")
                        }
                    )
                    .onAppear {
                        print("DEBUG: [RunWorkoutView] FitnessDeviceManagerView appeared in fullScreenCover")
                        print("DEBUG: [RunWorkoutView] Bluetooth state: \(fitnessDeviceManagerViewModel.bluetoothState.stateDescription)")
                        print("DEBUG: [RunWorkoutView] HealthKit authorized: \(fitnessDeviceManagerViewModel.isHealthKitAuthorized)")
                    }
                    .onDisappear {
                        print("DEBUG: [RunWorkoutView] FitnessDeviceManagerView disappeared from fullScreenCover")
                        print("DEBUG: [RunWorkoutView] Current value of dismissedBluetoothWarning: \(fitnessDeviceManagerViewModel.dismissedBluetoothWarning)")
                    }
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
        VStack(spacing: 2) {
            HStack {
                // Bluetooth Device Status
                HStack(spacing: 4) {
                    Image(systemName: viewModel.bluetoothState == .poweredOn ? "bolt.fill" : "bolt.slash.fill")
                        .foregroundColor(viewModel.bluetoothState == .poweredOn ? .blue : AppTheme.GeneratedColors.textSecondary)
                    
                    // Connection Status Text
                    switch viewModel.deviceConnectionState {
                    case .disconnected:
                        Text("No Device Connected")
                            .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                    case .connecting:
                        HStack {
                            Text("Connecting...")
                            ProgressView().scaleEffect(0.7)
                        }
                        .foregroundColor(AppTheme.GeneratedColors.warning)
                    case .connected(let peripheral):
                        Text("\(peripheral.name ?? "Device")")
                            .foregroundColor(AppTheme.GeneratedColors.success)
                            .fontWeight(.medium)
                    case .disconnecting:
                        Text("Disconnecting...")
                            .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                    case .failed:
                        Text("Connection Failed")
                            .foregroundColor(AppTheme.GeneratedColors.error)
                    }
                }
                
                Spacer()
                
                // GPS Source Indicator with improved visual
                HStack(spacing: 3) {
                    Image(systemName: viewModel.locationSource == .watch ? "applewatch" : "iphone")
                        .foregroundColor(viewModel.locationSource == .watch ? .blue : AppTheme.GeneratedColors.textPrimary)
                    Text("GPS")
                        .foregroundColor(viewModel.locationSource == .watch ? .blue : AppTheme.GeneratedColors.textPrimary)
                }
                .padding(4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.systemBackground).opacity(0.3))
                )
            }
            .font(.caption)
            
            // Heart Rate Indicator Row with improved visualization
            if case .connected = viewModel.deviceConnectionState {
                HStack(spacing: 8) {
                    // Heart rate display with pulsing animation
                    HStack(spacing: 3) {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                            .opacity(viewModel.currentHeartRate != nil ? 1.0 : 0.5)
                            .scaleEffect(viewModel.currentHeartRate != nil ? 1.0 : 0.9)
                            .animation(
                                viewModel.currentHeartRate != nil ? 
                                    Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true) : 
                                    .default, 
                                value: viewModel.currentHeartRate != nil
                            )
                        
                        Text(viewModel.currentHeartRate != nil ? "\(viewModel.currentHeartRate!) BPM" : "-- BPM")
                            .foregroundColor(viewModel.currentHeartRate != nil ? .primary : AppTheme.GeneratedColors.textSecondary)
                            .fontWeight(viewModel.currentHeartRate != nil ? .semibold : .regular)
                    }
                    
                    // Add source indicator for heart rate
                    if viewModel.currentHeartRate != nil {
                        Text("via \(viewModel.connectedDeviceName ?? "Device")")
                            .font(.caption2)
                            .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                    }
                    
                    Spacer()
                    
                    // Add cadence display if available
                    if let cadence = viewModel.currentCadence {
                        HStack(spacing: 3) {
                            Image(systemName: "figure.walk")
                                .foregroundColor(.blue)
                            Text("\(cadence) SPM")
                                .fontWeight(.semibold)
                        }
                    }
                }
                .font(.caption)
                .padding(.leading, 8)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 5)
        .background(.thinMaterial)
    }
    
    @ViewBuilder
    private func runMetricsHeader() -> some View {
        VStack(spacing: 0) {
            // Two Mile Auto-Stop Indicator
            HStack {
                Spacer()
                Text("Auto-Stop at 2 miles")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppTheme.GeneratedColors.warning.opacity(0.3))
                    .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                    .cornerRadius(12)
                Spacer()
            }
            .padding(.top, 4)
            
            Grid(alignment: .center, horizontalSpacing: 10, verticalSpacing: 15) {
                GridRow {
                    MetricDisplay(label: "DISTANCE", value: viewModel.distanceFormatted)
                    MetricDisplay(label: "TIME", value: viewModel.elapsedTimeFormatted)
                }
                GridRow {
                    MetricDisplay(label: "AVG PACE", value: viewModel.averagePaceFormatted)
                    MetricDisplay(label: "CUR PACE", value: viewModel.currentPaceFormatted)
                }
                
                // Add Heart Rate and Cadence in a row
                GridRow {
                    // Heart Rate Display
                    MetricDisplay(
                        label: "HEART RATE",
                        value: viewModel.currentHeartRate != nil ? "\(viewModel.currentHeartRate!) BPM" : "-- BPM",
                        icon: "heart.fill",
                        iconColor: .red
                    )
                    
                    // Cadence Display
                    MetricDisplay(
                        label: "CADENCE",
                        value: viewModel.currentCadence != nil ? "\(viewModel.currentCadence!) SPM" : "-- SPM",
                        icon: "metronome",
                        iconColor: .blue
                    )
                }
            }
            .padding()
        }
        .background(AppTheme.GeneratedColors.deepOps)
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
                        .padding(.bottom, 2)
                }
                Text(label)
                    .runLabelStyle(size: 12, color: AppTheme.GeneratedColors.textTertiary)
                    .padding(.bottom, 1)
                Text(value)
                    .statsNumberStyle(size: 24, color: AppTheme.GeneratedColors.cream)
            }
            .frame(maxWidth: .infinity) // Distribute horizontally
        }
    }
    
    @ViewBuilder
    private func runControls() -> some View {
        HStack {
            Spacer()
            switch viewModel.runState {
            case .ready, .idle:
                Button { viewModel.startRun() }
                label: { controlButtonLabel(systemName: "play.circle.fill", color: AppTheme.GeneratedColors.success) }
            case .running:
                Button { viewModel.pauseRun() }
                label: { controlButtonLabel(systemName: "pause.circle.fill", color: AppTheme.GeneratedColors.warning) }
            case .paused:
                HStack(spacing: 40) {
                    Button { viewModel.resumeRun() }
                    label: { controlButtonLabel(systemName: "play.circle.fill", color: AppTheme.GeneratedColors.success) }

                    Button { viewModel.stopRun() }
                    label: { controlButtonLabel(systemName: "stop.circle.fill", color: AppTheme.GeneratedColors.error) }
                }
            case .finished, .error:
                EmptyView() // Handled by navigation
            default: // requestingPermission, permissionDenied
                EmptyView()
            }
            Spacer()
        }
        .padding()
        .frame(height: 80) // Consistent height for control area
        .background(AppTheme.GeneratedColors.backgroundOverlay.opacity(0.3))
    }
    
    // Helper for styling control buttons
    private func controlButtonLabel(systemName: String, color: Color) -> some View {
        Image(systemName: systemName)
            .resizable()
            .scaledToFit()
            .frame(width: 50, height: 50)
            .foregroundColor(color)
            .padding()
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
    
    // MARK: - Device Connection Banner
    private func deviceConnectionBanner() -> some View {
        Button {
            print("DEBUG: [RunWorkoutView] Banner button tapped - transition sequence starting")
            // Better two-step transition - first hide banner, then show sheet
            print("DEBUG: [RunWorkoutView] Step 1: Hiding banner (showDeviceConnectionBanner = false)")
            DispatchQueue.main.async {
                showDeviceConnectionBanner = false
                print("DEBUG: [RunWorkoutView] Banner hidden in first async")
                
                DispatchQueue.main.async { // next run loop
                    print("DEBUG: [RunWorkoutView] Step 2: About to show device manager sheet in second async")
                    showingDeviceManagerSheet = true
                    print("DEBUG: [RunWorkoutView] showingDeviceManagerSheet set to true")
                }
            }
        } label: {
            HStack {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .foregroundColor(.white)
                    .font(.system(size: 16))
                
                Text("Connect a fitness device for heart rate tracking")
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.8))
                    .font(.system(size: 12))
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(AppTheme.GeneratedColors.brassGold)
            .cornerRadius(8)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .onAppear {
            print("DEBUG: [RunWorkoutView] Device connection banner appeared")
        }
        .onDisappear {
            print("DEBUG: [RunWorkoutView] Device connection banner disappeared")
        }
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

// Remove duplicate protocol definitions - use the shared protocols from the Services folder instead

// No more duplicate protocol definitions here 