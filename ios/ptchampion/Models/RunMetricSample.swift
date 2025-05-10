import Foundation
import SwiftData
import CoreLocation

@Model
class RunMetricSample {
    // Relationship to parent workout
    @Attribute(.unique) var id: UUID
    var workoutID: UUID
    
    // Timing
    var timestamp: Date
    var elapsedSeconds: Double
    
    // Metrics
    var heartRate: Int?
    var paceMetersPerSecond: Double?
    var cadenceStepsPerMinute: Int?
    
    // Location
    var latitude: Double?
    var longitude: Double?
    var altitude: Double?
    var horizontalAccuracy: Double?
    
    init(workoutID: UUID, 
         timestamp: Date, 
         elapsedSeconds: Double, 
         heartRate: Int? = nil, 
         paceMetersPerSecond: Double? = nil, 
         cadenceStepsPerMinute: Int? = nil,
         latitude: Double? = nil,
         longitude: Double? = nil,
         altitude: Double? = nil,
         horizontalAccuracy: Double? = nil) {
        self.id = UUID()
        self.workoutID = workoutID
        self.timestamp = timestamp
        self.elapsedSeconds = elapsedSeconds
        self.heartRate = heartRate
        self.paceMetersPerSecond = paceMetersPerSecond
        self.cadenceStepsPerMinute = cadenceStepsPerMinute
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.horizontalAccuracy = horizontalAccuracy
    }
    
    // Convert pace to minutes per km
    var paceMinutesPerKm: Double? {
        guard let pace = paceMetersPerSecond, pace > 0 else { return nil }
        return (1000.0 / pace) / 60.0 // Convert m/s to min/km
    }
    
    // Convert pace to minutes per mile
    var paceMinutesPerMile: Double? {
        guard let pace = paceMetersPerSecond, pace > 0 else { return nil }
        return (1609.34 / pace) / 60.0 // Convert m/s to min/mile
    }
    
    // Create a CLLocation from the stored coordinates
    var location: CLLocation? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
            altitude: altitude ?? 0,
            horizontalAccuracy: horizontalAccuracy ?? -1,
            verticalAccuracy: -1,
            timestamp: timestamp
        )
    }
} 