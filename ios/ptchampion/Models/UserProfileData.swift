import Foundation

struct UserProfileData: Identifiable {
    let id: String // Typically the userID
    let username: String
    let rank: String
    let totalWorkouts: Int
    let averageScore: Double // Example: 85.5 (representing %)
    let personalBests: [PersonalBestItem] // A list of personal bests
    let recentActivities: [ActivityItem] // A list of recent activities
}

struct PersonalBestItem: Identifiable {
    let id = UUID()
    let exerciseName: String
    let value: String // Example: "50 reps", "5km in 22:15"
}

struct ActivityItem: Identifiable {
    let id = UUID()
    let description: String
    let date: Date
    let iconName: String? // Optional: SFSymbol name for the activity
} 