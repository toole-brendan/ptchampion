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
    // Define constants directly within the view
    private struct Constants {
        static let globalPadding: CGFloat = AppTheme.GeneratedSpacing.contentPadding
        static let cardGap: CGFloat = AppTheme.GeneratedSpacing.cardGap
        static let panelCornerRadius: CGFloat = AppTheme.GeneratedRadius.card
    }
    
    @StateObject private var viewModel: RunWorkoutViewModel // Use @StateObject
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext // Access ModelContext
    @State private var workoutToNavigate: WorkoutResultSwiftData? = nil // <-- ADDED

    // Keep the initializer simple for previews, context injected onAppear
    init() {
        _viewModel = StateObject(wrappedValue: RunWorkoutViewModel(modelContext: nil)) // Use StateObject
    }

    var body: some View {
        VStack(spacing: 0) {
            // Device Connection Status Header
            deviceStatusHeader()

            // Top Metrics Display
            runMetricsHeader()

            // Map View Placeholder (Optional)
            // ZStack { // Use ZStack to overlay map if needed
            //     MapViewPlaceholder()
            //     // Overlay current pace/time on map?
            // }
            // .frame(height: 200) // Example fixed height

            Spacer() // Pushes controls to bottom

            // Permission/Error Overlay (Similar to WorkoutSessionView)
            if viewModel.runState == .permissionDenied || viewModel.runState == .error("") { // Check error state properly
                 permissionOrErrorOverlay()
                     .padding(.bottom, 80) // Adjust padding to avoid controls
                     .transition(.opacity.animation(.easeInOut))
            }

            Spacer()

            // Bottom Controls
            runControls()
        }
        .background(AppTheme.GeneratedColors.cream.ignoresSafeArea()) // Use AppTheme.GeneratedColors.cream
        .navigationTitle("Run Tracking")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar { // Custom toolbar for close button
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Close") {
                    if viewModel.runState == .finished {
                        if let completedWorkout = viewModel.completedWorkoutForDetail {
                            self.workoutToNavigate = completedWorkout
                        } else {
                            // If finished but detail not ready, just dismiss or wait?
                            // For now, let's assume stopRun should have been called / will be called
                            // or the navigation will happen via .onChange
                            dismiss() 
                        }
                    } else if viewModel.runState == .running || viewModel.runState == .paused {
                        viewModel.stopRun() // This will trigger saving and eventually navigation
                    } else {
                        dismiss() // For idle, ready, error states etc.
                    }
                }
                .foregroundColor(AppTheme.GeneratedColors.brassGold)
            }
        }
        // Inject the actual modelContext when the view appears and context is available
        .onAppear {
            // Instead of reassigning viewModel (which won't work with @StateObject),
            // set the modelContext property
            viewModel.modelContext = modelContext
        }
        .onChange(of: viewModel.completedWorkoutForDetail) { newWorkoutDetail in // <-- ADDED
            if let workout = newWorkoutDetail {
                self.workoutToNavigate = workout
            }
        }
        // Hidden NavigationLink to trigger navigation when workoutToNavigate is set
        .background( // <-- ADDED
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

    // MARK: - Subviews

    // New Header for Device Status
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
                }.foregroundColor(AppTheme.GeneratedColors.warning)
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
        .background(.thinMaterial) // Subtle background
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
                  MetricDisplay(label: "HEART RATE",
                                value: viewModel.currentHeartRate != nil ? "\(viewModel.currentHeartRate!) BPM" : "-- BPM")
                                .gridCellColumns(2) // Span across two columns
             }
        }
        .padding()
        .background(AppTheme.GeneratedColors.deepOps) // Use AppTheme.GeneratedColors.deepOps
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

    // Helper View for Run Controls (Similar to WorkoutSessionView)
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
             case .finished, .error: // <-- MODIFIED: Removed dismiss button, nav handled by completedWorkoutForDetail
                 EmptyView() // Or a disabled button, or some other indicator
             default: // requestingPermission, permissionDenied
                 EmptyView()
             }
             Spacer()
         }
         .padding()
         .frame(height: 80) // Consistent height for control area
         .background(Color.black.opacity(0.3))
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
         VStack(spacing: 15) {
             Image(systemName: viewModel.runState == .permissionDenied ? "location.slash.fill" : "exclamationmark.triangle.fill")
                 .resizable()
                 .scaledToFit()
                 .frame(width: 50, height: 50)
                 .foregroundColor(viewModel.runState == .permissionDenied ? AppTheme.GeneratedColors.tacticalGray : AppTheme.GeneratedColors.warning)

             Text(viewModel.runState == .permissionDenied ? "Location Access Denied" : "Error")
                 .font(.title2).bold()

             Text(viewModel.errorMessage ?? "An error occurred.")
                 .multilineTextAlignment(.center)
                 .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                 .padding(.horizontal)

             if viewModel.runState == .permissionDenied {
                 Button("Open Settings") {
                     if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
                         UIApplication.shared.open(url)
                     }
                 }
                 .padding(.horizontal, 16)
                 .padding(.vertical, 10)
                 .background(AppTheme.GeneratedColors.primary)
                 .foregroundColor(AppTheme.GeneratedColors.cream)
                 .font(.headline)
                 .cornerRadius(8)
                 .padding(.top)
             } else if case .error = viewModel.runState {
                 Button("Dismiss") {
                     viewModel.errorMessage = nil // Clear error message
                     viewModel.runState = .ready // Go back to ready state?
                 }
                 .padding(.horizontal, 16)
                 .padding(.vertical, 10)
                 .background(AppTheme.GeneratedColors.primary)
                 .foregroundColor(AppTheme.GeneratedColors.cream)
                 .font(.headline)
                 .cornerRadius(8)
                 .padding(.top)
             }
         }
         .padding(30)
         .background(.thinMaterial) // Use material background for overlay
         .cornerRadius(Constants.panelCornerRadius)
         .shadow(radius: 5)
         .padding(Constants.globalPadding) // Padding around the overlay box
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
    // Provide a dummy ModelContainer for the preview
    NavigationView {
        RunWorkoutView()
    }
    .modelContainer(for: WorkoutResultSwiftData.self, inMemory: true) // Use in-memory store for preview
}

// Remove duplicate protocol definitions - use the shared protocols from the Services folder instead

// No more duplicate protocol definitions here 