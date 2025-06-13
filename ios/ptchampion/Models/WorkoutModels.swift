import Foundation
import UIKit
import SwiftUI

// MARK: - Exercise Type Enum
enum ExerciseType: String, CaseIterable, Codable, Identifiable {
    case pushup = "pushup"
    case pullup = "pullup"
    case situp = "situp"      // Keep temporarily for migration
    case plank = "plank"      // NEW: Add plank
    case run = "run"
    case unknown = "unknown"
    
    var id: String { self.rawValue }
    
    /// Filtered cases for UI display (excludes deprecated exercises)
    static var visibleCases: [ExerciseType] {
        return [.pushup, .pullup, .plank, .run]  // Excludes .situp
    }
    
    var displayName: String {
        switch self {
        case .pushup: return "Push-ups"
        case .pullup: return "Pull-ups"
        case .situp: return "Sit-ups"    // Keep temporarily
        case .plank: return "Plank"       // NEW: Add after .situp case
        case .run: return "3-mile Run"    // Updated from 2-mile to 3-mile for USMC PFT
        case .unknown: return "Unknown Exercise"
        }
    }
    
    var exerciseId: Int {
        switch self {
        case .pushup: return 1
        case .pullup: return 2
        case .situp: return 3             // Keep temporarily
        case .plank: return 5             // NEW: Use ID 5 for plank
        case .run: return 4
        case .unknown: return 0
        }
    }
    
    var color: Color {
        switch self {
        case .pushup: return .blue
        case .pullup: return .green
        case .situp: return .orange       // Keep temporarily
        case .plank: return .purple       // NEW: Distinct color for plank
        case .run: return .red
        case .unknown: return .gray
        }
    }
    
    var icon: String {
        switch self {
        case .pushup: return "figure.strengthtraining.traditional"
        case .pullup: return "figure.climbing"
        case .situp: return "figure.core.training"
        case .plank: return "figure.core.training"  // Same icon as situp
        case .run: return "figure.run"
        case .unknown: return "questionmark.circle"
        }
    }
}

// MARK: - NEW: Workout Model (Unified Schema)
/// Represents a workout in the new unified schema
struct Workout: Codable, Identifiable, Hashable {
    let id: Int
    let userId: Int
    let exerciseId: Int
    let exerciseType: ExerciseType
    let repetitions: Int?
    let durationSeconds: Int?
    let distanceMeters: Decimal?
    let formScore: Int // 0-100, now required (defaults to 0)
    let grade: Int // 0-100, required
    let isPublic: Bool
    let completedAt: Date
    let createdAt: Date
    let deviceId: String?
    let metadata: WorkoutMetadata?
    let notes: String?
    let syncStatus: SyncStatus
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case exerciseId = "exercise_id"
        case exerciseType = "exercise_type"
        case repetitions
        case durationSeconds = "duration_seconds"
        case distanceMeters = "distance_meters"
        case formScore = "form_score"
        case grade
        case isPublic = "is_public"
        case completedAt = "completed_at"
        case createdAt = "created_at"
        case deviceId = "device_id"
        case metadata
        case notes
        case syncStatus = "sync_status"
    }
    
    // Custom decoder to handle formScore defaulting
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        userId = try container.decode(Int.self, forKey: .userId)
        exerciseId = try container.decode(Int.self, forKey: .exerciseId)
        exerciseType = try container.decode(ExerciseType.self, forKey: .exerciseType)
        repetitions = try container.decodeIfPresent(Int.self, forKey: .repetitions)
        durationSeconds = try container.decodeIfPresent(Int.self, forKey: .durationSeconds)
        distanceMeters = try container.decodeIfPresent(Decimal.self, forKey: .distanceMeters)
        
        // Handle form_score with default value of 0
        formScore = try container.decodeIfPresent(Int.self, forKey: .formScore) ?? 0
        
        grade = try container.decode(Int.self, forKey: .grade)
        isPublic = try container.decodeIfPresent(Bool.self, forKey: .isPublic) ?? false
        completedAt = try container.decode(Date.self, forKey: .completedAt)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        deviceId = try container.decodeIfPresent(String.self, forKey: .deviceId)
        metadata = try container.decodeIfPresent(WorkoutMetadata.self, forKey: .metadata)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        
        let syncStatusString = try container.decodeIfPresent(String.self, forKey: .syncStatus) ?? "synced"
        syncStatus = SyncStatus(rawValue: syncStatusString) ?? .synced
    }
    
    // Standard memberwise initializer
    init(
        id: Int,
        userId: Int,
        exerciseId: Int,
        exerciseType: ExerciseType,
        repetitions: Int? = nil,
        durationSeconds: Int? = nil,
        distanceMeters: Decimal? = nil,
        formScore: Int = 0, // Default to 0
        grade: Int,
        isPublic: Bool = false,
        completedAt: Date,
        createdAt: Date,
        deviceId: String? = nil,
        metadata: WorkoutMetadata? = nil,
        notes: String? = nil,
        syncStatus: SyncStatus = .synced
    ) {
        self.id = id
        self.userId = userId
        self.exerciseId = exerciseId
        self.exerciseType = exerciseType
        self.repetitions = repetitions
        self.durationSeconds = durationSeconds
        self.distanceMeters = distanceMeters
        self.formScore = max(0, min(100, formScore)) // Ensure valid range
        self.grade = max(0, min(100, grade)) // Ensure valid range
        self.isPublic = isPublic
        self.completedAt = completedAt
        self.createdAt = createdAt
        self.deviceId = deviceId
        self.metadata = metadata
        self.notes = notes
        self.syncStatus = syncStatus
    }
    
    // Computed properties for backward compatibility
    var timeInSeconds: Int? { durationSeconds }
    var reps: Int? { repetitions }
    
    // Exercise display helpers
    var exerciseDisplayName: String { exerciseType.displayName }
    
    // Performance categorization
    var performanceLevel: PerformanceLevel {
        switch grade {
        case 90...100: return .excellent
        case 80..<90: return .good
        case 70..<80: return .satisfactory
        case 60..<70: return .needsImprovement
        default: return .unsatisfactory
        }
    }
}

