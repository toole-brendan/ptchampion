import Foundation
import CoreLocation
import Combine

// Protocol for location services
protocol LocationServiceProtocol {
    var authorizationStatusPublisher: AnyPublisher<CLAuthorizationStatus, Never> { get }
    var locationPublisher: AnyPublisher<CLLocation?, Never> { get } // Publishes last known or updated location
    var errorPublisher: AnyPublisher<Error, Never> { get }

    func requestLocationPermission()
    func getLastKnownLocation() async -> CLLocation?
    func requestLocationUpdate() // One-time location request
    // Add these methods for continuous updates
    func startUpdatingLocation()
    func stopUpdatingLocation()
    
    // New method to get current location with error handling
    func getCurrentLocation() async -> CLLocation?
    
    // Get the current authorization status without waiting for a publisher
    func getCurrentAuthorizationStatus() -> CLAuthorizationStatus
}

// Custom errors
enum LocationError: Error, LocalizedError {
    case permissionDenied
    case locationUnavailable
    case restricted
    case unknownError(Error?)

    var errorDescription: String? {
        switch self {
        case .permissionDenied: return "Location access was denied. Please enable it in Settings."
        case .locationUnavailable: return "Could not determine current location."
        case .restricted: return "Location access is restricted on this device."
        case .unknownError(let err): return "An unknown location error occurred: \(err?.localizedDescription ?? "N/A")"
        }
    }
} 