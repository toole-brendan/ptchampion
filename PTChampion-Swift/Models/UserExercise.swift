import Foundation

struct UserExercise: Identifiable, Codable {
    let id: Int
    let userId: Int
    let exerciseId: Int
    let repetitions: Int?
    let formScore: Int?
    let timeInSeconds: Int?
    let grade: Int?
    let completed: Bool
    let metadata: [String: String]?
    let deviceId: String?
    let syncStatus: String?
    let createdAt: Date
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case exerciseId
        case repetitions
        case formScore
        case timeInSeconds
        case grade
        case completed
        case metadata
        case deviceId
        case syncStatus
        case createdAt
        case updatedAt
    }
    
    init(id: Int, userId: Int, exerciseId: Int, 
         repetitions: Int? = nil, formScore: Int? = nil, 
         timeInSeconds: Int? = nil, grade: Int? = nil, 
         completed: Bool, metadata: [String: String]? = nil, 
         deviceId: String? = nil, syncStatus: String? = nil,
         createdAt: Date = Date(), updatedAt: Date? = nil) {
        self.id = id
        self.userId = userId
        self.exerciseId = exerciseId
        self.repetitions = repetitions
        self.formScore = formScore
        self.timeInSeconds = timeInSeconds
        self.grade = grade
        self.completed = completed
        self.metadata = metadata
        self.deviceId = deviceId
        self.syncStatus = syncStatus
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

extension UserExercise {
    func formattedResult(for exerciseType: ExerciseType) -> String {
        switch exerciseType {
        case .pushup, .situp, .pullup:
            if let reps = repetitions {
                return "\(reps) reps"
            }
            return "N/A"
        case .run:
            if let seconds = timeInSeconds {
                let minutes = seconds / 60
                let remainingSeconds = seconds % 60
                return "\(minutes):\(String(format: "%02d", remainingSeconds))"
            }
            return "N/A"
        }
    }
    
    func scoreColor() -> UIColor {
        guard let grade = grade else { return .systemGray }
        
        switch grade {
        case 90...100:
            return .systemGreen
        case 75..<90:
            return .systemBlue
        case 60..<75:
            return .systemOrange
        case 40..<60:
            return .systemYellow
        default:
            return .systemRed
        }
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }
    
    var formattedTimeElapsed: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day, .hour, .minute]
        formatter.unitsStyle = .abbreviated
        formatter.maximumUnitCount = 2
        
        let interval = Date().timeIntervalSince(createdAt)
        return formatter.string(from: interval) ?? "Unknown"
    }
}

import UIKit // Added for UIColor reference