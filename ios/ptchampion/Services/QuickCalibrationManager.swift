import Foundation
import Vision
import AVFoundation
import UIKit

public class QuickCalibrationManager: ObservableObject {
    
    // MARK: - Simple Properties
    @Published var isCalibrated = false
    @Published var deviceOrientation: UIDeviceOrientation = .portrait
    @Published var estimatedUserHeight: Double = 170.0 // cm, with smart defaults
    
    // Camera reference
    weak var cameraService: CameraService?
    
    // Simple calibration data per exercise
    private var calibrationProfiles: [ExerciseType: SimpleCalibrationProfile] = [:]
    
    // MARK: - Simplified Calibration Profile
    public struct SimpleCalibrationProfile {
        let exerciseType: ExerciseType
        let deviceOrientation: UIDeviceOrientation
        let optimalDistance: Double // meters
        let frameGuideInsets: UIEdgeInsets // for positioning guides
        let created: Date
        
        // Pre-calculated values based on typical setups
        static func defaultProfile(for exercise: ExerciseType, orientation: UIDeviceOrientation) -> SimpleCalibrationProfile {
            switch (exercise, orientation.isLandscape) {
            case (.pushup, true):
                return SimpleCalibrationProfile(
                    exerciseType: exercise,
                    deviceOrientation: orientation,
                    optimalDistance: 2.5,
                    frameGuideInsets: UIEdgeInsets(top: 50, left: 100, bottom: 50, right: 100),
                    created: Date()
                )
            case (.pushup, false):
                return SimpleCalibrationProfile(
                    exerciseType: exercise,
                    deviceOrientation: orientation,
                    optimalDistance: 3.0,
                    frameGuideInsets: UIEdgeInsets(top: 80, left: 60, bottom: 80, right: 60),
                    created: Date()
                )
            case (.situp, true):
                return SimpleCalibrationProfile(
                    exerciseType: exercise,
                    deviceOrientation: orientation,
                    optimalDistance: 2.8,
                    frameGuideInsets: UIEdgeInsets(top: 60, left: 120, bottom: 60, right: 120),
                    created: Date()
                )
            case (.situp, false):
                return SimpleCalibrationProfile(
                    exerciseType: exercise,
                    deviceOrientation: orientation,
                    optimalDistance: 3.2,
                    frameGuideInsets: UIEdgeInsets(top: 100, left: 80, bottom: 100, right: 80),
                    created: Date()
                )
            case (.pullup, true):
                return SimpleCalibrationProfile(
                    exerciseType: exercise,
                    deviceOrientation: orientation,
                    optimalDistance: 3.5,
                    frameGuideInsets: UIEdgeInsets(top: 40, left: 80, bottom: 80, right: 80),
                    created: Date()
                )
            case (.pullup, false):
                return SimpleCalibrationProfile(
                    exerciseType: exercise,
                    deviceOrientation: orientation,
                    optimalDistance: 4.0,
                    frameGuideInsets: UIEdgeInsets(top: 60, left: 60, bottom: 120, right: 60),
                    created: Date()
                )
            default:
                return SimpleCalibrationProfile(
                    exerciseType: exercise,
                    deviceOrientation: orientation,
                    optimalDistance: 2.5,
                    frameGuideInsets: UIEdgeInsets(top: 60, left: 80, bottom: 60, right: 80),
                    created: Date()
                )
            }
        }
    }
    
    // MARK: - Quick Setup
    func quickSetup(for exercise: ExerciseType) {
        deviceOrientation = UIDevice.current.orientation
        let profile = SimpleCalibrationProfile.defaultProfile(for: exercise, orientation: deviceOrientation)
        calibrationProfiles[exercise] = profile
        isCalibrated = true
        
        print("Quick calibration setup completed for \(exercise.displayName) in \(deviceOrientation.isLandscape ? "landscape" : "portrait") mode")
    }
    
    // MARK: - Get Current Profile
    func getCurrentProfile(for exercise: ExerciseType) -> SimpleCalibrationProfile {
        return calibrationProfiles[exercise] ?? SimpleCalibrationProfile.defaultProfile(for: exercise, orientation: deviceOrientation)
    }
    
    // MARK: - Update for Orientation Change
    func updateForOrientationChange(exercise: ExerciseType) {
        let newOrientation = UIDevice.current.orientation
        guard newOrientation != deviceOrientation else { return }
        
        deviceOrientation = newOrientation
        let profile = SimpleCalibrationProfile.defaultProfile(for: exercise, orientation: newOrientation)
        calibrationProfiles[exercise] = profile
        
        print("Updated calibration profile for orientation change: \(newOrientation.isLandscape ? "landscape" : "portrait")")
    }
    
    // MARK: - Reset
    func reset() {
        calibrationProfiles.removeAll()
        isCalibrated = false
        print("Quick calibration manager reset")
    }
    
    // MARK: - Validation Helpers
    func getOptimalDistance(for exercise: ExerciseType) -> Double {
        return getCurrentProfile(for: exercise).optimalDistance
    }
    
    func getFrameGuideInsets(for exercise: ExerciseType) -> UIEdgeInsets {
        return getCurrentProfile(for: exercise).frameGuideInsets
    }
    
    // MARK: - Smart Defaults Based on Device
    private func getDeviceSpecificDefaults() -> (distance: Double, insets: UIEdgeInsets) {
        let screenSize = UIScreen.main.bounds.size
        let isLargeDevice = max(screenSize.width, screenSize.height) > 800
        
        if isLargeDevice {
            // iPad or large iPhone
            return (
                distance: 3.5,
                insets: UIEdgeInsets(top: 100, left: 120, bottom: 100, right: 120)
            )
        } else {
            // Standard iPhone
            return (
                distance: 2.8,
                insets: UIEdgeInsets(top: 80, left: 80, bottom: 80, right: 80)
            )
        }
    }
}

// MARK: - UIDeviceOrientation Extension
extension UIDeviceOrientation {
    var isLandscape: Bool {
        return self == .landscapeLeft || self == .landscapeRight
    }
    
    var isPortrait: Bool {
        return self == .portrait || self == .portraitUpsideDown
    }
} 