import SwiftUI
import HealthKit
import CoreBluetooth

struct FitnessDeviceManagerView: View {
    @EnvironmentObject var viewModel: FitnessDeviceManagerViewModel
    @State private var showingDeviceDetails = false
    @State private var activeBanner: BannerType?     // nil = none
    @AppStorage("useImperialUnits") private var useImperialUnits = false
    @AppStorage("dismissedBluetoothWarning") private var dismissedBluetoothWarning = false

    enum BannerType { case bluetooth, healthKit }
    
    var body: some View {
        VStack(spacing: 0) {
            // Banner at the top
            bannerView
            
            // Header
            deviceSourcesSection()
            
            // Current Metrics Section
            if viewModel.isReceivingHeartRateData || 
               viewModel.isReceivingPaceData || 
               viewModel.isReceivingCadenceData {
                currentMetricsSection()
            }
            
            // Device Sections
            if viewModel.isHealthKitAvailable {
                appleWatchSection()
                    .padding(.top)
            }
            
            bluetoothDevicesSection()
                .padding(.top)
            
            Spacer()
        }
        .navigationTitle("Fitness Devices")
        .onAppear {
            // This fires after the NavigationView is on-screen.
            print("DEBUG: [FitnessDeviceManagerView] onAppear")
            print("DEBUG: [FitnessDeviceManagerView] Current activeBanner: \(String(describing: activeBanner))")
            print("DEBUG: [FitnessDeviceManagerView] dismissedBluetoothWarning: \(viewModel.dismissedBluetoothWarning)")
            
            // Track state
            viewModel.showBluetoothError = false
            print("DEBUG: [FitnessDeviceManagerView] Reset showBluetoothError to false")
            
            if viewModel.bluetoothState != .poweredOn && !dismissedBluetoothWarning {
                print("DEBUG: [FitnessDeviceManagerView] Bluetooth state is \(viewModel.bluetoothState.stateDescription), showing banner")
                showBluetoothBanner()
            } else {
                print("DEBUG: [FitnessDeviceManagerView] No banner needed: Bluetooth=\(viewModel.bluetoothState.stateDescription), dismissedWarning=\(dismissedBluetoothWarning)")
            }
        }
        .onDisappear {
            print("DEBUG: [FitnessDeviceManagerView] onDisappear - activeBanner: \(String(describing: activeBanner))")
            print("DEBUG: [FitnessDeviceManagerView] onDisappear - dismissedBluetoothWarning: \(viewModel.dismissedBluetoothWarning)")
            print("DEBUG: [FitnessDeviceManagerView] onDisappear - bluetoothState: \(viewModel.bluetoothState.stateDescription)")
            
            // Reset banner state on disappear to ensure it can be shown again
            if activeBanner != nil {
                print("DEBUG: [FitnessDeviceManagerView] Resetting activeBanner from \(String(describing: activeBanner)) to nil on disappear")
                activeBanner = nil
            } else {
                print("DEBUG: [FitnessDeviceManagerView] activeBanner already nil on disappear")
            }
        }
        .sheet(isPresented: $showingDeviceDetails) {
            deviceDetailsView()
        }
        .onReceive(viewModel.$showBluetoothError) { hasError in
            print("DEBUG: [FitnessDeviceManagerView] onReceive showBluetoothError: \(hasError)")
            print("DEBUG: [FitnessDeviceManagerView] onReceive dismissedBluetoothWarning: \(dismissedBluetoothWarning)")
            
            guard hasError, 
                  !dismissedBluetoothWarning,
                  activeBanner == nil   // Prevent rebuild loop
            else {
                if hasError {
                    print("DEBUG: [FitnessDeviceManagerView] Ignoring showBluetoothError because dismissedBluetoothWarning=\(dismissedBluetoothWarning) or banner exists=\(activeBanner != nil)")
                }
                return
            }
            
            print("DEBUG: [FitnessDeviceManagerView] Showing banner and auto-resetting trigger")
            showBluetoothBanner()
            
            // Auto-reset the trigger so the next identical value is ignored
            viewModel.showBluetoothError = false
        }
        // Removed automatic HealthKit authorization to prevent auto-dismissal
        // Now authorization only happens when user explicitly taps "Connect" button
    }
    
