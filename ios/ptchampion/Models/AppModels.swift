import SwiftUI
import SwiftData

// USER MODEL - Using AuthUserModel from User.swift instead

// WORKOUT RESULT MODEL FOR SWIFTDATA - Renamed to avoid conflict
@Model
public final class WorkoutLegacyResult {
    @Attribute(.unique) public var id: String
    public var userId: String
    public var workoutType: String
    public var count: Int
    public var timestamp: Date
    public var duration: TimeInterval
    
    public init(id: String = UUID().uuidString, userId: String, workoutType: String, count: Int, timestamp: Date = Date(), duration: TimeInterval) {
        self.id = id
        self.userId = userId
        self.workoutType = workoutType
        self.count = count
        self.timestamp = timestamp
        self.duration = duration
    }
}

// AUTH VIEW MODEL
public class LegacyAuthViewModel: ObservableObject {
    @Published public var isAuthenticated: Bool = false
    @Published public var currentUser: AuthUserModel?
    @Published public var isLoading: Bool = false
    @Published public var error: String?
    
    public init() { }
    
    // Minimal implementation needed to make the app compile
    public func logout() {
        isAuthenticated = false
        currentUser = nil
    }
} 