import Foundation
import CoreLocation
import SwiftUI

// User model
struct User: Identifiable, Codable {
    var id: Int
    var username: String
    var password: String? // Only used for creation, not stored in memory after authentication
    var location: String?
    var latitude: Double?
    var longitude: Double?
    var createdAt: Date?
    
    // Calculated property for whether location data is available
    var hasLocation: Bool {
        return latitude != nil && longitude != nil
    }
}

// Exercise model
struct Exercise: Identifiable, Codable {
    var id: Int
    var name: String
    var description: String?
    var type: ExerciseType
    
    enum ExerciseType: String, Codable {
        case pushup = "pushup"
        case pullup = "pullup"
        case situp = "situp"
        case run = "run"
        
        var displayName: String {
            switch self {
            case .pushup: return "Push-ups"
            case .pullup: return "Pull-ups"
            case .situp: return "Sit-ups"
            case .run: return "2-mile Run"
            }
        }
        
        var iconName: String {
            switch self {
            case .pushup: return "figure.strengthtraining.traditional"
            case .pullup: return "figure.gymnastics"
            case .situp: return "figure.play"
            case .run: return "figure.run"
            }
        }
    }
}

// User Exercise model - records a user's exercise performance
struct UserExercise: Identifiable, Codable {
    var id: Int
    var userId: Int
    var exerciseId: Int
    var repetitions: Int?
    var formScore: Int?
    var timeInSeconds: Int?
    var grade: Int?
    var completed: Bool
    var metadata: String?
    var createdAt: Date?
    
    // Helper computed property to format result based on exercise type
    func formattedResult(for exerciseType: Exercise.ExerciseType) -> String {
        switch exerciseType {
        case .pushup, .pullup, .situp:
            return "\(repetitions ?? 0) reps"
        case .run:
            if let time = timeInSeconds {
                let minutes = time / 60
                let seconds = time % 60
                return String(format: "%d:%02d", minutes, seconds)
            } else {
                return "No time"
            }
        }
    }
    
    // Helper to get the score rating based on grade
    var scoreRating: String {
        guard let grade = grade else { return "Not rated" }
        
        if grade >= 90 {
            return "Excellent"
        } else if grade >= 80 {
            return "Good"
        } else if grade >= 65 {
            return "Satisfactory"
        } else if grade >= 50 {
            return "Marginal"
        } else {
            return "Poor"
        }
    }
    
    // Color for the score
    var scoreColor: Color {
        guard let grade = grade else { return .gray }
        
        if grade >= 90 {
            return .green
        } else if grade >= 80 {
            return .blue
        } else if grade >= 65 {
            return .yellow
        } else if grade >= 50 {
            return .orange
        } else {
            return .red
        }
    }
}

// Leaderboard entry
struct LeaderboardEntry: Identifiable, Codable {
    var id: Int
    var username: String
    var overallScore: Int
    var pushupScore: Int?
    var situpScore: Int?
    var pullupScore: Int?
    var runScore: Int?
    var distance: Double? // Only for local leaderboard, distance in miles from user
    
    var formattedDistance: String? {
        guard let distance = distance else { return nil }
        
        if distance < 0.1 {
            return "< 0.1 miles"
        } else {
            return String(format: "%.1f miles", distance)
        }
    }
}

// PoseData for computer vision - represents body keypoints
struct PoseData: Codable {
    struct Keypoint: Codable {
        var position: Position
        var part: String
        var score: Double
        
        struct Position: Codable {
            var x: Double
            var y: Double
        }
    }
    
    var keypoints: [Keypoint]
}

// Exercise state for tracking form and counting reps
protocol ExerciseState {
    var isUp: Bool { get set }
    var isDown: Bool { get set }
    var count: Int { get set }
    var formScore: Int { get set }
    var feedback: String { get set }
}

struct PushupState: ExerciseState {
    var isUp: Bool = false
    var isDown: Bool = false
    var count: Int = 0
    var formScore: Int = 0
    var feedback: String = "Position yourself in frame"
}

struct PullupState: ExerciseState {
    var isUp: Bool = false
    var isDown: Bool = false
    var count: Int = 0
    var formScore: Int = 0
    var feedback: String = "Position yourself in frame"
}

struct SitupState: ExerciseState {
    var isUp: Bool = false
    var isDown: Bool = false
    var count: Int = 0
    var formScore: Int = 0
    var feedback: String = "Position yourself in frame"
}

// Bluetooth Device data
struct BluetoothDevice: Identifiable {
    var id: String
    var name: String
    var connected: Bool
    var heartRate: Int?
}

// Bluetooth Service data for run tracking
struct BluetoothServiceData {
    var heartRate: Int?
    var steps: Int?
    var distance: Double?  // in miles
    var timeElapsed: Int?  // in seconds
    var speed: Double?     // in mph
}