import SwiftUI
import CoreLocation // For CLAuthorizationStatus
import SwiftData // Import SwiftData
import CoreBluetooth // For CBManagerState

struct RunWorkoutView: View {
    @StateObject private var viewModel: RunWorkoutViewModel // Use @StateObject
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext // Access ModelContext

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
            // Re-initialize the viewModel with the actual context when the view appears.
            // This ensures the VM has access to the context from the environment.
             viewModel = RunWorkoutViewModel(modelContext: modelContext)
         }
    }

    // MARK: - Subviews

    // New Header for Device Status
    @ViewBuilder
    private func deviceStatusHeader() -> some View {
        HStack {
            // Bluetooth Power Status Icon
            Image(systemName: viewModel.bluetoothState == .poweredOn ? "bolt.fill" : "bolt.slash.fill")
                .foregroundColor(viewModel.bluetoothState == .poweredOn ? .blue : .gray)

            // Connection Status Text
            switch viewModel.deviceConnectionState {
            case .disconnected:
                Text("No Device Connected")
                    .foregroundColor(.gray)
            case .connecting:
                HStack {
                    Text("Connecting...")
                    ProgressView().scaleEffect(0.7)
                }.foregroundColor(.orange)
            case .connected(let peripheral):
                Text("Connected: \(peripheral.name ?? "Device")")
                    .foregroundColor(.green)
            case .disconnecting:
                Text("Disconnecting...")
                    .foregroundColor(.gray)
            case .failed:
                Text("Connection Failed")
                    .foregroundColor(.red)
            }
            
            Spacer()
            
            // Location Source Indicator
            HStack(spacing: 3) {
                Image(systemName: viewModel.locationSource == .watch ? "applewatch" : "iphone")
                Text("GPS")
            }
            .foregroundColor(viewModel.locationSource == .watch ? .blue : .primary)

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

// Assume WorkoutResultSwiftData exists
@Model
final class WorkoutResultSwiftData { // Make final if no subclasses
   var serverId: Int?
   @Attribute(.unique) var localId: UUID // Add a unique local ID
   var userId: Int
   var exerciseId: Int
   var repetitions: Int?
   var formScore: Int?
   var timeInSeconds: Int
   var grade: Int?
   var completed: Bool
   @Attribute(.externalStorage) var metadata: String? // Use external storage for potentially large JSON
   var deviceId: String?
   var syncStatus: String? // "pending", "synced", "error"
   var createdAt: Date

    init(serverId: Int? = nil, localId: UUID = UUID(), userId: Int, exerciseId: Int, repetitions: Int? = nil, formScore: Int? = nil, timeInSeconds: Int, grade: Int? = nil, completed: Bool, metadata: String? = nil, deviceId: String? = nil, syncStatus: String? = nil, createdAt: Date) {
        self.serverId = serverId
        self.localId = localId
        self.userId = userId
        self.exerciseId = exerciseId
        self.repetitions = repetitions
        self.formScore = formScore
        self.timeInSeconds = timeInSeconds
        self.grade = grade
        self.completed = completed
        self.metadata = metadata
        self.deviceId = deviceId
        self.syncStatus = syncStatus
        self.createdAt = createdAt
    }
}

// Helper for Primary Button Style (Ensure this exists)
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.deepOpsGreen) // Example color
            .foregroundColor(.white)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
}

// Helpers for View Styles (Ensure these exist)
extension Text {
    func subheadingStyle() -> some View { self.font(.title3).bold() }
    func labelStyle(size: CGFloat = 14, color: Color = .gray) -> some View { self.font(.system(size: size)).foregroundColor(color) }
    func statsNumberStyle(size: CGFloat = 32, color: Color = .primary) -> some View { self.font(.system(size: size, weight: .bold)).foregroundColor(color) }
}

extension View {
    func cardStyle() -> some View { self.background(Color(UIColor.systemBackground)).cornerRadius(10).shadow(radius: 3) }
}

struct AppConstants {
    static let globalPadding: CGFloat = 16
    static let panelCornerRadius: CGFloat = 12
}

// Helper for Distance Unit preference
enum DistanceUnit: String, Codable, CaseIterable {
    case miles, kilometers
}

// Assume KeychainService and its getUserId() method exist
protocol KeychainServiceProtocol { func getUserId() -> Int? }
class KeychainService: KeychainServiceProtocol { func getUserId() -> Int? { return 123 } } // Mock

// Assume LocationService and its publishers exist
protocol LocationServiceProtocol {
    var authorizationStatusPublisher: AnyPublisher<CLAuthorizationStatus, Never> { get }
    var locationPublisher: AnyPublisher<CLLocation?, Never> { get }
    var errorPublisher: AnyPublisher<Error, Never> { get }
    func requestLocationPermission()
    func startUpdatingLocation()
    func stopUpdatingLocation()
}
class LocationService: LocationServiceProtocol { // Mock
    var authorizationStatusPublisher: AnyPublisher<CLAuthorizationStatus, Never> = Just(.authorizedWhenInUse).eraseToAnyPublisher()
    var locationPublisher: AnyPublisher<CLLocation?, Never> = Just(nil).eraseToAnyPublisher()
    var errorPublisher: AnyPublisher<Error, Never> = Empty().eraseToAnyPublisher()
    func requestLocationPermission() {}
    func startUpdatingLocation() {}
    func stopUpdatingLocation() {}
} 