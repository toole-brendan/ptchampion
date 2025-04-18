import SwiftUI
import CoreBluetooth // For CBManagerState description

struct DeviceScanningView: View {
    @StateObject private var viewModel = DeviceScanningViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                // Status Header
                bluetoothStatusHeader()
                
                // List of Discovered Devices
                List(viewModel.discoveredPeripherals) { discovered in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(discovered.name)
                                .font(.headline)
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
            .navigationTitle("Scan Devices")
        }
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private func bluetoothStatusHeader() -> some View {
        Text("Bluetooth Status: \(viewModel.bluetoothState.description)")
            .padding()
            .foregroundColor(viewModel.bluetoothState == .poweredOn ? .green : .red)
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
                .padding(.top)
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

#Preview {
    DeviceScanningView()
} 