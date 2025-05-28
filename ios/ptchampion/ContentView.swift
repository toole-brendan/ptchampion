import SwiftUI
import PTDesignSystem // Assuming your custom components are here

struct ContentView: View {
    // ViewModels for each tab - initialize or inject as per your app's architecture
    // Using @StateObject for ViewModels owned by this view
    // Note: For a real app, consider how AuthViewModel is provided if it's truly global.
    // It might be better as an @EnvironmentObject injected from a higher level (e.g., App struct).
    @StateObject private var authViewModel = AuthViewModel() 
    @StateObject private var dashboardViewModel = DashboardViewModel()
    @StateObject private var leaderboardViewModel = LeaderboardViewModel()
    // You would also need @StateObject for WorkoutHistoryViewModel and potentially ProfileViewModel
    @StateObject private var workoutHistoryViewModel = WorkoutHistoryViewModel() // Assuming this exists
    // For ProfileView, if it's simple, it might not need its own ViewModel, or it might use AuthViewModel.
    @State private var showingStyleShowcase = false
    @State private var showingExerciseSelection = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("PT Champion")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(AppTheme.GeneratedColors.primary)
                
                Image(systemName: "medal.fill")
                    .font(.system(size: 80))
                    .foregroundColor(AppTheme.GeneratedColors.brassGold)
                    .padding(.bottom, 30)
                
                // Use conditional tracking for iOS compatibility
                militaryTitleText()
                    .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                
                Text("Powered by Computer Vision")
                    .militaryMonospaced(size: 14)
                    .foregroundColor(AppTheme.GeneratedColors.textTertiary)
                    .padding(.bottom, 40)
                
                VStack(spacing: 15) {
                    Button {
                        showingExerciseSelection = true
                    } label: {
                        Text("START WORKOUT")
                            .militaryMonospaced()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppTheme.GeneratedColors.primary)
                            .foregroundColor(AppTheme.GeneratedColors.textOnPrimary)
                            .cornerRadius(AppTheme.GeneratedRadius.button)
                    }
                    
                    Button {
                        showingStyleShowcase = true
                    } label: {
                        Text("VIEW MILITARY UI SHOWCASE")
                            .militaryMonospaced()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppTheme.GeneratedColors.secondary)
                            .foregroundColor(AppTheme.GeneratedColors.textOnSecondary)
                            .cornerRadius(AppTheme.GeneratedRadius.button)
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppTheme.GeneratedColors.background)
            .navigationTitle("PT Champion")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingStyleShowcase) {
                MilitaryStyleShowcase()
            }
            .fullScreenCover(isPresented: $showingExerciseSelection) {
                ExerciseSelectionView()
            }
        }
    }
    
    // Helper function to create the title text with conditional tracking
    @ViewBuilder
    private func militaryTitleText() -> some View {
        let baseText = Text("FITNESS EVALUATION SYSTEM")
            .militaryMonospaced()
            
        if #available(iOS 16.0, *) {
            baseText.tracking(2) // Military stencil look
        } else {
            baseText
        }
    }
}

#Preview {
    ContentView()
        // For previews to work correctly, especially if views use @EnvironmentObject,
        // you need to provide mock/real instances here.
        .environmentObject(AuthViewModel()) // Example
        // .modelContext(...) // If using SwiftData and any tab needs it directly or indirectly
} 