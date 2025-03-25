import Foundation

struct Exercise: Codable, Identifiable {
    let id: Int
    let name: String
    let description: String?
    let type: ExerciseType
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case type
    }
}

enum ExerciseType: String, Codable {
    case pushup
    case pullup
    case situp
    case run
    
    var displayName: String {
        switch self {
        case .pushup:
            return "Push-ups"
        case .pullup:
            return "Pull-ups"
        case .situp:
            return "Sit-ups"
        case .run:
            return "2-mile Run"
        }
    }
    
    var description: String {
        switch self {
        case .pushup:
            return "Upper body exercise performed in a prone position, raising and lowering the body using the arms"
        case .pullup:
            return "Upper body exercise where you hang from a bar and pull your body up until your chin is above the bar"
        case .situp:
            return "Abdominal exercise performed by lying on your back and lifting your torso"
        case .run:
            return "Cardio exercise measuring endurance over a 2-mile distance"
        }
    }
}