import SwiftUI
import Charts // Assuming iOS 16+ for Swift Charts

struct ProgressView: View {
    @StateObject private var viewModel = ProgressViewModel()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: AppConstants.cardGap) {
                    Text("Your Progress")
                        .headingStyle()
                        .padding([.horizontal, .bottom], AppConstants.globalPadding)

                    // Placeholder Chart Section
                    // TODO: Replace with actual chart implementation using viewModel.workoutHistory data
                    VStack(alignment: .leading) {
                        Text("Workout Trends") // Example Title
                            .subheadingStyle()
                        PlaceholderChartView()
                            .frame(height: 200)
                    }
                    .cardStyle()
                    .padding(.horizontal, AppConstants.globalPadding)

                    // History List Section
                    Text("Workout History")
                        .subheadingStyle()
                        .padding(.top)
                        .padding(.horizontal, AppConstants.globalPadding)

                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding(AppConstants.globalPadding)
                            .frame(maxWidth: .infinity)
                    } else if viewModel.workoutHistory.isEmpty {
                        Text("No workout history found. Complete a workout to see your progress!")
                            .foregroundColor(.tacticalGray)
                            .multilineTextAlignment(.center)
                            .padding(AppConstants.globalPadding)
                            .frame(maxWidth: .infinity)
                    } else {
                        // Use LazyVStack for potentially long lists
                        LazyVStack(spacing: AppConstants.cardGap) {
                            ForEach(viewModel.workoutHistory) { record in
                                WorkoutHistoryRow(record: record)
                            }
                        }
                        .padding(.horizontal, AppConstants.globalPadding)
                    }

                    Spacer()
                }
                .padding(.bottom) // Add padding at the very bottom
            }
            .background(Color.tacticalCream.ignoresSafeArea())
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
                    .foregroundColor(.brassGold)
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
            RoundedRectangle(cornerRadius: AppConstants.cardCornerRadius)
                .fill(Color.gray.opacity(0.1))
            Text("Chart Area")
                .foregroundColor(.tacticalGray)
        }
        // Apply chart styling from Theme.swift when implementing
    }
}

// Updated History Row to use WorkoutRecord
struct WorkoutHistoryRow: View {
    let record: WorkoutRecord
    // Inject ViewModel or pass formatter if needed, using static here for simplicity
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none // Just show date for brevity?
        return formatter
    }()

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(record.exerciseType)
                    .font(.headline)
                    .foregroundColor(.commandBlack)
                Text(Self.dateFormatter.string(from: record.startTime))
                    .labelStyle()
            }
            Spacer()
            // Display reps or duration based on type
            if let reps = record.repCount {
                Text("\(reps) reps")
                    .statsNumberStyle(size: 16)
            } else {
                // Format duration (e.g., from seconds to mm:ss)
                let durationFormatted = String(format: "%d:%02d", record.durationSeconds / 60, record.durationSeconds % 60)
                Text(durationFormatted)
                     .statsNumberStyle(size: 16)
            }
            // Optional: Display score if available
            // if let score = record.score {
            //     Text("\(score) pts").labelStyle()
            // }
        }
        .padding()
        .cardStyle()
    }
}

#Preview {
    ProgressView()
} 