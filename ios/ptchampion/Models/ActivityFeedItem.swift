import Foundation

// Model for activity feed items that appear in the dashboard
public struct ActivityFeedItem: Identifiable {
    public let id = UUID()
    public let text: String
    public let date: Date
    public let icon: String
}

// Helper to format dates relatively
public func relativeDateFormatter(date: Date) -> String {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .full
    return formatter.localizedString(for: date, relativeTo: Date()
}

// Sample Activity Data - can be used for previews and development
public struct ActivityFeedSamples {
    public static let items: [ActivityFeedItem] = [
        ActivityFeedItem(text: "Completed Push-Up Challenge", date: Date().addingTimeInterval(-120), icon: "flame.fill"),
        ActivityFeedItem(text: "Set a new Personal Best in Sit-Ups", date: Date().addingTimeInterval(-3600 * 3), icon: "star.fill"),
        ActivityFeedItem(text: "Logged 5 workouts this week", date: Date().addingTimeInterval(-3600 * 24 * 2), icon: "figure.walk"),
        ActivityFeedItem(text: "Joined the 'Monthly Fitness' leaderboard", date: Date().addingTimeInterval(-3600 * 24 * 5), icon: "rosette")
    ]
} 