// MARK: - Workout Request Models
/// Request to create a new workout
struct CreateWorkoutRequest: Codable {
    let exerciseId: Int
    let exerciseType: ExerciseType
    let repetitions: Int?
    let durationSeconds: Int?
    let distanceMeters: Decimal?
    let formScore: Int // Required field with default
    let grade: Int
    let isPublic: Bool
    let completedAt: Date
    let deviceId: String?
    let metadata: WorkoutMetadata?
    let notes: String?
    let idempotencyKey: String?
    
    enum CodingKeys: String, CodingKey {
        case exerciseId = "exercise_id"
        case exerciseType = "exercise_type"
        case repetitions
        case durationSeconds = "duration_seconds"
        case distanceMeters = "distance_meters"
        case formScore = "form_score"
        case grade
        case isPublic = "is_public"
        case completedAt = "completed_at"
        case deviceId = "device_id"
        case metadata
        case notes
        case idempotencyKey = "idempotency_key"
    }
    
    init(
        exerciseType: ExerciseType,
        repetitions: Int? = nil,
        durationSeconds: Int? = nil,
        distanceMeters: Decimal? = nil,
        formScore: Int = 0, // Default to 0
        grade: Int,
        isPublic: Bool = false,
        completedAt: Date = Date(),
        deviceId: String? = UIDevice.current.identifierForVendor?.uuidString,
        metadata: WorkoutMetadata? = nil,
        notes: String? = nil,
        idempotencyKey: String? = UUID().uuidString
    ) {
        self.exerciseId = exerciseType.exerciseId
        self.exerciseType = exerciseType
        self.repetitions = repetitions
        self.durationSeconds = durationSeconds
        self.distanceMeters = distanceMeters
        self.formScore = max(0, min(100, formScore)) // Validate range
        self.grade = max(0, min(100, grade)) // Validate range
        self.isPublic = isPublic
        self.completedAt = completedAt
        self.deviceId = deviceId
        self.metadata = metadata
        self.notes = notes
        self.idempotencyKey = idempotencyKey
    }
}

