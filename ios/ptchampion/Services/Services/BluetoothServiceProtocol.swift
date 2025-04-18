import Foundation
import CoreBluetooth
import Combine
import CoreLocation

// Protocol for Bluetooth interactions
protocol BluetoothServiceProtocol {
    var centralManagerStatePublisher: AnyPublisher<CBManagerState, Never> { get }
    var discoveredPeripheralsPublisher: AnyPublisher<[DiscoveredPeripheral], Never> { get }
    var connectionStatePublisher: AnyPublisher<PeripheralConnectionState, Never> { get }
    var connectedPeripheralPublisher: AnyPublisher<CBPeripheral?, Never> { get }
    var heartRatePublisher: AnyPublisher<Int, Never> { get }
    var locationPublisher: AnyPublisher<CLLocation, Never> { get }
    var manufacturerNamePublisher: AnyPublisher<String?, Never> { get }
    var locationServiceAvailablePublisher: AnyPublisher<Bool, Never> { get }
    
    func startScan()
    func stopScan()
    func connect(peripheral: CBPeripheral)
    func disconnect()
} 