import Foundation
import Combine

/// Repository for managing calibration data storage and retrieval using UserDefaults
class CalibrationRepository: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var error: CalibrationRepositoryError?
    
    // MARK: - Cache
    private var calibrationCache: [String: CalibrationData] = [:]
    private let cacheQueue = DispatchQueue(label: "calibration.cache", qos: .utility)
    
    // MARK: - Initialization
    init() {
        print("📱 CalibrationRepository initialized with UserDefaults storage")
        // Load recent calibrations into cache
        loadRecentCalibrationsToCache()
    }
    
    // MARK: - Public Save Methods
    func saveCalibration(_ calibration: CalibrationData) async throws {
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        defer {
            Task { @MainActor in
                isLoading = false
            }
        }
        
        do {
            try saveToUserDefaults(calibration)
            
            // Update cache
            cacheQueue.async {
                let cacheKey = self.cacheKey(for: calibration.exercise)
                self.calibrationCache[cacheKey] = calibration
            }
            
            print("💾 Saved calibration for \(calibration.exercise.displayName) with score \(calibration.calibrationScore)")
        } catch {
            await MainActor.run {
                self.error = CalibrationRepositoryError.saveFailed(error)
            }
            throw error
        }
    }
    
    // MARK: - Public Retrieval Methods
    func getLatestCalibration(for exercise: ExerciseType) async -> CalibrationData? {
        // Check cache first
        let cacheKey = self.cacheKey(for: exercise)
        if let cached = calibrationCache[cacheKey] {
            return cached
        }
        
        await MainActor.run {
            isLoading = true
        }
        
        defer {
            Task { @MainActor in
                isLoading = false
            }
        }
        
        let calibration = getUserDefaultsCalibration(for: exercise)
        
        // Update cache
        if let data = calibration {
            cacheQueue.async {
                self.calibrationCache[cacheKey] = data
            }
        }
        
        return calibration
    }
    
    func getBestCalibration(for exercise: ExerciseType) async -> CalibrationData? {
        await MainActor.run {
            isLoading = true
        }
        
        defer {
            Task { @MainActor in
                isLoading = false
            }
        }
        
        // Check for saved calibration first
        if let savedCalibration = getUserDefaultsCalibration(for: exercise) {
            return savedCalibration
        }
        
        // If running in simulator and no calibration exists, provide a mock calibration
        #if targetEnvironment(simulator)
        print("📱 Running in simulator - providing mock calibration for \(exercise.displayName)")
        return createMockCalibration(for: exercise)
        #else
        return nil
        #endif
    }
    
    func getUsableCalibrations(for exercise: ExerciseType) async -> [CalibrationData] {
        await MainActor.run {
            isLoading = true
        }
        
        defer {
            Task { @MainActor in
                isLoading = false
            }
        }
        
        if let calibration = getUserDefaultsCalibration(for: exercise) {
            // For UserDefaults, we only have one calibration per exercise
            // Check if it's usable (score > 50)
            if calibration.calibrationScore > 50.0 {
                return [calibration]
            }
        }
        
        return []
    }
    
    func getAllCalibrations(for exercise: ExerciseType? = nil) async -> [CalibrationData] {
        await MainActor.run {
            isLoading = true
        }
        
        defer {
            Task { @MainActor in
                isLoading = false
            }
        }
        
        var calibrations: [CalibrationData] = []
        
        if let exercise = exercise {
            if let calibration = getUserDefaultsCalibration(for: exercise) {
                calibrations.append(calibration)
            }
        } else {
            // Get all exercises
            let exercises: [ExerciseType] = [.pushup, .situp, .pullup]
            for exerciseType in exercises {
                if let calibration = getUserDefaultsCalibration(for: exerciseType) {
                    calibrations.append(calibration)
                }
            }
        }
        
        return calibrations
    }
    
    // MARK: - Deletion Methods
    func deleteCalibration(id: UUID) async throws {
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        defer {
            Task { @MainActor in
                isLoading = false
            }
        }
        
        // Find which exercise this calibration belongs to
        let exercises: [ExerciseType] = [.pushup, .situp, .pullup]
        for exercise in exercises {
            if let calibration = getUserDefaultsCalibration(for: exercise),
               calibration.id == id {
                UserDefaults.standard.removeObject(forKey: "calibration_\(exercise.rawValue)")
                
                // Remove from cache
                cacheQueue.async {
                    let cacheKey = self.cacheKey(for: exercise)
                    self.calibrationCache.removeValue(forKey: cacheKey)
                }
                
                print("🗑️ Deleted calibration for \(exercise.displayName)")
                return
            }
        }
    }
    
    func archiveCalibration(id: UUID) async throws {
        // For UserDefaults implementation, archiving is the same as deleting
        try await deleteCalibration(id: id)
    }
    
    // MARK: - Cleanup Methods
    func deleteOldCalibrations(olderThan days: Int) async throws {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        await MainActor.run {
            isLoading = true
        }
        
        defer {
            Task { @MainActor in
                isLoading = false
            }
        }
        
        let exercises: [ExerciseType] = [.pushup, .situp, .pullup]
        var deletedCount = 0
        
        for exercise in exercises {
            if let calibration = getUserDefaultsCalibration(for: exercise),
               calibration.timestamp < cutoffDate {
                UserDefaults.standard.removeObject(forKey: "calibration_\(exercise.rawValue)")
                
                // Remove from cache
                cacheQueue.async {
                    let cacheKey = self.cacheKey(for: exercise)
                    self.calibrationCache.removeValue(forKey: cacheKey)
                }
                
                deletedCount += 1
            }
        }
        
        print("🧹 Deleted \(deletedCount) old calibrations")
    }
    
    // MARK: - Statistics Methods
    func getCalibrationStatistics() async -> CalibrationStatistics {
        let exercises: [ExerciseType] = [.pushup, .situp, .pullup]
        var exerciseCounts: [ExerciseType: Int] = [:]
        var qualityCounts: [CalibrationQuality: Int] = [:]
        var totalScore: Float = 0
        var totalConfidence: Float = 0
        var totalCalibrations = 0
        var usableCalibrations = 0
        
        for exercise in exercises {
            if let calibration = getUserDefaultsCalibration(for: exercise) {
                exerciseCounts[exercise] = 1
                totalCalibrations += 1
                totalScore += calibration.calibrationScore
                totalConfidence += calibration.confidenceLevel
                
                                 // Determine quality based on score
                 let quality: CalibrationQuality
                 if calibration.calibrationScore >= 90 {
                     quality = .excellent
                 } else if calibration.calibrationScore >= 80 {
                     quality = .good
                 } else if calibration.calibrationScore >= 70 {
                     quality = .acceptable
                 } else if calibration.calibrationScore >= 60 {
                     quality = .poor
                 } else {
                     quality = .invalid
                 }
                qualityCounts[quality, default: 0] += 1
                
                if calibration.calibrationScore > 50 {
                    usableCalibrations += 1
                }
            }
        }
        
        return CalibrationStatistics(
            totalCalibrations: totalCalibrations,
            exerciseCounts: exerciseCounts,
            qualityCounts: qualityCounts,
            averageScore: totalCalibrations == 0 ? 0 : totalScore / Float(totalCalibrations),
            averageConfidence: totalCalibrations == 0 ? 0 : totalConfidence / Float(totalCalibrations),
            usableCalibrations: usableCalibrations
        )
    }
    
    // MARK: - Migration from UserDefaults (No-op for UserDefaults-only implementation)
    func migrateFromUserDefaults() async {
        print("📱 Migration not needed - already using UserDefaults")
    }
    
    // MARK: - Private Helpers
    private func getUserDefaultsCalibration(for exercise: ExerciseType) -> CalibrationData? {
        guard let data = UserDefaults.standard.data(forKey: "calibration_\(exercise.rawValue)"),
              let calibration = try? JSONDecoder().decode(CalibrationData.self, from: data) else {
            print("⚠️ No UserDefaults calibration found for \(exercise.displayName)")
            return nil
        }
        
        print("📱 Loaded calibration from UserDefaults for \(exercise.displayName)")
        return calibration
    }
    
    private func saveToUserDefaults(_ calibration: CalibrationData) throws {
        do {
            let data = try JSONEncoder().encode(calibration)
            UserDefaults.standard.set(data, forKey: "calibration_\(calibration.exercise.rawValue)")
            print("📱 Saved calibration to UserDefaults for \(calibration.exercise.displayName)")
        } catch {
            throw CalibrationRepositoryError.saveFailed(error)
        }
    }
    
    private func cacheKey(for exercise: ExerciseType) -> String {
        return "latest_\(exercise.rawValue)"
    }
    
    private func loadRecentCalibrationsToCache() {
        Task {
            let exercises: [ExerciseType] = [.pushup, .situp, .pullup]
            
            for exercise in exercises {
                if let calibration = await getLatestCalibration(for: exercise) {
                    cacheQueue.async {
                        let cacheKey = self.cacheKey(for: exercise)
                        self.calibrationCache[cacheKey] = calibration
                    }
                }
            }
        }
    }
    
    #if targetEnvironment(simulator)
    private func createMockCalibration(for exercise: ExerciseType) -> CalibrationData {
        return CalibrationData(
            id: UUID(),
            timestamp: Date(),
            exercise: exercise,
            deviceHeight: 1.2,
            deviceAngle: 0.0,
            deviceDistance: 1.5,
            deviceStability: 0.8,
            userHeight: 1.75,
            armSpan: 1.75,
            torsoLength: 0.6,
            legLength: 0.9,
            angleAdjustments: AngleAdjustments(
                pushupElbowUp: 160.0,
                pushupElbowDown: 90.0,
                pushupBodyAlignment: 10.0,
                situpTorsoUp: 80.0,
                situpTorsoDown: 10.0,
                situpKneeAngle: 90.0,
                pullupArmExtended: 170.0,
                pullupArmFlexed: 90.0,
                pullupBodyVertical: 15.0
            ),
            visibilityThresholds: VisibilityThresholds(
                minimumConfidence: 0.5,
                criticalJoints: 0.7,
                supportJoints: 0.6,
                faceJoints: 0.5
            ),
            poseNormalization: PoseNormalization(
                shoulderWidth: 0.4,
                hipWidth: 0.35,
                armLength: 0.6,
                legLength: 0.9,
                headSize: 0.2
            ),
            calibrationScore: 85.0, // Good quality mock calibration
            confidenceLevel: 0.8,
            frameCount: 100,
            validationRanges: ValidationRanges(
                angleTolerances: ["elbow": 15.0, "knee": 10.0, "hip": 20.0],
                positionTolerances: ["shoulder": 0.1, "hip": 0.1],
                movementThresholds: ["speed": 2.0, "acceleration": 5.0]
            )
        )
    }
    #endif
}

// MARK: - Supporting Types

enum CalibrationRepositoryError: LocalizedError {
    case saveFailed(Error)
    case fetchFailed(Error)
    case deleteFailed(Error)
    case archiveFailed(Error)
    case cleanupFailed(Error)
    case migrationFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .saveFailed(let error):
            return "Failed to save calibration: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Failed to fetch calibration: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete calibration: \(error.localizedDescription)"
        case .archiveFailed(let error):
            return "Failed to archive calibration: \(error.localizedDescription)"
        case .cleanupFailed(let error):
            return "Failed to cleanup old calibrations: \(error.localizedDescription)"
        case .migrationFailed(let error):
            return "Failed to migrate calibrations: \(error.localizedDescription)"
        }
    }
}

struct CalibrationStatistics {
    let totalCalibrations: Int
    let exerciseCounts: [ExerciseType: Int]
    let qualityCounts: [CalibrationQuality: Int]
    let averageScore: Float
    let averageConfidence: Float
    let usableCalibrations: Int
    
    static let empty = CalibrationStatistics(
        totalCalibrations: 0,
        exerciseCounts: [:],
        qualityCounts: [:],
        averageScore: 0,
        averageConfidence: 0,
        usableCalibrations: 0
    )
} 