import Foundation

// Enum for different types of exercises tracked
// Aligned with backend schema keys
enum ExerciseType: String, Codable, CaseIterable {
    case pushup = "pushup" // Use schema keys as raw values
    case situp = "situp"
    case pullup = "pullup"
    case run = "run"
    case unknown = "unknown" // For safety

    // Keep initializer if needed, but rawValue is now the key
    init(key: String) {
        self = ExerciseType(rawValue: key) ?? .unknown
    }
    
    // Computed property for display name if needed in UI
    var displayName: String {
        switch self {
        case .pushup: return "Push-ups"
        case .situp: return "Sit-ups"
        case .pullup: return "Pull-ups"
        case .run: return "Run"
        case .unknown: return "Unknown"
        }
    }
}

// Represents an exercise definition (Aligned with schema.ts Exercise)
struct Exercise: Codable, Identifiable {
    let id: Int
    let name: String
    let description: String?
    let type: String // Raw value like "pushup", "run"

    // No CodingKeys needed if property names match schema columns
}

// Represents the data to be saved for a completed workout session
// Aligned with schema.ts InsertUserExercise
struct InsertUserExerciseRequest: Codable {
    let userId: Int
    let exerciseId: Int
    let repetitions: Int?
    let formScore: Int? // 0-100
    let timeInSeconds: Int?
    let grade: Int? // 0-100
    let completed: Bool?
    let metadata: String? // JSON string
    let deviceId: String?
    let syncStatus: String? // synced, pending, conflict

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case exerciseId = "exercise_id"
        case repetitions
        case formScore = "form_score"
        case timeInSeconds = "time_in_seconds"
        case grade
        case completed
        case metadata
        case deviceId = "device_id"
        case syncStatus = "sync_status"
    }
}

// Represents a workout record fetched from the backend (e.g., for history)
// Aligned with schema.ts UserExercise
struct UserExerciseRecord: Codable, Identifiable {
    let id: Int
    let userId: Int
    let exerciseId: Int
    let repetitions: Int?
    let formScore: Int? // 0-100
    let timeInSeconds: Int?
    let grade: Int? // 0-100
    let completed: Bool?
    let metadata: String? // JSON string
    let deviceId: String?
    let syncStatus: String?
    let createdAt: Date // Assuming non-optional based on schema default
    let updatedAt: Date // Assuming non-optional based on schema default
    
    // Computed property to get ExerciseType enum
    var exerciseTypeKey: String {
        // This relies on having the Exercise definitions available
        // or assuming the backend includes the type key directly
        // If backend includes type key:
         return metadata?.extractExerciseTypeKey() ?? "unknown"
        // If not, we'd need to fetch Exercises separately and match by exerciseId
    }

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
        case deviceId = "device_id"
        case syncStatus = "sync_status"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// Helper extension (optional) to extract type from metadata if stored there
// This is just an example, adapt based on actual metadata structure
extension String {
    func extractExerciseTypeKey() -> String? {
        // Example: Assuming metadata is JSON like {"type": "pushup", ...}
        guard let data = self.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else {
            return nil
        }
        return type
    }
}


// Structure for paginated workout history response
// Mirroring Android's PaginatedWorkoutsResponseDto structure
struct PaginatedUserExerciseResponse: Codable {
    let items: [UserExerciseRecord] // The list of workout records for the current page
    let totalItems: Int           // Total number of records available
    let totalPages: Int           // Total number of pages
    let currentPage: Int          // The current page number
    // Add other pagination fields if the API provides them (e.g., pageSize)

    enum CodingKeys: String, CodingKey {
        case items
        case totalItems = "total_items" // Adjust key based on actual API response
        case totalPages = "total_pages"
        case currentPage = "current_page"
    }
} 