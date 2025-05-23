import Foundation
import CoreLocation

// MARK: - Device Types
enum FitnessDeviceType: String, Codable {
    case unknown = "Unknown Device"
    case garmin = "Garmin"
    case polar = "Polar"
    case suunto = "Suunto"
    case appleWatch = "Apple Watch"
    case wahoo = "Wahoo"
    case genericHeartRateMonitor = "Heart Rate Monitor"
    case genericFitnessTracker = "Fitness Tracker"
    
    // Known device manufacturer prefixes
    static func detectDeviceType(from manufacturerName: String?) -> FitnessDeviceType {
        guard let name = manufacturerName?.lowercased() else { return .unknown }
        
        if name.contains("garmin") {
            return .garmin
        } else if name.contains("polar") {
            return .polar
        } else if name.contains("suunto") {
            return .suunto
        } else if name.contains("apple") {
            return .appleWatch
        } else if name.contains("wahoo") {
            return .wahoo
        } else {
            return .genericFitnessTracker
        }
    }
    
    // Helper method to determine if the device supports location data
    static func supportsLocation(_ type: FitnessDeviceType) -> Bool {
        switch type {
        case .garmin, .suunto:
            return true // Most modern fitness watches support location
        case .appleWatch:
            return false // Apple Watch location comes through HealthKit, not BLE
        case .polar, .wahoo:
            return false // These are typically HR straps without GPS
        case .unknown, .genericHeartRateMonitor, .genericFitnessTracker:
            return false // Assume no GPS unless proven otherwise
        }
    }
}

// MARK: - Running Metrics
struct RunningPace: Equatable {
    // Minutes per kilometer
    let minutesPerKm: Double
    // Minutes per mile (for US users)
    let minutesPerMile: Double
    // Raw pace in m/s
    let metersPerSecond: Double
    
    init(metersPerSecond: Double) {
        self.metersPerSecond = metersPerSecond
        
        // Calculate minutes per kilometer (convert m/s to min/km)
        self.minutesPerKm = metersPerSecond > 0 ? (1000.0 / metersPerSecond) / 60.0 : 0
        
        // Calculate minutes per mile (convert m/s to min/mile)
        self.minutesPerMile = metersPerSecond > 0 ? (1609.34 / metersPerSecond) / 60.0 : 0
    }
    
    // Format as mm:ss
    func formattedPace(useImperial: Bool = false) -> String {
        let paceValue = useImperial ? minutesPerMile : minutesPerKm
        if paceValue <= 0 {
            return "--:--"
        }
        
        let minutes = Int(paceValue)
        let seconds = Int((paceValue - Double(minutes)) * 60)
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    static let zero = RunningPace(metersPerSecond: 0)
}

struct RunningCadence: Equatable {
    // Steps per minute
    let stepsPerMinute: Int
    // Strides per minute (typically half of steps for running)
    let stridesPerMinute: Int
    
    init(stepsPerMinute: Int) {
        self.stepsPerMinute = stepsPerMinute
        self.stridesPerMinute = stepsPerMinute / 2
    }
    
    static let zero = RunningCadence(stepsPerMinute: 0)
}

// MARK: - Workout Location Data
struct WorkoutLocationSnapshot: Codable, Equatable {
    let timestamp: Date
    let location: LocationData
    let heartRate: Int?
    let pace: Double? // in m/s
    let cadence: Int? // steps per minute
    
    struct LocationData: Codable, Equatable {
        let latitude: Double
        let longitude: Double
        let altitude: Double?
        let speed: Double?
        let course: Double?
        let horizontalAccuracy: Double?
        let verticalAccuracy: Double?
        
        init(from clLocation: CLLocation) {
            self.latitude = clLocation.coordinate.latitude
            self.longitude = clLocation.coordinate.longitude
            self.altitude = clLocation.altitude
            self.speed = clLocation.speed > 0 ? clLocation.speed : nil
            self.course = clLocation.course >= 0 ? clLocation.course : nil
            self.horizontalAccuracy = clLocation.horizontalAccuracy >= 0 ? clLocation.horizontalAccuracy : nil
            self.verticalAccuracy = clLocation.verticalAccuracy >= 0 ? clLocation.verticalAccuracy : nil
        }
    }
} 