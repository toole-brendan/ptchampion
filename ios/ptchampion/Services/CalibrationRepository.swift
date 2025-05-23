import Foundation
import CoreData
import Combine

/// Repository for managing calibration data storage and retrieval using Core Data
class CalibrationRepository: ObservableObject {
    
    // MARK: - Core Data Stack
    private let container: NSPersistentContainer
    private let context: NSManagedObjectContext
    
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var error: CalibrationRepositoryError?
    
    // MARK: - Cache
    private var calibrationCache: [String: CalibrationData] = [:]
    private let cacheQueue = DispatchQueue(label: "calibration.cache", qos: .utility)
    
    // MARK: - Initialization
    init(container: NSPersistentContainer) {
        self.container = container
        self.context = container.viewContext
        
        // Configure context
        context.automaticallyMergesChangesFromParent = true
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        // Load recent calibrations into cache
        loadRecentCalibrationsToCache()
    }
    
    convenience init() {
        // Create default container - in practice, this would be injected
        let container = NSPersistentContainer(name: "PTChampionDataModel")
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Core Data failed to load: \(error)")
            }
        }
        self.init(container: container)
    }
    
    // MARK: - Public Save Methods
    func saveCalibration(_ calibration: CalibrationData) async throws {
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        do {
            try await withCheckedThrowingContinuation { continuation in
                context.perform {
                    do {
                        // Check if calibration already exists
                        let existingEntity = self.findExistingCalibration(calibration.id)
                        
                        let entity: CalibrationEntity
                        if let existing = existingEntity {
                            // Update existing
                            entity = existing
                        } else {
                            // Create new
                            entity = CalibrationEntity(context: self.context, from: calibration)
                        }
                        
                        try self.context.save()
                        
                        // Update cache
                        self.cacheQueue.async {
                            let cacheKey = self.cacheKey(for: calibration.exercise)
                            self.calibrationCache[cacheKey] = calibration
                        }
                        
                        print("💾 Saved calibration for \(calibration.exercise.displayName) with score \(calibration.calibrationScore)")
                        continuation.resume()
                        
                    } catch {
                        continuation.resume(throwing: CalibrationRepositoryError.saveFailed(error))
                    }
                }
            }
        } catch {
            await MainActor.run {
                self.error = error as? CalibrationRepositoryError ?? .saveFailed(error)
            }
            throw error
        }
        
        await MainActor.run {
            isLoading = false
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
        
        return await withCheckedContinuation { continuation in
            context.perform {
                do {
                    let request: NSFetchRequest<CalibrationEntity> = CalibrationEntity.fetchRequest()
                    request.predicate = CalibrationEntity.predicateForExercise(exercise)
                    request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
                    request.fetchLimit = 1
                    
                    let results = try self.context.fetch(request)
                    let calibrationData = results.first?.toCalibrationData()
                    
                    // Update cache
                    if let data = calibrationData {
                        self.cacheQueue.async {
                            self.calibrationCache[cacheKey] = data
                        }
                    }
                    
                    continuation.resume(returning: calibrationData)
                } catch {
                    print("❌ Failed to fetch latest calibration for \(exercise.displayName): \(error)")
                    continuation.resume(returning: nil)
                }
            }
        }
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
        
        return await withCheckedContinuation { continuation in
            context.perform {
                do {
                    let request: NSFetchRequest<CalibrationEntity> = CalibrationEntity.fetchRequest()
                    
                    // First try to get high-quality calibrations
                    let highQualityPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                        CalibrationEntity.predicateForExercise(exercise),
                        CalibrationEntity.predicateForQualityAbove(80.0)
                    ])
                    request.predicate = highQualityPredicate
                    request.sortDescriptors = [NSSortDescriptor(key: "calibrationScore", ascending: false)]
                    request.fetchLimit = 1
                    
                    var results = try self.context.fetch(request)
                    
                    // If no high-quality calibration, fall back to best available
                    if results.isEmpty {
                        request.predicate = CalibrationEntity.predicateForExercise(exercise)
                        request.sortDescriptors = [NSSortDescriptor(key: "calibrationScore", ascending: false)]
                        results = try self.context.fetch(request)
                    }
                    
                    let calibrationData = results.first?.toCalibrationData()
                    continuation.resume(returning: calibrationData)
                } catch {
                    print("❌ Failed to fetch best calibration for \(exercise.displayName): \(error)")
                    continuation.resume(returning: nil)
                }
            }
        }
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
        
        return await withCheckedContinuation { continuation in
            context.perform {
                do {
                    let request: NSFetchRequest<CalibrationEntity> = CalibrationEntity.fetchRequest()
                    
                    let usablePredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                        CalibrationEntity.predicateForExercise(exercise),
                        CalibrationEntity.predicateForUsable()
                    ])
                    request.predicate = usablePredicate
                    request.sortDescriptors = [
                        NSSortDescriptor(key: "calibrationScore", ascending: false),
                        NSSortDescriptor(key: "timestamp", ascending: false)
                    ]
                    
                    let results = try self.context.fetch(request)
                    let calibrations = results.compactMap { $0.toCalibrationData() }
                    
                    continuation.resume(returning: calibrations)
                } catch {
                    print("❌ Failed to fetch usable calibrations for \(exercise.displayName): \(error)")
                    continuation.resume(returning: [])
                }
            }
        }
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
        
        return await withCheckedContinuation { continuation in
            context.perform {
                do {
                    let request: NSFetchRequest<CalibrationEntity> = CalibrationEntity.fetchRequest()
                    
                    if let exercise = exercise {
                        request.predicate = CalibrationEntity.predicateForExercise(exercise)
                    } else {
                        request.predicate = NSPredicate(format: "isArchived == NO")
                    }
                    
                    request.sortDescriptors = [
                        NSSortDescriptor(key: "timestamp", ascending: false)
                    ]
                    
                    let results = try self.context.fetch(request)
                    let calibrations = results.compactMap { $0.toCalibrationData() }
                    
                    continuation.resume(returning: calibrations)
                } catch {
                    print("❌ Failed to fetch all calibrations: \(error)")
                    continuation.resume(returning: [])
                }
            }
        }
    }
    
    // MARK: - Deletion Methods
    func deleteCalibration(id: UUID) async throws {
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        do {
            try await withCheckedThrowingContinuation { continuation in
                context.perform {
                    do {
                        if let entity = self.findExistingCalibration(id) {
                            self.context.delete(entity)
                            try self.context.save()
                            
                            // Remove from cache
                            self.cacheQueue.async {
                                if let exercise = entity.exercise,
                                   let exerciseType = ExerciseType(rawValue: exercise) {
                                    let cacheKey = self.cacheKey(for: exerciseType)
                                    self.calibrationCache.removeValue(forKey: cacheKey)
                                }
                            }
                            
                            print("🗑️ Deleted calibration with ID: \(id)")
                        }
                        continuation.resume()
                    } catch {
                        continuation.resume(throwing: CalibrationRepositoryError.deleteFailed(error))
                    }
                }
            }
        } catch {
            await MainActor.run {
                self.error = error as? CalibrationRepositoryError ?? .deleteFailed(error)
            }
            throw error
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
    
    func archiveCalibration(id: UUID) async throws {
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        do {
            try await withCheckedThrowingContinuation { continuation in
                context.perform {
                    do {
                        if let entity = self.findExistingCalibration(id) {
                            entity.isArchived = true
                            try self.context.save()
                            
                            // Remove from cache
                            self.cacheQueue.async {
                                if let exercise = entity.exercise,
                                   let exerciseType = ExerciseType(rawValue: exercise) {
                                    let cacheKey = self.cacheKey(for: exerciseType)
                                    self.calibrationCache.removeValue(forKey: cacheKey)
                                }
                            }
                            
                            print("📦 Archived calibration with ID: \(id)")
                        }
                        continuation.resume()
                    } catch {
                        continuation.resume(throwing: CalibrationRepositoryError.archiveFailed(error))
                    }
                }
            }
        } catch {
            await MainActor.run {
                self.error = error as? CalibrationRepositoryError ?? .archiveFailed(error)
            }
            throw error
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
    
    // MARK: - Cleanup Methods
    func deleteOldCalibrations(olderThan days: Int) async throws {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        await MainActor.run {
            isLoading = true
        }
        
        do {
            try await withCheckedThrowingContinuation { continuation in
                context.perform {
                    do {
                        let request: NSFetchRequest<CalibrationEntity> = CalibrationEntity.fetchRequest()
                        request.predicate = NSPredicate(format: "timestamp < %@", cutoffDate as NSDate)
                        
                        let results = try self.context.fetch(request)
                        for entity in results {
                            self.context.delete(entity)
                        }
                        
                        try self.context.save()
                        
                        // Clear cache
                        self.cacheQueue.async {
                            self.calibrationCache.removeAll()
                        }
                        
                        print("🧹 Deleted \(results.count) old calibrations")
                        continuation.resume()
                    } catch {
                        continuation.resume(throwing: CalibrationRepositoryError.cleanupFailed(error))
                    }
                }
            }
        } catch {
            await MainActor.run {
                self.error = error as? CalibrationRepositoryError ?? .cleanupFailed(error)
            }
            throw error
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
    
    // MARK: - Statistics Methods
    func getCalibrationStatistics() async -> CalibrationStatistics {
        return await withCheckedContinuation { continuation in
            context.perform {
                do {
                    let request: NSFetchRequest<CalibrationEntity> = CalibrationEntity.fetchRequest()
                    request.predicate = NSPredicate(format: "isArchived == NO")
                    
                    let results = try self.context.fetch(request)
                    
                    var exerciseCounts: [ExerciseType: Int] = [:]
                    var qualityCounts: [CalibrationQuality: Int] = [:]
                    var totalScore: Float = 0
                    var totalConfidence: Float = 0
                    
                    for entity in results {
                        if let exerciseString = entity.exercise,
                           let exercise = ExerciseType(rawValue: exerciseString) {
                            exerciseCounts[exercise, default: 0] += 1
                        }
                        
                        let quality = entity.qualityLevel
                        qualityCounts[quality, default: 0] += 1
                        
                        totalScore += entity.calibrationScore
                        totalConfidence += entity.confidenceLevel
                    }
                    
                    let stats = CalibrationStatistics(
                        totalCalibrations: results.count,
                        exerciseCounts: exerciseCounts,
                        qualityCounts: qualityCounts,
                        averageScore: results.isEmpty ? 0 : totalScore / Float(results.count),
                        averageConfidence: results.isEmpty ? 0 : totalConfidence / Float(results.count),
                        usableCalibrations: results.filter { $0.isUsable }.count
                    )
                    
                    continuation.resume(returning: stats)
                } catch {
                    print("❌ Failed to fetch calibration statistics: \(error)")
                    continuation.resume(returning: CalibrationStatistics.empty)
                }
            }
        }
    }
    
    // MARK: - Migration from UserDefaults
    func migrateFromUserDefaults() async {
        print("🔄 Starting migration from UserDefaults...")
        
        let exercises: [ExerciseType] = [.pushup, .situp, .pullup]
        var migrationCount = 0
        
        for exercise in exercises {
            if let data = UserDefaults.standard.data(forKey: "calibration_\(exercise.rawValue)"),
               let calibration = try? JSONDecoder().decode(CalibrationData.self, from: data) {
                
                do {
                    try await saveCalibration(calibration)
                    
                    // Remove from UserDefaults after successful migration
                    UserDefaults.standard.removeObject(forKey: "calibration_\(exercise.rawValue)")
                    migrationCount += 1
                    
                    print("✅ Migrated calibration for \(exercise.displayName)")
                } catch {
                    print("❌ Failed to migrate calibration for \(exercise.displayName): \(error)")
                }
            }
        }
        
        print("🏁 Migration completed. Migrated \(migrationCount) calibrations.")
    }
    
    // MARK: - Private Helpers
    private func findExistingCalibration(_ id: UUID) -> CalibrationEntity? {
        let request: NSFetchRequest<CalibrationEntity> = CalibrationEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        do {
            return try context.fetch(request).first
        } catch {
            print("❌ Error finding existing calibration: \(error)")
            return nil
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