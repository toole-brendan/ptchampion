import Foundation
import SwiftUI

// Uncomment DistanceUnit for RunWorkoutViewModel
/* Commenting out to avoid duplicate declaration - already defined in RunWorkoutViewModel.swift
enum DistanceUnit: String, CaseIterable, Identifiable {
    case kilometers = "km"
    case miles = "mi"

    var id: String { self.rawValue }

    var displayName: String {
        switch self {
        case .kilometers: return "Kilometers"
        case .miles: return "Miles"
        }
    }
}
*/

// Potential future enums can go here
// Example:
enum AppTab {
    case dashboard, workout, history, leaderboards, settings
}

// Workout filter for the workout history screen
enum WorkoutFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case pushup = "Push-Ups"
    case situp = "Sit-Ups"
    case pullup = "Pull-Ups"
    case run = "Run"
    
    var id: String { self.rawValue }
    
    var systemImage: String {
        switch self {
        case .all: return "figure.run.circle.fill"
        case .pushup: return "figure.strengthtraining.traditional"
        case .situp: return "figure.core.training"
        case .pullup: return "figure.strengthtraining.traditional"
        case .run: return "figure.run"
        }
    }
    
    // Custom icon names for exercise types
    var customIconName: String? {
        switch self {
        case .pushup: return "pushup"
        case .situp: return "situp"
        case .pullup: return "pullup"
        case .run: return "running"
        default: return nil
        }
    }
    
    // Convert to exercise type string used in database
    var exerciseTypeString: String? {
        switch self {
        case .all: return nil
        case .pushup: return "pushup"
        case .situp: return "situp"
        case .pullup: return "pullup"
        case .run: return "run"
        }
    }
} 