// MARK: - Workout Metadata
/// Flexible metadata structure for workouts
struct WorkoutMetadata: Codable, Hashable {
    let heartRateData: HeartRateData?
    let poseAnalysis: PoseAnalysisData?
    let environmentalData: EnvironmentalData?
    let deviceInfo: DeviceInfo?
    
    // Custom properties for different exercise types
    let runningMetrics: RunningMetrics?
    let strengthMetrics: StrengthMetrics?
    
    enum CodingKeys: String, CodingKey {
        case heartRateData = "heart_rate_data"
        case poseAnalysis = "pose_analysis"
        case environmentalData = "environmental_data"
        case deviceInfo = "device_info"
        case runningMetrics = "running_metrics"
        case strengthMetrics = "strength_metrics"
    }
}

// MARK: - Metadata Components
struct HeartRateData: Codable, Hashable {
    let averageHeartRate: Int?
    let maxHeartRate: Int?
    let heartRateZones: [HeartRateZone]?
}

struct HeartRateZone: Codable, Hashable {
    let zone: Int // 1-5
    let timeInSeconds: Int
    let percentage: Double
}

struct PoseAnalysisData: Codable, Hashable {
    let averageFormScore: Double?
    let formBreakdowns: [FormBreakdown]?
    let repTimings: [Double]? // Time for each rep
}

struct FormBreakdown: Codable, Hashable {
    let timestamp: TimeInterval
    let score: Double
    let feedback: String?
}

struct EnvironmentalData: Codable, Hashable {
    let temperature: Double?
    let humidity: Double?
    let altitude: Double?
    let weather: String?
}

struct DeviceInfo: Codable, Hashable {
    let deviceModel: String?
    let osVersion: String?
    let appVersion: String?
    let cameraUsed: Bool?
    let bluetoothDevices: [String]?
}

struct RunningMetrics: Codable, Hashable {
    let pace: Double? // minutes per mile
    let cadence: Int? // steps per minute
    let strideLength: Double? // meters
    let route: RouteData?
}

struct RouteData: Codable, Hashable {
    let coordinates: [Coordinate]?
    let elevationGain: Double?
    let totalDistance: Double?
}

struct Coordinate: Codable, Hashable {
    let latitude: Double
    let longitude: Double
    let timestamp: TimeInterval
}

struct StrengthMetrics: Codable, Hashable {
    let repTimings: [Double]? // Time for each rep
    let restPeriods: [Double]? // Rest between sets
    let powerOutput: [Double]? // If available from sensors
}

// MARK: - Legacy Models for Backward Compatibility
/// Legacy model - use Workout instead
struct LogWorkoutRequest: Codable {
    let exerciseID: Int32
    let reps: Int32?
    let durationSeconds: Int32?
    let formScore: Int32? // Optional for legacy compatibility
    let completedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case exerciseID = "exercise_id"
        case reps
        case durationSeconds = "duration_seconds"
        case formScore = "form_score"
        case completedAt = "completed_at"
    }
}

