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
    
    var description: String {
        switch self {
        case .pushup:
            return "Upper body exercise to build chest, shoulder, and arm strength."
        case .situp:
            return "Core exercise to strengthen abdominal muscles and improve posture."
        case .pullup:
            return "Upper body exercise targeting back, shoulders, and arms."
        case .run:
            return "Cardio exercise measuring endurance and aerobic fitness."
        }
    }
}

struct Exercise: Codable, Identifiable {
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
        case imageUrl = "image_url"
    }
    
    // Returns goal for each exercise type
    var goal: String {
        switch type {
        case .pushup:
            return "Goal: 60 reps for max score"
        case .situp:
            return "Goal: 78 reps for max score"
        case .pullup:
            return "Goal: 20 reps for max score"
        case .run:
            return "Goal: 13:00 (min:sec) for max score"
        }
    }
    
    // Returns instruction for how to perform the exercise
    var instructions: [String] {
        switch type {
        case .pushup:
            return [
                "Start in a plank position with arms straight",
                "Lower your body until elbows reach 90 degrees",
                "Push back up to the starting position",
                "Keep your back straight throughout the movement"
            ]
        case .situp:
            return [
                "Lie on your back with knees bent",
                "Cross arms over chest or place hands behind ears",
                "Curl upper body toward knees",
                "Lower back down in a controlled motion"
            ]
        case .pullup:
            return [
                "Grip the bar with palms facing away from you",
                "Hang with arms fully extended",
                "Pull up until chin is above the bar",
                "Lower down with control to starting position"
            ]
        case .run:
            return [
                "Run 2 miles (3.2 km) as quickly as possible",
                "Pace yourself throughout the distance",
                "Track time with the app's timer",
                "Can be done on a track, treadmill or outdoor course"
            ]
        }
    }
}