import Foundation
import Combine

// Updated display details to include new stats
struct UserProfileDisplayDetails: Identifiable {
    let id = UUID() // This is for the View's list, separate from userID
    var userID: String = ""
    var userName: String = "Loading..."
    var rank: String = "N/A"
    var totalWorkouts: Int = 0
    var averageScore: String = "N/A" // Formatted for display
    var personalBests: [String] = [] // Formatted for display, e.g., ["Push-ups: 50 reps", "Run: 5km in 22:15"]
    var recentActivity: [FormattedActivityItem] = []
    var isLoading: Bool = true
    var errorMessage: String? = nil
}

struct FormattedActivityItem: Identifiable {
    let id = UUID()
    let description: String
    let relativeDate: String // e.g., "1 day ago", "Mar 15"
    let iconName: String
}

class UserProfileViewModel: ObservableObject {
    @Published var userDetails = UserProfileDisplayDetails()
    
    private let userID: String
    private let userService: UserServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    init(userID: String, userService: UserServiceProtocol) {
        self.userID = userID
        self.userService = userService
        self.userDetails.userID = userID // Initialize with userID for clarity
        fetchUserDetails()
    }

    func fetchUserDetails() {
        userDetails.isLoading = true
        userDetails.errorMessage = nil

        userService.fetchUserProfile(userID: userID)
            .receive(on: DispatchQueue.main)
            .sink {
                [weak self] completion in
                self?.userDetails.isLoading = false
                switch completion {
                case .failure(let error):
                    print("Error fetching user profile: \(error.localizedDescription)")
                    if let userServiceError = error as? UserServiceError {
                        self?.userDetails.errorMessage = userServiceError.localizedDescription
                    } else {
                        self?.userDetails.errorMessage = "An unexpected error occurred."
                    }
                    // Update userDetails to reflect error state
                    self?.userDetails.userName = "Error"
                    self?.userDetails.rank = "-"
                case .finished:
                    break
                }
            } receiveValue: { [weak self] profileData in
                self?.mapProfileDataToDisplayDetails(profileData)
            }
            .store(in: &cancellables)
    }

    private func mapProfileDataToDisplayDetails(_ data: UserProfileData) {
        let dateFormatter = RelativeDateTimeFormatter()
        dateFormatter.unitsStyle = .full

        let formattedPBs = data.personalBests.map { "\($0.exerciseName): \($0.value)" }
        let formattedActivities = data.recentActivities.map {
            FormattedActivityItem(
                description: $0.description,
                relativeDate: dateFormatter.localizedString(for: $0.date, relativeTo: Date(),
                iconName: $0.iconName ?? "figure.walk" // Default icon
            )
        }
        
        userDetails = UserProfileDisplayDetails(
            userID: data.id,
            userName: data.username,
            rank: data.rank,
            totalWorkouts: data.totalWorkouts,
            averageScore: String(format: "%.1f%%", data.averageScore), // Format as percentage string
            personalBests: formattedPBs,
            recentActivity: formattedActivities,
            isLoading: false,
            errorMessage: nil
        )
    }

    // Convenience for previews or when no service is needed initially
    // This might be removed if all previews use MockUserService
    convenience init(userID: String) {
        self.init(userID: userID, userService: MockUserService() // Default to MockUserService
        print("UserProfileViewModel initialized with default MockUserService for userID: \(userID)")
    }
} 