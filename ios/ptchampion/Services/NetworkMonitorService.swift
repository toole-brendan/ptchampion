import Foundation
import Network
import Combine

/// Notification names for network connectivity events
extension Notification.Name {
    static let connectivityChanged = Notification.Name("connectivityChanged")
    static let connectivityRestored = Notification.Name("connectivityRestored")
    static let connectivityLost = Notification.Name("connectivityLost")
}

/// Service to monitor network connectivity using NWPathMonitor
class NetworkMonitorService: ObservableObject {
    /// Published property for connectivity status
    @Published var isConnected: Bool = true
    
    /// Published property for connection type
    @Published var connectionType: ConnectionType = .unknown
    
    /// Connection type enumeration
    enum ConnectionType {
        case wifi
        case cellular
        case wiredEthernet
        case unknown
    }
    
    /// The path monitor instance
    private let monitor = NWPathMonitor()
    
    /// Queue for path monitor
    private let queue = DispatchQueue(label: "NetworkMonitor", qos: .background)
    
    /// Get current reachability status as a string
    var connectionDescription: String {
        if isConnected {
            switch connectionType {
            case .wifi: return "Connected (WiFi)"
            case .cellular: return "Connected (Cellular)"
            case .wiredEthernet: return "Connected (Ethernet)"
            case .unknown: return "Connected"
            }
        } else {
            return "Disconnected"
        }
    }
    
    /// Initialize and start monitoring
    init() {
        startMonitoring()
    }
    
    /// Clean up on deinit
    deinit {
        stopMonitoring()
    }
    
    /// Start network path monitoring
    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                // Determine if we have connectivity
                let isConnected = path.status == .satisfied
                let oldStatus = self?.isConnected ?? false
                
                // Update connection type
                var connectionType: ConnectionType = .unknown
                if path.usesInterfaceType(.wifi) {
                    connectionType = .wifi
                } else if path.usesInterfaceType(.cellular) {
                    connectionType = .cellular
                } else if path.usesInterfaceType(.wiredEthernet) {
                    connectionType = .wiredEthernet
                }
                
                // Update published properties
                self?.isConnected = isConnected
                self?.connectionType = connectionType
                
                // Post notifications about connectivity changes
                if oldStatus != isConnected {
                    // General change notification
                    NotificationCenter.default.post(
                        name: .connectivityChanged,
                        object: self,
                        userInfo: ["isConnected": isConnected]
                    )
                    
                    // Specific state notifications
                    if isConnected {
                        // Connected - useful for triggering sync
                        NotificationCenter.default.post(name: .connectivityRestored, object: self)
                    } else {
                        // Disconnected - useful for showing UI indicators
                        NotificationCenter.default.post(name: .connectivityLost, object: self)
                    }
                }
                
                print("Network connectivity: \(isConnected ? "Connected" : "Disconnected") via \(connectionType)")
            }
        }
        
        // Start monitoring
        monitor.start(queue: queue)
    }
    
    /// Stop monitoring network path
    func stopMonitoring() {
        monitor.cancel()
    }
} 