/// Legacy model for inserting user exercises - use CreateWorkoutRequest instead
struct InsertUserExerciseRequest: Codable {
    let exerciseId: Int
    let exerciseType: String
    let repetitions: Int?
    let formScore: Int?
    let timeInSeconds: Int?
    let grade: Int?
    let completed: Bool
    let metadata: String?
    let deviceId: String?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case exerciseId = "exercise_id"
        case exerciseType = "exercise_type"
        case repetitions
        case formScore = "form_score"
        case timeInSeconds = "time_in_seconds"
        case grade
        case completed
        case metadata
        case deviceId = "device_id"
        case createdAt = "created_at"
    }
    
    // Primary initializer matching the usage pattern in RunWorkoutViewModel
    init(exerciseId: Int, repetitions: Int? = nil, formScore: Int? = nil, timeInSeconds: Int? = nil, grade: Int? = nil, completedAt: Date = Date()) {
        self.exerciseId = exerciseId
        self.repetitions = repetitions
        self.formScore = formScore
        self.timeInSeconds = timeInSeconds
        self.grade = grade
        self.completed = true
        self.metadata = nil
        self.deviceId = UIDevice.current.identifierForVendor?.uuidString
        self.createdAt = completedAt
        
        // Map exerciseId to exerciseType string
        switch exerciseId {
        case 1:
            self.exerciseType = "pushup"
        case 2:
            self.exerciseType = "pullup"
        case 3:
            self.exerciseType = "situp"
        case 5:                           // NEW
            self.exerciseType = "plank"   // NEW: Map ID 5 to plank
        case 4:
            self.exerciseType = "run"
        case 0:
            self.exerciseType = "unknown"
        default:
            self.exerciseType = "unknown"
        }
    }
    
    // Alternative initializer for backwards compatibility
    init(exerciseType: ExerciseType, repetitions: Int? = nil, timeInSeconds: Int? = nil, formScore: Int? = nil, grade: Int? = nil) {
        self.exerciseId = exerciseType.exerciseId
        self.exerciseType = exerciseType.rawValue
        self.repetitions = repetitions
        self.formScore = formScore
        self.timeInSeconds = timeInSeconds
        self.grade = grade
        self.completed = true
        self.metadata = nil
        self.deviceId = UIDevice.current.identifierForVendor?.uuidString
        self.createdAt = Date()
    }
}

/// Legacy paginated response - use PaginatedWorkoutsResponse instead
struct PaginatedUserExerciseResponse: Codable {
    let items: [UserExerciseRecord]
    let totalCount: Int
    let currentPage: Int
    let pageSize: Int
    let totalPages: Int
    
    enum CodingKeys: String, CodingKey {
        case items
        case totalCount = "total_count"
        case currentPage = "current_page"
        case pageSize = "page_size"
        case totalPages = "total_pages"
    }
}

/// Legacy exercise model for API responses
struct Exercise: Codable, Identifiable {
    let id: Int
    let name: String
    let type: String
    let description: String?
    let category: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case type
        case description
        case category
    }
}

/// Legacy model - use Workout instead
struct UserExerciseRecord: Codable, Identifiable {
    let id: Int
    let userId: Int
    let exerciseId: Int
    let repetitions: Int?
    let formScore: Int?
    let timeInSeconds: Int?
    let grade: Int?
    let completed: Bool?
    let metadata: String?
    let deviceId: String?
    let syncStatus: String?
    let createdAt: Date
    let updatedAt: Date
    
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
    
    /// Computed property to get exercise type string from exerciseId
    var exerciseTypeKey: String {
        switch exerciseId {
        case 1: return "pushup"
        case 2: return "pullup"
        case 3: return "situp"
        case 5: return "plank"    // NEW: Add plank mapping
        case 4: return "run"
        default: return "unknown"
        }
    }
}

// MARK: - API Response Models
/// Paginated workout response from API
struct PaginatedWorkoutsResponse: Codable {
    let items: [Workout]
    let totalCount: Int
    let page: Int
    let pageSize: Int
    let totalPages: Int
    
    enum CodingKeys: String, CodingKey {
        case items
        case totalCount = "total_count"
        case page
        case pageSize = "page_size"
        case totalPages = "total_pages"
    }
}

/// Workout response from API (matches backend WorkoutResponse schema)
struct WorkoutAPIResponse: Codable {
    let id: Int
    let userId: Int
    let exerciseId: Int
    let exerciseName: String
    let exerciseType: String
    let reps: Int?
    let durationSeconds: Int?
    let distanceMeters: Decimal?
    let formScore: Int // Required field
    let grade: Int
    let isPublic: Bool
    let completedAt: Date
    let createdAt: Date
    let deviceId: String?
    let metadata: WorkoutMetadata?
    let notes: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case exerciseId = "exercise_id"
        case exerciseName = "exercise_name"
        case exerciseType = "exercise_type"
        case reps
        case durationSeconds = "duration_seconds"
        case distanceMeters = "distance_meters"
        case formScore = "form_score"
        case grade
        case isPublic = "is_public"
        case completedAt = "completed_at"
        case createdAt = "created_at"
        case deviceId = "device_id"
        case metadata
        case notes
    }
    
    /// Convert API response to Workout model
    func toWorkout() -> Workout {
        return Workout(
            id: id,
            userId: userId,
            exerciseId: exerciseId,
            exerciseType: ExerciseType(rawValue: exerciseType) ?? .pushup,
            repetitions: reps,
            durationSeconds: durationSeconds,
            distanceMeters: distanceMeters,
            formScore: formScore, // Now guaranteed to be present
            grade: grade,
            isPublic: isPublic,
            completedAt: completedAt,
            createdAt: createdAt,
            deviceId: deviceId,
            metadata: metadata,
            notes: notes,
            syncStatus: .synced
        )
    }
}

