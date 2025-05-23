// ios/ptchampion/ViewModels/WorkoutSessionViewModel+Calibration.swift

import Foundation
import SwiftUI
import Combine

extension WorkoutSessionViewModel {
    
    // MARK: - Calibration Properties
    var needsCalibration: Bool {
        // We need calibration only if:
        // 1. We've already checked for saved calibration data
        // 2. AND we still don't have calibration data
        return hasCheckedCalibration && calibrationData == nil
    }
    
    // MARK: - Calibration Methods
    func checkCalibrationStatus() async {
        print("DEBUG: [WorkoutSessionViewModel] Checking calibration status for \(exerciseType.displayName)")
        
        // Check if we already have calibration data
        if calibrationData != nil {
            print("DEBUG: [WorkoutSessionViewModel] Calibration already loaded")
            hasCheckedCalibration = true
            return
        }
        
        // Try to load saved calibration
        if let repository = calibrationRepository {
            calibrationData = await repository.getBestCalibration(for: exerciseType)
            
            if let calibration = calibrationData {
                print("DEBUG: [WorkoutSessionViewModel] Loaded calibration with score: \(calibration.calibrationScore)")
                applyCalibrationData(calibration)
            } else {
                print("DEBUG: [WorkoutSessionViewModel] No calibration found for \(exerciseType.displayName)")
            }
        }
        
        hasCheckedCalibration = true
    }
    
    func applyCalibrationData(_ calibration: CalibrationData) {
        print("DEBUG: [WorkoutSessionViewModel] Applying calibration data")
        
        // Apply calibration to real-time feedback manager
        realTimeFeedbackManager.startFeedback(for: exerciseType, with: calibration)
        
        // Update grader with calibration data if supported
        if let calibratableGrader = exerciseGrader as? CalibratableExerciseGrader {
            calibratableGrader.applyCalibration(calibration)
        }
        
        // Store calibration quality for UI display
        calibrationQuality = evaluateCalibrationQuality(calibration)
    }
    
    private func evaluateCalibrationQuality(_ calibration: CalibrationData) -> CalibrationQuality {
        switch calibration.calibrationScore {
        case 90...100: return .excellent
        case 80..<90: return .good
        case 70..<80: return .acceptable
        case 60..<70: return .poor
        default: return .invalid
        }
    }
    
    func handleCalibrationComplete(_ calibrationData: CalibrationData) {
        print("DEBUG: [WorkoutSessionViewModel] Calibration completed with score: \(calibrationData.calibrationScore)")
        
        self.calibrationData = calibrationData
        applyCalibrationData(calibrationData)
        
        // Dismiss calibration view
        showCalibrationView = false
        
        // Update state to ready
        DispatchQueue.main.async {
            self.workoutState = .ready
            self.feedbackMessage = "Calibration complete! Ready to begin."
        }
    }
    
    func skipCalibration() {
        print("DEBUG: [WorkoutSessionViewModel] User skipped calibration")
        
        hasCheckedCalibration = true
        showCalibrationView = false
        
        // Update state to ready without calibration
        DispatchQueue.main.async {
            self.workoutState = .ready
            self.feedbackMessage = "Ready to begin (uncalibrated)."
        }
    }
}

// MARK: - Calibratable Grader Protocol
protocol CalibratableExerciseGrader {
    func applyCalibration(_ calibration: CalibrationData)
}
