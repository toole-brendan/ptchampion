import SwiftUI

struct LeaderboardView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    // Sample data for the leaderboard
    let leaderboardEntries = [
        LeaderboardEntry(rank: 1, name: "John Doe", score: 150),
        LeaderboardEntry(rank: 2, name: "Jane Smith", score: 145),
        LeaderboardEntry(rank: 3, name: "Alex Johnson", score: 140),
        LeaderboardEntry(rank: 4, name: "Sam Wilson", score: 135),
        LeaderboardEntry(rank: 5, name: "Pat Brown", score: 130)
    ]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(leaderboardEntries) { entry in
                    HStack {
                        Text("#\(entry.rank)")
                            .font(.headline)
                            .frame(width: 40)
                        
                        Text(entry.name)
                            .font(.body)
                        
                        Spacer()
                        
                        Text("\(entry.score)")
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Leaderboard")
        }
    }
}

struct LeaderboardEntry: Identifiable {
    let id = UUID()
    let rank: Int
    let name: String
    let score: Int
}

#Preview {
    LeaderboardView()
        .environmentObject(AuthViewModel())
} 