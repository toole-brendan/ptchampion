import Foundation
import CoreLocation
import Combine

// MARK: - Protocol (REMOVE - Defined in LocationServiceProtocol.swift)
/*
protocol LocationServiceProtocol {
    var authorizationStatusPublisher: AnyPublisher<CLAuthorizationStatus, Never> { get }
    var locationPublisher: AnyPublisher<CLLocation?, Never> { get }
    var errorPublisher: AnyPublisher<Error, Never> { get }

    func requestLocationPermission()
    func startUpdatingLocation()
    func stopUpdatingLocation()
    func isLocationAuthorized() -> Bool
}
*/

// MARK: - Location Service Implementation
class LocationService: NSObject, LocationServiceProtocol, CLLocationManagerDelegate {

    private let locationManager = CLLocationManager()
    // Continuations are used for async/await wrappers if needed, but Combine publishers are primary here
    private var statusContinuation: CheckedContinuation<CLAuthorizationStatus, Never>?
    private var locationContinuation: CheckedContinuation<CLLocation?, Error>?

    // Combine Subjects for publishing updates
    private let authorizationStatusSubject: CurrentValueSubject<CLAuthorizationStatus, Never>
    private let locationSubject = CurrentValueSubject<CLLocation?, Never>(nil)
    private let errorSubject = PassthroughSubject<Error, Never>()

    // Public Combine Publishers
    var authorizationStatusPublisher: AnyPublisher<CLAuthorizationStatus, Never> {
        authorizationStatusSubject.eraseToAnyPublisher()
    }
    var locationPublisher: AnyPublisher<CLLocation?, Never> {
        locationSubject.eraseToAnyPublisher()
    }
    var errorPublisher: AnyPublisher<Error, Never> {
        errorSubject.eraseToAnyPublisher()
    }

    override init() {
        // Initialize subject with the *current* status before setting delegate
        authorizationStatusSubject = CurrentValueSubject(locationManager.authorizationStatus)
        super.init()
        locationManager.delegate = self
        // Set desired accuracy - adjust as needed for battery vs precision
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters // Good balance for local area
        print("LocationService initialized. Current status: \(locationManager.authorizationStatus.rawValue)")
    }

    // MARK: - Protocol Implementation

    func getCurrentAuthorizationStatus() -> CLAuthorizationStatus {
        return locationManager.authorizationStatus
    }


    func requestLocationPermission() {
        let currentStatus = locationManager.authorizationStatus
        authorizationStatusSubject.send(currentStatus) // Ensure the publisher reflects the current state

        if currentStatus == .notDetermined {
            print("LocationService: Requesting When In Use authorization.")
            // Request permission asynchronously. The delegate method will handle the result.
            locationManager.requestWhenInUseAuthorization()
        } else if currentStatus == .denied || currentStatus == .restricted {
            print("LocationService: Permission previously denied or restricted.")
            // Publish error for subscribers
            errorSubject.send(LocationError.permissionDenied)
        } else if currentStatus == .authorizedWhenInUse || currentStatus == .authorizedAlways {
             print("LocationService: Permission already granted (\(currentStatus.rawValue)).")
             // No need to request again, could potentially trigger an update if desired
             // requestLocationUpdate() // Optional: Trigger update if permission already granted
        }
    }


    func getLastKnownLocation() async -> CLLocation? {
        // Note: locationManager.location might be stale or nil if updates haven't run recently
        let lastLocation = locationManager.location
        print("LocationService: Providing last known location: \(lastLocation?.coordinate.latitude ?? 0), \(lastLocation?.coordinate.longitude ?? 0)")
        locationSubject.send(lastLocation) // Publish the last known location
        return lastLocation
    }


    func requestLocationUpdate() {
        let currentStatus = locationManager.authorizationStatus
        guard currentStatus == .authorizedWhenInUse || currentStatus == .authorizedAlways else {
            print("LocationService: Cannot request location update, not authorized. Status: \(currentStatus.rawValue)")
             if currentStatus == .notDetermined {
                 print("LocationService: Permission not determined, requesting...")
                 requestLocationPermission() // Request permission first
             } else {
                 // Denied or restricted
                 errorSubject.send(LocationError.permissionDenied)
             }
            return
        }
        print("LocationService: Requesting a single location update.")
       // Use requestLocation for a single update (more battery efficient than startUpdatingLocation)
       // The delegate methods (didUpdateLocations or didFailWithError) will handle the result.
       locationManager.requestLocation()
    }

    // Start continuous location updates
    func startUpdatingLocation() {
        let currentStatus = locationManager.authorizationStatus
        guard currentStatus == .authorizedWhenInUse || currentStatus == .authorizedAlways else {
            print("LocationService: Cannot start location updates, not authorized. Status: \(currentStatus.rawValue)")
            if currentStatus == .notDetermined {
                print("LocationService: Permission not determined, requesting...")
                requestLocationPermission() // Request permission first
            } else {
                // Denied or restricted
                errorSubject.send(LocationError.permissionDenied)
            }
            return
        }
        
        print("LocationService: Starting continuous location updates.")
        locationManager.startUpdatingLocation()
    }
    
    // Stop continuous location updates
    func stopUpdatingLocation() {
        print("LocationService: Stopping continuous location updates.")
        locationManager.stopUpdatingLocation()
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let newStatus = manager.authorizationStatus
        print("LocationService: Delegate - Authorization status changed to \(newStatus.rawValue)")
        authorizationStatusSubject.send(newStatus) // Publish the new status

        // Handle continuation if an async wrapper was waiting for the status change
        statusContinuation?.resume(returning: newStatus)
        statusContinuation = nil // Reset continuation

        if newStatus == .denied || newStatus == .restricted {
            errorSubject.send(LocationError.permissionDenied) // Publish error on denial
        } else if newStatus == .authorizedWhenInUse || newStatus == .authorizedAlways {
            // Optional: Automatically request location once authorized
             print("LocationService: Delegate - Authorized. Requesting initial location.")
             // requestLocationUpdate() // Be mindful of triggering too many updates
        }
    }


    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latestLocation = locations.last else {
            print("LocationService: Delegate - Received empty locations array.")
            return
        }
        print("LocationService: Delegate - Received location update: \(latestLocation.coordinate.latitude), \(latestLocation.coordinate.longitude)")
        locationSubject.send(latestLocation) // Publish the new location

        // Handle continuation if an async wrapper was waiting
        locationContinuation?.resume(returning: latestLocation)
        locationContinuation = nil
    }


    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("LocationService: Delegate - Failed with error: \(error.localizedDescription)")

        let locationError: LocationError
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                locationError = .permissionDenied
                authorizationStatusSubject.send(.denied) // Ensure status reflects denial
            case .locationUnknown:
                // Often transient, might not be a fatal error for the service itself
                print("LocationService: Delegate - CLError locationUnknown. May resolve on next attempt.")
                locationError = .locationUnavailable // Map to our custom error
            case .network:
                 print("LocationService: Delegate - CLError network. Check connectivity.")
                 locationError = .locationUnavailable // Or a more specific network error if needed
            default:
                locationError = .unknownError(error)
            }
        } else {
            locationError = .unknownError(error)
        }

        errorSubject.send(locationError) // Publish the error

        // Handle continuation if an async wrapper was waiting
        locationContinuation?.resume(throwing: locationError)
        locationContinuation = nil
    }


    deinit {
        print("LocationService deinitialized.")
        // No need to stop location updates if using requestLocation(), but good practice if using startUpdatingLocation()
        // locationManager.stopUpdatingLocation()
    }
} 