    // MARK: - Banner Helpers
    private func showBluetoothBanner() {
        print("DEBUG: [FitnessDeviceManagerView] Showing Bluetooth Banner - activeBanner was \(String(describing: activeBanner))")
        print("DEBUG: [FitnessDeviceManagerView] dismissedBluetoothWarning = \(dismissedBluetoothWarning)")
        print("DEBUG: [FitnessDeviceManagerView] Bluetooth state = \(viewModel.bluetoothState.stateDescription)")
        
        // Guard against showing banner that's already dismissed or showing
        guard activeBanner == nil, !dismissedBluetoothWarning else {
            print("DEBUG: [FitnessDeviceManagerView] NOT showing banner because: activeBanner=\(String(describing: activeBanner)), dismissedWarning=\(dismissedBluetoothWarning)")
            return
        }
            
        print("DEBUG: [FitnessDeviceManagerView] Setting activeBanner to .bluetooth")
        activeBanner = .bluetooth
        viewModel.showBluetoothError = false  // reset trigger
        print("DEBUG: [FitnessDeviceManagerView] Set activeBanner to .bluetooth")
    }
    
    private func showHealthKitBanner() {
        print("DEBUG: Showing HealthKit Banner - activeBanner was \(String(describing: activeBanner))")
        if activeBanner == nil { 
            activeBanner = .healthKit
            print("DEBUG: Set activeBanner to .healthKit")
        }
    }
    
