import Foundation

// Model for activity feed items that appear in the dashboard
public struct ActivityFeedItem: Identifiable {
    public let id = UUID()
    public let text: String
    public let date: Date
    public let icon: String
    public let metric: String?
    public let exerciseType: String
    
    public init(text: String, date: Date, icon: String, metric: String? = nil, exerciseType: String) {
        self.text = text
        self.date = date
        self.icon = icon
        self.metric = metric
        self.exerciseType = exerciseType
    }
}

// Helper to format dates relatively
public func relativeDateFormatter(date: Date) -> String {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .full
    return formatter.localizedString(for: date, relativeTo: Date())
}

// Sample Activity Data - can be used for previews and development
public struct ActivityFeedSamples {
    public static let items: [ActivityFeedItem] = [
        ActivityFeedItem(
            text: "Push-ups",
            date: Date().addingTimeInterval(-120),
            icon: "figure.strengthtraining.traditional",
            metric: "42 reps",
            exerciseType: "pushup"
        ),
        ActivityFeedItem(
            text: "Running",
            date: Date().addingTimeInterval(-3600 * 12),
            icon: "figure.run",
            metric: "3.2 km",
            exerciseType: "run"
        ),
        ActivityFeedItem(
            text: "Sit-ups",
            date: Date().addingTimeInterval(-3600 * 24),
            icon: "figure.core.training",
            metric: "35 reps",
            exerciseType: "situp"
        ),
        ActivityFeedItem(
            text: "Pull-ups",
            date: Date().addingTimeInterval(-3600 * 24 * 2),
            icon: "figure.pull.ups",
            metric: "12 reps",
            exerciseType: "pullup"
        ),
        ActivityFeedItem(
            text: "Push-ups",
            date: Date().addingTimeInterval(-3600 * 24 * 4),
            icon: "figure.strengthtraining.traditional",
            metric: "30 reps",
            exerciseType: "pushup"
        )
    ]
} 