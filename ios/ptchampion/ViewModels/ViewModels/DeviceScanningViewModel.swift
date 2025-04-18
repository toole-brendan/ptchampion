import Foundation
import Combine
import CoreBluetooth // Needed for CBManagerState

@MainActor // Ensure UI updates are on the main thread
class DeviceScanningViewModel: ObservableObject {
    
    private let bluetoothService: BluetoothServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    @Published var bluetoothState: CBManagerState = .unknown
    @Published var discoveredPeripherals: [DiscoveredPeripheral] = []
    @Published var connectionState: PeripheralConnectionState = .disconnected()
    @Published var connectedPeripheral: CBPeripheral? = nil
    @Published var isScanning: Bool = false // Track scanning state explicitly

    init(bluetoothService: BluetoothServiceProtocol = BluetoothService()) {
        self.bluetoothService = bluetoothService
        subscribeToBluetoothService() 
    }
    
    private func subscribeToBluetoothService() {
        // Subscribe to Bluetooth state changes
        bluetoothService.centralManagerStatePublisher
            .receive(on: DispatchQueue.main) // Ensure updates are on main thread for @Published
            .sink { [weak self] state in
                self?.bluetoothState = state
                // Stop scanning if Bluetooth powers off
                if state != .poweredOn {
                    self?.isScanning = false 
                }
            }
            .store(in: &cancellables)
        
        // Subscribe to discovered peripherals
        bluetoothService.discoveredPeripheralsPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.discoveredPeripherals, on: self)
            .store(in: &cancellables)
            
        // Subscribe to connection state changes
        bluetoothService.connectionStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.connectionState = state
                // Handle UI changes based on state (e.g., stop showing loading indicator)
            }
            .store(in: &cancellables)
            
        // Subscribe to connected peripheral changes
        bluetoothService.connectedPeripheralPublisher
             .receive(on: DispatchQueue.main)
            .assign(to: \.connectedPeripheral, on: self)
            .store(in: &cancellables)
    }
    
    func startScan() {
        guard bluetoothState == .poweredOn else {
            print("ViewModel: Cannot scan, Bluetooth not powered on.")
            // TODO: Show alert to user?
            return
        }
        isScanning = true
        discoveredPeripherals = [] // Clear previous results
        bluetoothService.startScan()
    }
    
    func stopScan() {
        isScanning = false
        bluetoothService.stopScan()
    }
    
    func connect(peripheral: DiscoveredPeripheral) {
        guard bluetoothState == .poweredOn else {
             print("ViewModel: Cannot connect, Bluetooth not powered on.")
            return
        }
        // Ask the service to connect
        bluetoothService.connect(to: peripheral.peripheral)
    }
    
    func disconnect() {
        bluetoothService.disconnect(from: nil)
    }
} 