// MARK: - Performance Level Enum
enum PerformanceLevel: String, CaseIterable {
    case excellent = "excellent"
    case good = "good"
    case satisfactory = "satisfactory"
    case needsImprovement = "needs_improvement"
    case unsatisfactory = "unsatisfactory"
    
    var displayName: String {
        switch self {
        case .excellent: return "Excellent"
        case .good: return "Good"
        case .satisfactory: return "Satisfactory"
        case .needsImprovement: return "Needs Improvement"
        case .unsatisfactory: return "Unsatisfactory"
        }
    }
    
    var color: String {
        switch self {
        case .excellent: return "green"
        case .good: return "blue"
        case .satisfactory: return "yellow"
        case .needsImprovement: return "orange"
        case .unsatisfactory: return "red"
        }
    }
}

// MARK: - Validation Extensions
extension CreateWorkoutRequest {
    /// Validates that the workout request has appropriate data for the exercise type
    func validate() throws {
        // Validate form_score range
        guard formScore >= 0 && formScore <= 100 else {
            throw WorkoutValidationError.invalidFormScore
        }
        
        // Validate grade range
        guard grade >= 0 && grade <= 100 else {
            throw WorkoutValidationError.invalidGrade
        }
        
        // Exercise type specific validation
        switch exerciseType {
        case .run:
            guard distanceMeters != nil && durationSeconds != nil else {
                throw WorkoutValidationError.missingRunMetrics
            }
        case .pushup, .pullup, .situp:
            guard repetitions != nil else {
                throw WorkoutValidationError.missingRepetitions
            }
        case .plank:
            guard durationSeconds != nil else {
                throw WorkoutValidationError.missingDuration
            }
        case .unknown:
            // No specific validation for unknown exercise types
            break
        }
    }
}

// MARK: - Validation Errors
enum WorkoutValidationError: LocalizedError {
    case invalidFormScore
    case invalidGrade
    case missingRunMetrics
    case missingRepetitions
    case missingDuration
    
    var errorDescription: String? {
        switch self {
        case .invalidFormScore:
            return "Form score must be between 0 and 100"
        case .invalidGrade:
            return "Grade must be between 0 and 100"
        case .missingRunMetrics:
            return "Running exercises require distance and duration"
        case .missingRepetitions:
            return "Strength exercises require repetition count"
        case .missingDuration:
            return "Plank exercises require duration"
        }
    }
}

// MARK: - Extensions
extension String {
    func extractExerciseTypeKey() -> String {
        // Try to parse metadata JSON and extract exercise type
        guard let data = self.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let exerciseType = json["exercise_type"] as? String else {
            return "unknown"
        }
        return exerciseType
    }
}

extension Workout {
    /// Create a workout for testing purposes
    static func mock(
        id: Int = 1,
        exerciseType: ExerciseType = .pushup,
        repetitions: Int? = 50,
        formScore: Int = 85,
        grade: Int = 85,
        completedAt: Date = Date()
    ) -> Workout {
        Workout(
            id: id,
            userId: 1,
            exerciseId: exerciseType.exerciseId,
            exerciseType: exerciseType,
            repetitions: repetitions,
            durationSeconds: exerciseType == .run ? 600 : nil,
            distanceMeters: exerciseType == .run ? Decimal(3218.69) : nil, // 2 miles in meters
            formScore: formScore, // Now always provided
            grade: grade,
            isPublic: false,
            completedAt: completedAt,
            createdAt: completedAt,
            deviceId: "test-device",
            metadata: nil,
            notes: nil,
            syncStatus: .synced
        )
    }
} 