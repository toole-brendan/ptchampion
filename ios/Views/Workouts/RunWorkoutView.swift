import SwiftUI
import CoreLocation // For CLAuthorizationStatus
import SwiftData // Import SwiftData

struct RunWorkoutView: View {
    @State private var viewModel: RunWorkoutViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext // Access ModelContext

    // Custom Initializer to inject ModelContext
    init() {
        // Must initialize @State properties within init or use default values
        // We create the ViewModel here, passing the context
        _viewModel = State(initialValue: RunWorkoutViewModel(modelContext: nil)) // Temp assignment
    }

    var body: some View {
        VStack(spacing: 0) {
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
        .background(Color.tacticalCream.ignoresSafeArea())
        .navigationTitle("Run Tracking")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar { // Custom toolbar for close button
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Close") {
                    if viewModel.runState == .running || viewModel.runState == .paused {
                        viewModel.stopRun() // Ensure run stops if active
                    }
                    dismiss()
                }
                .foregroundColor(.brassGold)
            }
        }
        // Inject the actual modelContext when the view appears and context is available
        .onAppear {
            // Check if viewModel needs re-initialization with the actual context
            // This ensures the context is available when the VM is fully used
            if viewModel.modelContext == nil { // Only initialize if context wasn't set (or needs refresh)
                 viewModel = RunWorkoutViewModel(modelContext: modelContext)
            }
         }
    }

    // Helper View for Top Metrics
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
        }
        .padding()
        .background(Color.deepOpsGreen) // Use dark background for contrast
    }

    // Helper for single metric display
    struct MetricDisplay: View {
        let label: String
        let value: String
        var body: some View {
            VStack {
                Text(label)
                    .labelStyle(size: 12, color: .inactiveGray) // Smaller label
                    .padding(.bottom, 1)
                Text(value)
                    .statsNumberStyle(size: 24, color: .tacticalCream) // Cream text on dark bg
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
                 label: { controlButtonLabel(systemName: "play.circle.fill", color: .green) }
             case .running:
                 Button { viewModel.pauseRun() }
                 label: { controlButtonLabel(systemName: "pause.circle.fill", color: .yellow) }
             case .paused:
                 HStack(spacing: 40) {
                     Button { viewModel.resumeRun() }
                     label: { controlButtonLabel(systemName: "play.circle.fill", color: .green) }

                     Button { viewModel.stopRun() }
                     label: { controlButtonLabel(systemName: "stop.circle.fill", color: .red) }
                 }
             case .finished, .error:
                 Button { dismiss() }
                 label: { controlButtonLabel(systemName: "checkmark.circle.fill", color: .brassGold) }
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
                 .foregroundColor(viewModel.runState == .permissionDenied ? .tacticalGray : .orange)

             Text(viewModel.runState == .permissionDenied ? "Location Access Denied" : "Error")
                 .font(.title2).bold()

             Text(viewModel.errorMessage ?? "An error occurred.")
                 .multilineTextAlignment(.center)
                 .foregroundColor(.tacticalGray)
                 .padding(.horizontal)

             if viewModel.runState == .permissionDenied {
                 Button("Open Settings") {
                     if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
                         UIApplication.shared.open(url)
                     }
                 }
                 .buttonStyle(PrimaryButtonStyle())
                 .padding(.top)
             } else if case .error = viewModel.runState {
                 Button("Dismiss") {
                     viewModel.errorMessage = nil // Clear error message
                     viewModel.runState = .ready // Go back to ready state?
                 }
                  .buttonStyle(PrimaryButtonStyle())
                  .padding(.top)
             }
         }
         .padding(30)
         .background(.thinMaterial) // Use material background for overlay
         .cornerRadius(AppConstants.panelCornerRadius)
         .shadow(radius: 5)
         .padding(AppConstants.globalPadding) // Padding around the overlay box
     }
}

// MapView Placeholder (Replace with actual MapKit view if desired)
struct MapViewPlaceholder: View {
    var body: some View {
        ZStack {
            Color.gray.opacity(0.2)
            Text("Map Area (Optional)")
                .foregroundColor(.tacticalGray)
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