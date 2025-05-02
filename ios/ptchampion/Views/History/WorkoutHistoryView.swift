import SwiftUI
import SwiftData

struct WorkoutHistoryView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Query private var workoutResults: [WorkoutResultSwiftData]
    
    var body: some View {
        NavigationView {
            List {
                if workoutResults.isEmpty {
                    Text("No workout history yet")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    ForEach(workoutResults) { result in
                        WorkoutHistoryRow(result: result)
                    }
                }
            }
            .navigationTitle("Workout History")
        }
    }
}

struct WorkoutHistoryRow: View {
    let result: WorkoutResultSwiftData
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(result.workoutType)
                .font(.headline)
            
            HStack {
                Text("Count: \(result.count)")
                Spacer()
                Text(result.timestamp, style: .date)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    WorkoutHistoryView()
        .environmentObject(AuthViewModel())
} 