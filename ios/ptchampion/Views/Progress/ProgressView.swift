import SwiftUI
import Charts // Assuming iOS 16+ for Swift Charts

struct ProgressView: View {
    // Define constants directly within the view
    fileprivate struct Constants {
        static let globalPadding: CGFloat = 16
        static let cardGap: CGFloat = 12
        static let cardCornerRadius: CGFloat = 8
    }
    
    @StateObject private var viewModel = ProgressViewModel()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: Constants.cardGap) {
                    Text("Your Progress")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding([.horizontal, .bottom], Constants.globalPadding)

                    // Placeholder Chart Section
                    // TODO: Replace with actual chart implementation using viewModel.workoutHistory data
                    VStack(alignment: .leading) {
                        Text("Workout Trends") // Example Title
                            .font(.headline)
                        PlaceholderChartView()
                            .frame(height: 200)
                    }
                    .padding()
                    .background(Color(red: 0.957, green: 0.945, blue: 0.902))
                    .cornerRadius(Constants.cardCornerRadius)
                    .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
                    .padding(.horizontal, Constants.globalPadding)

                    // History List Section
                    Text("Workout History")
                        .font(.headline)
                        .padding(.top)
                        .padding(.horizontal, Constants.globalPadding)

                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding(Constants.globalPadding)
                            .frame(maxWidth: .infinity)
                    } else if viewModel.workoutHistory.isEmpty {
                        Text("No workout history found. Complete a workout to see your progress!")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(Constants.globalPadding)
                            .frame(maxWidth: .infinity)
                    } else {
                        // Use LazyVStack for potentially long lists
                        LazyVStack(spacing: Constants.cardGap) {
                            ForEach(viewModel.workoutHistory) { record in
                                // Convert UserExerciseRecord to WorkoutResultSwiftData
                                let swiftDataRecord = WorkoutResultSwiftData(
                                    exerciseType: record.exerciseTypeKey,
                                    startTime: record.createdAt,
                                    endTime: record.createdAt.addingTimeInterval(Double(record.timeInSeconds ?? 0)),
                                    durationSeconds: record.timeInSeconds ?? 0,
                                    repCount: record.repetitions,
                                    score: record.grade.map { Double($0) },
                                    distanceMeters: nil // Extract from metadata if needed
                                )
                                WorkoutHistoryRow(result: swiftDataRecord)
                            }
                        }
                        .padding(.horizontal, Constants.globalPadding)
                    }

                    Spacer()
                }
                .padding(.bottom) // Add padding at the very bottom
            }
            .background(Color(red: 0.957, green: 0.945, blue: 0.902).ignoresSafeArea())
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.fetchHistory()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(viewModel.isLoading)
                    .foregroundColor(Color(red: 0.749, green: 0.635, blue: 0.302)) // Approximation of brassGold
                }
            }
            // Use .task for initial fetch if preferred over init
            // .task { await viewModel.fetchHistory() }
        }
    }
}

// Example Placeholder Chart (replace with actual implementation)
struct PlaceholderChartView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: ProgressView.Constants.cardCornerRadius)
                .fill(Color.gray.opacity(0.1))
            Text("Chart Area")
                .foregroundColor(.secondary)
        }
        // Apply chart styling from Theme.swift when implementing
    }
}

#Preview {
    ProgressView()
} 