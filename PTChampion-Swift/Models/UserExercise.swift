import Foundation

struct UserExercise: Codable, Identifiable {
    let id: Int
    let userId: Int
    let exerciseId: Int
    var repetitions: Int?
    var formScore: Int?
    var timeInSeconds: Int?
    var grade: Int?
    var completed: Bool
    var metadata: String?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case exerciseId = "exercise_id"
        case repetitions
        case formScore = "form_score"
        case timeInSeconds = "time_in_seconds"
        case grade
        case completed
        case metadata
        case createdAt = "created_at"
    }
}

// Used for creating a new user exercise record
struct UserExerciseSubmission: Codable {
    let exerciseId: Int
    var repetitions: Int?
    var formScore: Int?
    var timeInSeconds: Int?
    var grade: Int?
    var completed: Bool
    var metadata: String?
    
    enum CodingKeys: String, CodingKey {
        case exerciseId = "exerciseId"
        case repetitions
        case formScore
        case timeInSeconds
        case grade
        case completed
        case metadata
    }
}

// Combined model for detailed exercise results
struct ExerciseResult: Identifiable {
    let id: Int
    let exercise: Exercise
    let userExercise: UserExercise
    
    var displayScore: String {
        switch exercise.type {
        case .pushup, .pullup, .situp:
            return "\(userExercise.repetitions ?? 0) reps"
        case .run:
            if let seconds = userExercise.timeInSeconds {
                let minutes = seconds / 60
                let remainingSeconds = seconds % 60
                return "\(minutes):\(String(format: "%02d", remainingSeconds))"
            }
            return "N/A"
        }
    }
    
    var displayGrade: String {
        if let grade = userExercise.grade {
            return "\(grade)/100"
        }
        return "Not graded"
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: userExercise.createdAt)
    }
}

// For leaderboard entries
struct LeaderboardEntry: Identifiable {
    let id: Int
    let username: String
    let overallScore: Int
    let runTime: String?
    let pushupReps: Int?
    let situpReps: Int?
    let pullupReps: Int?
    let distance: Double?
}