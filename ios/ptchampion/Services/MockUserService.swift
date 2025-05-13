import Foundation
import Combine

class MockUserService: UserServiceProtocol {
    func fetchUserProfile(userID: String) -> AnyPublisher<UserProfileData, Error> {
        // Simulate a delay and different user states
        return Future<UserProfileData, Error> { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if userID == "errorUserID" {
                    promise(.failure(UserServiceError.userNotFound))
                } else if userID == "emptyUser" {
                    let emptyProfile = UserProfileData(
                        id: userID,
                        username: "User \(userID.prefix(6))",
                        rank: "Bronze I",
                        totalWorkouts: 0,
                        averageScore: 0.0,
                        personalBests: [],
                        recentActivities: []
                    )
                    promise(.success(emptyProfile))
                } else {
                    let mockProfile = UserProfileData(
                        id: userID,
                        username: "Mock User \(userID.prefix(6))",
                        rank: "Gold III",
                        totalWorkouts: Int.random(in: 20...100),
                        averageScore: Double.random(in: 70...95),
                        personalBests: [
                            PersonalBestItem(exerciseName: "Push-ups", value: "\(Int.random(in: 20...50)) reps"),
                            PersonalBestItem(exerciseName: "Running", value: "5km in 00:2\(Int.random(in: 3...8)):\(Int.random(in: 10...59))"),
                            PersonalBestItem(exerciseName: "Plank", value: "\(Int.random(in: 60...180)) sec")
                        ],
                        recentActivities: [
                            ActivityItem(description: "Completed Morning Run: 3 miles", date: Date().addingTimeInterval(-86400 * 1), iconName: "figure.run"),
                            ActivityItem(description: "Set new Pull-up Record: 15 reps", date: Date().addingTimeInterval(-86400 * 3), iconName: "figure.strengthtraining.traditional"),
                            ActivityItem(description: "Joined 'Push-up Masters' challenge", date: Date().addingTimeInterval(-86400 * 5), iconName: "star.fill")
                        ]
                    )
                    promise(.success(mockProfile))
                }
            }
        }
        .eraseToAnyPublisher()
    }
} 
