import SwiftUI
import CoreBluetooth // For CBManagerState

struct DeviceScanningView: View {
    @StateObject private var viewModel = DeviceScanningViewModel()
    @State private var showingDeviceDetails = false
    @AppStorage("useImperialUnits") private var useImperialUnits = false
    
    var body: some View {
        NavigationView {
            VStack {
                // Status Header
                bluetoothStatusHeader()
                
                if viewModel.connectedPeripheral != nil {
                    // Connected device metrics
                    connectedDeviceMetrics()
                }
                
                // List of Discovered Devices
                List(viewModel.discoveredPeripherals) { discovered in
                    HStack {
                        VStack(alignment: .leading) {
                            HStack {
                                Text(discovered.name)
                                    .font(.headline)
                                
                                // Show device type if known
                                if discovered.deviceType != .unknown {
                                    Text("• \(discovered.deviceType.rawValue)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Text("RSSI: \(discovered.rssi)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        
                        // Connect Button or Status Indicator
                        deviceConnectionButton(for: discovered)
                    }
                }
                
                Spacer()
                
                // Scan Button
                scanButton()
                
            }
            .navigationTitle("Fitness Devices")
            .sheet(isPresented: $showingDeviceDetails) {
                deviceDetailsView()
            }
        }
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private func bluetoothStatusHeader() -> some View {
        VStack {
            Text("Bluetooth Status: \(viewModel.bluetoothState.stateDescription)")
                .padding()
                .foregroundColor(viewModel.bluetoothState == .poweredOn ? .green : .red)
            
            if viewModel.isScanning {
                HStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                    Text("Scanning for fitness devices...")
                }
                .padding(.bottom)
            }
        }
    }
    
    @ViewBuilder
    private func connectedDeviceMetrics() -> some View {
        VStack(spacing: 12) {
            HStack {
                Text(viewModel.deviceDisplayName())
                    .font(.headline)
                
                if viewModel.batteryLevel != nil {
                    Spacer()
                    Label(viewModel.formattedBatteryLevel(), systemImage: "battery.50")
                        .foregroundColor(.green)
                }
            }
            
            Divider()
            
            HStack(spacing: 20) {
                if viewModel.heartRate > 0 {
                    DeviceMetricView(
                        value: viewModel.formattedHeartRate(),
                        title: "Heart Rate",
                        systemImage: "heart.fill"
                    )
                }
                
                if viewModel.currentPace.metersPerSecond > 0 {
                    DeviceMetricView(
                        value: viewModel.formattedPace(useImperial: useImperialUnits),
                        title: useImperialUnits ? "min/mile" : "min/km",
                        systemImage: "figure.run"
                    )
                }
                
                if viewModel.currentCadence.stepsPerMinute > 0 {
                    DeviceMetricView(
                        value: viewModel.formattedCadence(),
                        title: "Cadence",
                        systemImage: "metronome"
                    )
                }
            }
            
            Button("Show Device Details") {
                showingDeviceDetails = true
            }
            .padding(.top, 8)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private func scanButton() -> some View {
        Button {
            if viewModel.isScanning {
                viewModel.stopScan()
            } else {
                viewModel.startScan()
            }
        } label: {
            Text(viewModel.isScanning ? "Stop Scan" : "Start Scan")
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.bluetoothState == .poweredOn ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
        .padding()
        .disabled(viewModel.bluetoothState != .poweredOn)
    }
    
    @ViewBuilder
    private func deviceConnectionButton(for discovered: DiscoveredPeripheral) -> some View {
        // Check if this is the currently connected peripheral
        if viewModel.connectedPeripheral?.identifier == discovered.id {
            // Check connection state specifically for this connected device
            switch viewModel.connectionState {
            case .connected:
                Button("Disconnect") { viewModel.disconnect() }
                    .buttonStyle(.bordered)
                    .tint(.red)
            case .disconnecting:
                Text("Disconnecting...").foregroundColor(.gray)
            default: // Should not happen if connectedPeripheral matches
                Text("State Error").foregroundColor(.red)
            }
        } else {
            // Check if we are trying to connect to *this* peripheral
            if case .connecting = viewModel.connectionState, 
               viewModel.connectedPeripheral?.identifier == discovered.id { // Check connecting peripheral ID if available
                 ProgressView()
            } else {
                // If disconnected and ready, show Connect button
                Button("Connect") {
                    viewModel.connect(peripheral: discovered)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isScanning || !isConnectable(state: viewModel.connectionState))
            }
        }
    }
    
    @ViewBuilder
    private func deviceDetailsView() -> some View {
        VStack {
            Text("Device Details")
                .font(.headline)
                .padding()
            
            if let peripheral = viewModel.connectedPeripheral {
                VStack(alignment: .leading, spacing: 12) {
                    DetailRow(label: "Name", value: peripheral.name ?? "Unknown")
                    DetailRow(label: "Manufacturer", value: viewModel.manufacturerName ?? "Unknown")
                    DetailRow(label: "Type", value: viewModel.deviceType.rawValue)
                    DetailRow(label: "Battery", value: viewModel.formattedBatteryLevel())
                    
                    Divider()
                    
                    Text("Supported Features:")
                        .font(.headline)
                        .padding(.top, 8)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        FeatureRow(title: "Heart Rate", isSupported: viewModel.heartRate > 0)
                        FeatureRow(title: "Location Tracking", isSupported: viewModel.currentLocation != nil)
                        FeatureRow(title: "Running Pace", isSupported: viewModel.currentPace.metersPerSecond > 0)
                        FeatureRow(title: "Running Cadence", isSupported: viewModel.currentCadence.stepsPerMinute > 0)
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
            
            Button("Close") {
                showingDeviceDetails = false
            }
            .padding()
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

// Helper components
struct DeviceMetricView: View {
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

struct DetailRow: View {
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

struct FeatureRow: View {
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

#Preview {
    DeviceScanningView()
} 