import Foundation

enum ExerciseType: String, Codable, CaseIterable {
    case pushup = "pushup"
    case situp = "situp"
    case pullup = "pullup"
    case run = "run"
    
    var displayName: String {
        switch self {
        case .pushup: return "Push-ups"
        case .situp: return "Sit-ups"
        case .pullup: return "Pull-ups"
        case .run: return "2-Mile Run"
        }
    }
    
    var iconName: String {
        switch self {
        case .pushup: return "figure.strengthtraining.traditional"
        case .situp: return "figure.core.training"
        case .pullup: return "figure.highintensity.intervaltraining"
        case .run: return "figure.run"
        }
    }
    
    var goal: String {
        switch self {
        case .pushup: return "Max reps in 2 minutes"
        case .situp: return "Max reps in 2 minutes"
        case .pullup: return "Max reps"
        case .run: return "Fastest time for 2 miles"
        }
    }
}

struct Exercise: Identifiable, Codable {
    let id: Int
    let name: String
    let description: String
    let type: ExerciseType
    let imageUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case type
        case imageUrl = "imageUrl"
    }
}

extension Exercise {
    // Helper method to get example data
    static func examples() -> [Exercise] {
        return [
            Exercise(
                id: 1,
                name: "Push-ups",
                description: "Upper body exercise to build chest, shoulder, and arm strength.",
                type: .pushup,
                imageUrl: nil
            ),
            Exercise(
                id: 2,
                name: "Sit-ups",
                description: "Core exercise focusing on abdominal muscles and hip flexors.",
                type: .situp,
                imageUrl: nil
            ),
            Exercise(
                id: 3,
                name: "Pull-ups",
                description: "Upper body exercise that targets the back, shoulders, and arms.",
                type: .pullup,
                imageUrl: nil
            ),
            Exercise(
                id: 4,
                name: "2-Mile Run",
                description: "Cardio exercise measuring endurance and aerobic fitness.",
                type: .run,
                imageUrl: nil
            )
        ]
    }
}