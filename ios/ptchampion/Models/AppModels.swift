import SwiftUI
import SwiftData

// USER MODEL
public struct User: Identifiable, Codable, Equatable {
    public var id: String
    public var email: String
    public var firstName: String
    public var lastName: String
    public var profilePictureUrl: String?
    
    public init(id: String, email: String, firstName: String, lastName: String, profilePictureUrl: String? = nil) {
        self.id = id
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.profilePictureUrl = profilePictureUrl
    }
}

// WORKOUT RESULT MODEL FOR SWIFTDATA
@Model
public final class WorkoutResultSwiftData {
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
public class AuthViewModel: ObservableObject {
    @Published public var isAuthenticated: Bool = false
    @Published public var currentUser: User?
    @Published public var isLoading: Bool = false
    @Published public var error: String?
    
    public init() { }
    
    // Minimal implementation needed to make the app compile
    public func logout() {
        isAuthenticated = false
        currentUser = nil
    }
} 