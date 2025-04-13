import SwiftUI
import Combine

struct DashboardView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel = DashboardViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Welcome section
                if let user = authManager.currentUser {
                    welcomeSection(user: user)
                }
                
                // Performance card
                if viewModel.isLoading {
                    ProgressView()
                        .frame(height: 200)
                } else if !viewModel.latestExercises.isEmpty {
                    PerformanceCard(
                        latestExercises: viewModel.latestExercises,
                        overallScore: viewModel.overallScore
                    )
                    .padding(.horizontal)
                } else {
                    noPerformanceDataView()
                }
                
                // Exercise section
                exercisesSection()
                
                // Leaderboard section (compact version)
                leaderboardPreview()
            }
            .padding(.vertical)
        }
        .navigationTitle("PT Champion")
        .navigationBarItems(trailing: 
            Button(action: authManager.signOut) {
                Text("Sign Out")
            }
        )
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .onAppear {
            viewModel.loadData()
        }
        .refreshable {
            viewModel.loadData()
        }
    }
    
    private func welcomeSection(user: User) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Welcome, \(user.username)")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("Track your performance and improve your PT score")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }
    
    private func noPerformanceDataView() -> some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 40))
                .foregroundColor(.blue)
            
            Text("No Performance Data Yet")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Complete your first exercise to see your performance metrics")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    private func exercisesSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Exercises")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .padding(.horizontal)
            
            if viewModel.isLoading {
                ProgressView()
                    .frame(height: 100)
            } else if viewModel.exercises.isEmpty {
                Text("No exercises available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(viewModel.exercises) { exercise in
                    ExerciseCard(
                        exercise: exercise,
                        latestScore: viewModel.latestExercises[exercise.type.rawValue],
                        onTap: {
                            viewModel.navigateToExercise(exercise)
                        }
                    )
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
            }
        }
    }
    
    private func leaderboardPreview() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Leaderboard")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                NavigationLink(destination: LeaderboardView()) {
                    Text("See All")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            
            if viewModel.isLoading {
                ProgressView()
                    .frame(height: 100)
            } else if viewModel.leaderboard.isEmpty {
                Text("No leaderboard data available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                VStack(spacing: 0) {
                    // Header row
                    HStack {
                        Text("Rank")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 50, alignment: .center)
                        
                        Text("User")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text("Score")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 60, alignment: .trailing)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color(.systemBackground))
                    
                    Divider()
                    
                    // Top 3 users
                    ForEach(viewModel.leaderboard.prefix(3).indices, id: \.self) { index in
                        let entry = viewModel.leaderboard[index]
                        HStack {
                            Text("\(index + 1)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(index < 3 ? .blue : .primary)
                                .frame(width: 50, alignment: .center)
                            
                            Text(entry.username)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Text("\(entry.overallScore)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(scoreColor(for: entry.overallScore))
                                .frame(width: 60, alignment: .trailing)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                        .background(Color(.systemBackground))
                        
                        if index < 2 {
                            Divider()
                                .padding(.horizontal)
                        }
                    }
                }
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                .padding(.horizontal)
            }
        }
    }
    
    private func scoreColor(for score: Int) -> Color {
        switch score {
        case 90...100:
            return .green
        case 75..<90:
            return .blue
        case 60..<75:
            return .orange
        default:
            return .red
        }
    }
}

class DashboardViewModel: ObservableObject {
    @Published var exercises: [Exercise] = []
    @Published var latestExercises: [String: UserExercise] = [:]
    @Published var leaderboard: [LeaderboardEntry] = []
    @Published var isLoading = true
    @Published var errorMessage: String?
    
    var overallScore: Int {
        calculateOverallScore()
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    func loadData() {
        isLoading = true
        errorMessage = nil
        
        // Load exercises, latest scores, and leaderboard data in parallel
        Publishers.Zip3(
            loadExercises(),
            loadLatestExercises(),
            loadLeaderboard()
        )
        .receive(on: DispatchQueue.main)
        .sink(receiveCompletion: { [weak self] completion in
            self?.isLoading = false
            
            if case .failure(let error) = completion {
                self?.errorMessage = error.localizedDescription
            }
        }, receiveValue: { [weak self] (exercises, latestExercises, leaderboard) in
            self?.exercises = exercises
            self?.latestExercises = latestExercises
            self?.leaderboard = leaderboard
        })
        .store(in: &cancellables)
    }
    
    func navigateToExercise(_ exercise: Exercise) {
        // This will be implemented using navigation
        print("Navigate to exercise: \(exercise.name)")
    }
    
    private func loadExercises() -> AnyPublisher<[Exercise], Error> {
        return APIClient.shared.getExercises()
    }
    
    private func loadLatestExercises() -> AnyPublisher<[String: UserExercise], Error> {
        return APIClient.shared.getLatestUserExercises()
    }
    
    private func loadLeaderboard() -> AnyPublisher<[LeaderboardEntry], Error> {
        return APIClient.shared.getGlobalLeaderboard()
    }
    
    private func calculateOverallScore() -> Int {
        guard !latestExercises.isEmpty else { return 0 }
        
        var totalScore = 0
        var count = 0
        
        for (_, exercise) in latestExercises {
            if let grade = exercise.grade {
                totalScore += grade
                count += 1
            }
        }
        
        return count > 0 ? totalScore / count : 0
    }
}

struct LeaderboardEntry: Identifiable, Decodable {
    let id: Int
    let username: String
    let overallScore: Int
}

// Placeholder view
struct LeaderboardView: View {
    var body: some View {
        Text("Full Leaderboard View")
            .navigationTitle("Leaderboard")
    }
}

// Preview
struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DashboardView()
                .environmentObject(AuthManager())
        }
    }
}