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
    @State private var workoutToNavigate: WorkoutResultSwiftData? = nil
    
    // MARK: - Constants
    private struct Constants {
        static let globalPadding: CGFloat = AppTheme.GeneratedSpacing.contentPadding
        static let cardGap: CGFloat = AppTheme.GeneratedSpacing.cardGap
        static let panelCornerRadius: CGFloat = AppTheme.GeneratedRadius.card
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
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("End") {
                    handleEndWorkout()
                }
                .foregroundColor(AppTheme.GeneratedColors.error)
            }
        }
        .onAppear {
            setupView()
        }
        .onChange(of: viewModel.completedWorkoutForDetail) { newWorkoutDetail in
            if let workout = newWorkoutDetail {
                self.workoutToNavigate = workout
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
    }
    
    // MARK: - Setup
    private func setupView() {
        // Set the model context
        viewModel.modelContext = modelContext
    }
    
    private func handleEndWorkout() {
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
        HStack {
            // Bluetooth Power Status Icon
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
                Text("Connected: \(peripheral.name ?? "Device")")
                    .foregroundColor(AppTheme.GeneratedColors.success)
            case .disconnecting:
                Text("Disconnecting...")
                    .foregroundColor(AppTheme.GeneratedColors.textSecondary)
            case .failed:
                Text("Connection Failed")
                    .foregroundColor(AppTheme.GeneratedColors.error)
            }
            
            Spacer()
            
            // Location Source Indicator
            HStack(spacing: 3) {
                Image(systemName: viewModel.locationSource == .watch ? "applewatch" : "iphone")
                Text("GPS")
            }
            .foregroundColor(viewModel.locationSource == .watch ? .blue : AppTheme.GeneratedColors.textPrimary)
        }
        .font(.caption)
        .padding(.horizontal)
        .padding(.vertical, 5)
        .background(.thinMaterial)
    }
    
    @ViewBuilder
    private func runMetricsHeader() -> some View {
        Grid(alignment: .center, horizontalSpacing: 10, verticalSpacing: 15) {
            GridRow {
                MetricDisplay(label: "DISTANCE", value: viewModel.distanceFormatted)
                MetricDisplay(label: "TIME", value: viewModel.elapsedTimeFormatted)
            }
            GridRow {
                MetricDisplay(label: "AVG PACE", value: viewModel.averagePaceFormatted)
                MetricDisplay(label: "CUR PACE", value: viewModel.currentPaceFormatted)
            }
            // Add Heart Rate Display
            GridRow {
                MetricDisplay(
                    label: "HEART RATE",
                    value: viewModel.currentHeartRate != nil ? "\(viewModel.currentHeartRate!) BPM" : "-- BPM"
                )
                .gridCellColumns(2) // Span across two columns
            }
        }
        .padding()
        .background(AppTheme.GeneratedColors.deepOps)
    }
    
    // Helper for single metric display
    struct MetricDisplay: View {
        let label: String
        let value: String
        var body: some View {
            VStack {
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
    }
    .modelContainer(for: WorkoutResultSwiftData.self, inMemory: true)
}

// Remove duplicate protocol definitions - use the shared protocols from the Services folder instead

// No more duplicate protocol definitions here 