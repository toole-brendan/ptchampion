import Foundation
import SwiftUI

// REMOVE ExerciseType - Should be defined ONLY in WorkoutModels.swift
/*
enum ExerciseType: String, CaseIterable, Identifiable {
    case pushup = "Push-ups"
    case situp = "Sit-ups"
    case pullup = "Pull-ups"
    case run = "Run"

    var id: String { self.rawValue }
}
*/

// REMOVE DistanceUnit - Should be defined elsewhere (e.g. Theme.swift or Units.swift)
/*
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