    // Add banner debugging
    private var bannerView: some View {
        Group {
            if let banner = activeBanner {
                WarningBanner(
                    title: banner == .bluetooth ? "Bluetooth Error"
                                                : "HealthKit Authorization",
                    message: banner == .bluetooth
                             ? viewModel.bluetoothErrorMessage
                             : "Please allow PT Champion to access your health data to use Apple Watch features.",
                    primary: .init(label: "OK") { 
                        print("DEBUG: [FitnessDeviceManagerView] Banner primary button (OK) tapped - banner type: \(banner)")
                        // Set the dismissal flag first, then dismiss the banner
                        if banner == .bluetooth {
                            print("DEBUG: [FitnessDeviceManagerView] Setting dismissedBluetoothWarning = true")
                            dismissedBluetoothWarning = true
                        }
                        
                        // Slight delay before dismissing to ensure the tap is fully processed
                        print("DEBUG: [FitnessDeviceManagerView] Scheduling banner dismissal after 0.1s delay")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            print("DEBUG: [FitnessDeviceManagerView] Inside delayed dismissal block")
                            print("DEBUG: [FitnessDeviceManagerView] Setting activeBanner = nil")
                            activeBanner = nil 
                            print("DEBUG: [FitnessDeviceManagerView] Banner dismissal complete")
                        }
                    },
                    secondary: banner == .bluetooth
                        ? .init(label: "Settings") {
                              print("DEBUG: [FitnessDeviceManagerView] Banner settings button tapped")
                              if let url = URL(string: UIApplication.openSettingsURLString) {
                                  print("DEBUG: [FitnessDeviceManagerView] Opening settings URL")
                                  UIApplication.shared.open(url)
                              }
                              
                              // Set dismissed flag FIRST to prevent race condition
                              print("DEBUG: [FitnessDeviceManagerView] Setting dismissedBluetoothWarning = true")
                              dismissedBluetoothWarning = true
                              
                              print("DEBUG: [FitnessDeviceManagerView] Scheduling banner dismissal after settings opened (0.5s delay)")
                              DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                  print("DEBUG: [FitnessDeviceManagerView] Inside settings delayed dismissal block")
                                  print("DEBUG: [FitnessDeviceManagerView] Setting activeBanner = nil")
                                  activeBanner = nil
                                  print("DEBUG: [FitnessDeviceManagerView] Banner dismissal after settings complete")
                              }
                          }
                        : nil
                )
                .onAppear {
                    print("DEBUG: [FitnessDeviceManagerView] Banner appeared - type: \(banner)")
                    print("DEBUG: [FitnessDeviceManagerView] Current dismissedBluetoothWarning: \(viewModel.dismissedBluetoothWarning)")
                }
                .onDisappear {
                    print("DEBUG: [FitnessDeviceManagerView] Banner disappeared - type: \(banner)")
                    print("DEBUG: [FitnessDeviceManagerView] dismissedBluetoothWarning at disappear: \(viewModel.dismissedBluetoothWarning)")
                    print("DEBUG: [FitnessDeviceManagerView] activeBanner at disappear: \(String(describing: activeBanner))")
                }
                .id(banner) // Force view recreation when banner type changes
            }
        }
        .animation(.easeInOut, value: activeBanner)
    }
    
    // MARK: - Sections
    
    @ViewBuilder
    private func deviceSourcesSection() -> some View {
        VStack(spacing: 8) {
            Text("Data Sources")
                .font(.headline)
                .padding(.top)
            
            HStack(spacing: 16) {
                // Heart Rate Source
                VStack {
                    Label("Heart Rate", systemImage: "heart.fill")
                        .font(.caption)
                    
                    Text(viewModel.isReceivingHeartRateData ? viewModel.primaryDataSource() : "None")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color(.secondarySystemBackground)))
                
                // Location Source
                VStack {
                    Label("GPS", systemImage: "location.fill")
                        .font(.caption)
                    
                    Text(viewModel.isReceivingLocationData ? viewModel.deviceDisplayName() : "Phone")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color(.secondarySystemBackground)))
                
                // Pace Source
                VStack {
                    Label("Pace", systemImage: "figure.walk")
                        .font(.caption)
                    
                    Text(viewModel.isReceivingPaceData ? viewModel.deviceDisplayName() : "None")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color(.secondarySystemBackground)))
            }
            .padding(.horizontal)
        }
        .padding(.bottom)
    }
    
    @ViewBuilder
    private func currentMetricsSection() -> some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                if viewModel.heartRate > 0 {
                    FitnessMetricView(
                        value: viewModel.formattedHeartRate(),
                        title: "Heart Rate",
                        systemImage: "heart.fill"
                    )
                }
                
                if viewModel.currentPace.metersPerSecond > 0 {
                    FitnessMetricView(
                        value: viewModel.formattedPace(useImperial: useImperialUnits),
                        title: useImperialUnits ? "min/mile" : "min/km",
                        systemImage: "figure.run"
                    )
                }
                
                if viewModel.currentCadence.stepsPerMinute > 0 {
                    FitnessMetricView(
                        value: viewModel.formattedCadence(),
                        title: "Cadence",
                        systemImage: "metronome"
                    )
                }
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
            .padding(.horizontal)
        }
    }
    
    @ViewBuilder
    private func appleWatchSection() -> some View {
        VStack(alignment: .leading) {
            Text("Apple Watch")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 10) {
                HStack {
                    Image(systemName: "applewatch")
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading) {
                        Text(viewModel.isHealthKitAuthorized ? "Connected" : "Not Connected")
                            .font(.headline)
                        
                        Text(viewModel.isHealthKitAuthorized ? 
                             "Data from Apple Health" : 
                             "Authorization required")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if !viewModel.isHealthKitAuthorized {
                        Button("Connect") {
                            Task {
                                let authorized = await viewModel.requestHealthKitAuthorization()
                                if authorized {
                                    await viewModel.fetchRecentWorkouts()
                                } else {
                                    showHealthKitBanner()
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                
                if viewModel.isHealthKitAuthorized {
                    Toggle("Prefer Apple Watch for Heart Rate", isOn: $viewModel.preferAppleWatchForHeartRate)
                        .font(.caption)
                        .padding(.top, 4)
                }
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
            .padding(.horizontal)
        }
    }
    
    @ViewBuilder
    private func bluetoothDevicesSection() -> some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Bluetooth Devices")
                    .font(.headline)
                
                Spacer()
                
                Text("Status: \(viewModel.bluetoothState.stateDescription)")
                    .font(.caption)
                    .foregroundColor(viewModel.bluetoothState == .poweredOn ? .green : .red)
            }
            .padding(.horizontal)
            
            // Connected Device
            if let device = viewModel.connectedBluetoothDevice {
                connectedDeviceView(device)
            } else if viewModel.hasPreferredDevice() {
                // Show auto-connect option if we have a preferred device but not connected
                autoConnectDeviceView()
            }
            
            // Scan Button
            HStack {
                Button {
                    if viewModel.isBluetoothScanning {
                        viewModel.stopBluetoothScan()
                    } else {
                        viewModel.startBluetoothScan()
                    }
                } label: {
                    Text(viewModel.isBluetoothScanning ? "Stop Scanning" : "Scan for Devices")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(viewModel.isBluetoothScanning ? .red : .blue)
                .disabled(viewModel.bluetoothState != .poweredOn)
            }
            .padding(.horizontal)
            
            // Scanning Indicator
            if viewModel.isBluetoothScanning {
                HStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                    Text("Scanning for fitness devices...")
                        .font(.caption)
                }
                .padding(.horizontal)
            }
            
            // List of discovered devices
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.bluetoothDevices) { device in
                        deviceRow(device)
                    }
                }
                .padding(.horizontal)
            }
            .frame(height: min(300, CGFloat(viewModel.bluetoothDevices.count * 60 + 20)))
        }
    }
    
    @ViewBuilder
    private func connectedDeviceView(_ device: CBPeripheral) -> some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Connected: \(device.name ?? "Unknown Device")")
                        .font(.headline)
                    
                    HStack {
                        Text(viewModel.deviceDisplayName())
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if let batteryLevel = viewModel.deviceBatteryLevel {
                            Label("\(batteryLevel)%", systemImage: "battery.50")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                }
                
                Spacer()
                
                Button {
                    showingDeviceDetails = true
                } label: {
                    Label("Details", systemImage: "info.circle")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                
                Button {
                    viewModel.disconnectFromDevice()
                } label: {
                    Label("Disconnect", systemImage: "xmark.circle")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private func autoConnectDeviceView() -> some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Previous Device")
                        .font(.headline)
                    
                    Text("You have a preferred device saved")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Reconnect") {
                    viewModel.reconnectToPreferredDevice()
                }
                .buttonStyle(.borderedProminent)
                
                Button("Forget") {
                    viewModel.forgetPreferredDevice()
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private func deviceRow(_ device: DiscoveredPeripheral) -> some View {
        // Don't show already connected devices
        if viewModel.connectedBluetoothDevice?.identifier != device.id {
            HStack {
                VStack(alignment: .leading) {
                    Text(device.name)
                        .font(.headline)
                        
                    HStack {
                        if device.deviceType != .unknown {
                            Text(device.deviceType.rawValue)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Text("RSSI: \(device.rssi)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                if case .connecting = viewModel.deviceConnectionState {
                    ProgressView()
                } else {
                    Button("Connect") {
                        viewModel.connectToDevice(device)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!isConnectable(state: viewModel.deviceConnectionState))
                }
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 8).fill(Color(.tertiarySystemBackground)))
        }
    }
    
    @ViewBuilder
    private func deviceDetailsView() -> some View {
        NavigationView {
            VStack {
                if let peripheral = viewModel.connectedBluetoothDevice {
                    VStack(alignment: .leading, spacing: 12) {
                        FitnessDetailRow(label: "Name", value: peripheral.name ?? "Unknown")
                        FitnessDetailRow(label: "Manufacturer", value: viewModel.deviceManufacturer ?? "Unknown")
                        FitnessDetailRow(label: "Type", value: viewModel.connectedDeviceType.rawValue)
                        FitnessDetailRow(label: "Battery", value: viewModel.formattedBatteryLevel())
                        
                        Divider()
                        
                        Text("Supported Features:")
                            .font(.headline)
                            .padding(.top, 8)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            FitnessFeatureRow(title: "Heart Rate", isSupported: viewModel.isReceivingHeartRateData)
                            FitnessFeatureRow(title: "Location Tracking", isSupported: viewModel.isReceivingLocationData)
                            FitnessFeatureRow(title: "Running Pace", isSupported: viewModel.isReceivingPaceData)
                            FitnessFeatureRow(title: "Running Cadence", isSupported: viewModel.isReceivingCadenceData)
                        }
                        .padding(.leading)
                        
                        Spacer()
                    }
                    .padding()
                } else {
                    Text("No device connected")
                        .foregroundColor(.secondary)
                        .padding()
                    
                    Spacer()
                }
            }
            .navigationTitle("Device Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        showingDeviceDetails = false
                    }
                }
            }
        }
    }
    
    // Helper function to check if the state allows initiating a connection
    private func isConnectable(state: PeripheralConnectionState) -> Bool {
        switch state {
        case .disconnected, .failed:
            return true
        default:
            return false
        }
    }
}

// Re-using helper components from DeviceScanningView
private struct FitnessMetricView: View {
    let value: String
    let title: String
    let systemImage: String
    
    var body: some View {
        VStack {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.title3)
                .bold()
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(minWidth: 70)
    }
}

private struct FitnessDetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
                .frame(width: 120, alignment: .leading)
            
            Text(value)
                .fontWeight(.medium)
            
            Spacer()
        }
    }
}

private struct FitnessFeatureRow: View {
    let title: String
    let isSupported: Bool
    
    var body: some View {
        HStack {
            Image(systemName: isSupported ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(isSupported ? .green : .red)
            
            Text(title)
                .foregroundColor(isSupported ? .primary : .secondary)
            
            Spacer()
        }
    }
}

// Extension to provide descriptive strings for CBManagerState
extension CBManagerState {
    var stateDescription: String {
        switch self {
        case .poweredOn: return "Powered On"
        case .poweredOff: return "Powered Off"
        case .resetting: return "Resetting"
        case .unauthorized: return "Unauthorized"
        case .unsupported: return "Unsupported"
        case .unknown: return "Unknown"
        @unknown default: return "Unknown State"
        }
    }
}

#Preview {
    NavigationView {
        FitnessDeviceManagerView()
            .environmentObject(FitnessDeviceManagerViewModel())
    }
} 