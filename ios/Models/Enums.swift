import Foundation

// Enum for different types of exercises
enum ExerciseType: String, CaseIterable, Identifiable {
    case pushups = "Push-ups"
    case situps = "Sit-ups"
    case pullups = "Pull-ups"
    case run = "Run"
    // Add other exercises as needed

    var id: String { self.rawValue }

    // Display name (could be same as raw value or customized)
    var displayName: String {
        self.rawValue
    }

    // Associated system icon name for UI
    var iconName: String {
        switch self {
        case .pushups: return "figure.strengthtraining.traditional"
        case .situps: return "figure.core.training"
        case .pullups: return "figure.pullups" // Placeholder, might need custom
        case .run: return "figure.run"
        }
    }
}

// Enum for distance units preference
enum DistanceUnit: String, CaseIterable, Identifiable {
    case miles = "Miles"
    case kilometers = "Kilometers"

    var id: String { self.rawValue }
} 