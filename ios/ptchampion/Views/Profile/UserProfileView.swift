import SwiftUI
import PTDesignSystem

struct UserProfileView: View {
    @StateObject private var viewModel: UserProfileViewModel
    // The userID is passed to the ViewModel, so we might not need it directly in the View anymore
    // let userID: String 

    // Initialize the ViewModel
    init(userID: String) {
        // self.userID = userID // No longer storing userID directly if ViewModel handles it
        _viewModel = StateObject(wrappedValue: UserProfileViewModel(userID: userID, userService: MockUserService()))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if viewModel.userDetails.isLoading {
                    loadingView
                } else if let errorMessage = viewModel.userDetails.errorMessage {
                    errorView(message: errorMessage)
                } else {
                    headerView
                    Divider()
                    statsSectionView
                    Divider()
                    personalBestsSectionView
                    Divider()
                    recentActivitySectionView
                }
                Spacer() // Pushes content to the top if ScrollView has extra space
            }
            .padding()
        }
        .navigationTitle(viewModel.userDetails.isLoading ? "Loading Profile..." : viewModel.userDetails.userName)
        .navigationBarTitleDisplayMode(.inline)
        .background(AppTheme.GeneratedColors.background)
        .edgesIgnoringSafeArea(.all)
    }
    
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
            PTLabel("Loading profile...", style: .body)
                .padding(.top)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func errorView(message: String) -> some View {
        let view = VStack {
            Spacer()
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(AppTheme.GeneratedColors.error)
            PTLabel("Error", style: .body)
                .padding(.bottom, 2)
            PTLabel(message, style: .body)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        return view
    }

    private var headerView: some View {
        HStack(spacing: 15) {
            Image(systemName: "person.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 70, height: 70)
                .foregroundColor(AppTheme.GeneratedColors.textSecondary)
            
            VStack(alignment: .leading) {
                PTLabel(viewModel.userDetails.userName, style: .heading)
                PTLabel("Rank: \(viewModel.userDetails.rank)", style: .subheading)
                    .foregroundColor(AppTheme.GeneratedColors.textSecondary)
            }
            Spacer() // Pushes content to the left
        }
    }
    
    private var statsSectionView: some View {
        PTCard {
            VStack(alignment: .leading, spacing: 12) {
                PTLabel("Performance Stats", style: .body)
                    .padding(.bottom, 4)
                HStack(spacing: 12) {
                    StatCard(title: "Total Workouts", value: "\(viewModel.userDetails.totalWorkouts)", unit: "Sessions", color: .blue, iconName: "figure.walk")
                    StatCard(title: "Avg. Score", value: viewModel.userDetails.averageScore, unit: "Overall", color: .green, iconName: "star.leadinghalf.filled")
                }
                // TODO: Add more StatCards if applicable, e.g., Streak, Time Trained
            }
        }
    }
    
    private var personalBestsSectionView: some View {
        PTCard {
            VStack(alignment: .leading, spacing: 8) {
                PTLabel("Personal Bests", style: .body)
                    .padding(.bottom, 4)
                if viewModel.userDetails.personalBests.isEmpty {
                    PTLabel("No personal bests recorded yet.", style: .body)
                        .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                } else {
                    ForEach(viewModel.userDetails.personalBests, id: \.self) { (pb: String) in
                        HStack {
                            Image(systemName: "trophy.fill")
                                .foregroundColor(AppTheme.GeneratedColors.warning)
                            PTLabel(pb, style: .body)
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }
    
    private var recentActivitySectionView: some View {
        PTCard {
            VStack(alignment: .leading, spacing: 8) {
                PTLabel("Recent Activity", style: .body)
                    .padding(.bottom, 4)
                if viewModel.userDetails.recentActivity.isEmpty {
                    PTLabel("No recent activity to display.", style: .body)
                        .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                } else {
                    ForEach(viewModel.userDetails.recentActivity) { (activity: FormattedActivityItem) in
                        HStack(alignment: .top) {
                            Image(systemName: activity.iconName)
                                .foregroundColor(AppTheme.GeneratedColors.primary)
                                .frame(width: 20, alignment: .center) // Align icons
                            VStack(alignment: .leading) {
                                PTLabel(activity.description, style: .body)
                                PTLabel(activity.relativeDate, style: .caption)
                                    .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }
}

// No longer need local StatCard definition
// struct StatCard: View { ... }

#if DEBUG
struct UserProfileView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationView {
                UserProfileView(userID: "testUser123")
            }
            .previewDisplayName("Standard User")
            
            NavigationView {
                UserProfileView(userID: "emptyUser")
            }
            .previewDisplayName("Empty State")
            
            NavigationView {
                UserProfileView(userID: "errorUserID")
            }
            .previewDisplayName("Error State")
        }
        // .environmentObject(MockAuthViewModel()) // Temporarily commenting out to see if it resolves ambiguity
    }
}
#endif 