import SwiftUI
import Combine

struct HistoryView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel = HistoryViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Performance")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Track your progress over time")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top)
                
                // Exercise type filter
                exerciseFilterSection
                
                // History records
                if viewModel.isLoading {
                    ProgressView()
                        .padding(.top, 50)
                } else if viewModel.filteredHistory.isEmpty {
                    emptyStateView
                } else {
                    recordsList
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("History")
        .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
        .onAppear {
            viewModel.loadUserExercises()
        }
        .sheet(item: $viewModel.selectedRecord) { record in
            ExerciseDetailView(userExercise: record, exercise: viewModel.getExercise(for: record))
        }
    }
    
    private var exerciseFilterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                FilterButton(
                    title: "All",
                    isSelected: viewModel.selectedType == nil,
                    action: { viewModel.selectedType = nil }
                )
                
                ForEach(ExerciseType.allCases, id: \.self) { type in
                    FilterButton(
                        title: type.displayName,
                        isSelected: viewModel.selectedType == type,
                        action: { viewModel.selectedType = type }
                    )
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 50))
                .foregroundColor(.blue)
                .padding()
            
            Text("No history records")
                .font(.headline)
            
            if viewModel.selectedType != nil {
                Text("You haven't completed any \(viewModel.selectedType?.displayName ?? "") exercises yet.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            } else {
                Text("Start tracking your exercises to see your progress here.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 50)
    }
    
    private var recordsList: some View {
        LazyVStack(spacing: 16) {
            ForEach(viewModel.filteredHistory, id: \.id) { record in
                HistoryCard(
                    userExercise: record,
                    exercise: viewModel.getExercise(for: record)
                )
                .padding(.horizontal)
                .onTapGesture {
                    viewModel.selectedRecord = record
                }
            }
        }
    }
}

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

struct HistoryCard: View {
    let userExercise: UserExercise
    let exercise: Exercise?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with exercise type and date
            HStack {
                if let exercise = exercise {
                    Image(systemName: exercise.type.iconName)
                        .font(.system(size: 18))
                        .foregroundColor(.blue)
                    
                    Text(exercise.name)
                        .font(.headline)
                }
                
                Spacer()
                
                Text(formatDate(userExercise.createdAt))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemBackground))
            
            Divider()
            
            // Details
            VStack(spacing: 12) {
                // Performance row: reps/time, grade, etc
                HStack(spacing: 20) {
                    if let exercise = exercise {
                        // Exercise metric (reps or time)
                        HStack(spacing: 10) {
                            Image(systemName: metricIcon(for: exercise.type))
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading) {
                                Text(metricLabel(for: exercise.type))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text(metricValue(for: userExercise, exerciseType: exercise.type))
                                    .font(.headline)
                            }
                        }
                        
                        Spacer()
                        
                        // Grade
                        HStack(spacing: 10) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            
                            VStack(alignment: .leading) {
                                Text("Grade")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                if let grade = userExercise.grade {
                                    Text("\(grade)/100")
                                        .font(.headline)
                                        .foregroundColor(gradeColor(grade))
                                } else {
                                    Text("N/A")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    } else {
                        Text("Exercise details not available")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                // Form score/feedback
                if let formScore = userExercise.formScore, formScore > 0 {
                    HStack(spacing: 10) {
                        Image(systemName: "figure.walk")
                            .foregroundColor(.green)
                        
                        VStack(alignment: .leading) {
                            Text("Form Score")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("\(formScore)/100")
                                .font(.subheadline)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                }
                
                // Metadata if available
                if let metadata = userExercise.metadata, !metadata.isEmpty {
                    if let feedback = metadata["feedback"], !feedback.isEmpty {
                        HStack(spacing: 10) {
                            Image(systemName: "text.bubble")
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading) {
                                Text("Feedback")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text(feedback)
                                    .font(.subheadline)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                    }
                }
            }
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
        }
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func metricIcon(for exerciseType: ExerciseType) -> String {
        switch exerciseType {
        case .pushup, .situp, .pullup:
            return "number"
        case .run:
            return "clock"
        }
    }
    
    private func metricLabel(for exerciseType: ExerciseType) -> String {
        switch exerciseType {
        case .pushup, .situp, .pullup:
            return "Repetitions"
        case .run:
            return "Time"
        }
    }
    
    private func metricValue(for userExercise: UserExercise, exerciseType: ExerciseType) -> String {
        switch exerciseType {
        case .pushup, .situp, .pullup:
            return "\(userExercise.repetitions ?? 0) reps"
        case .run:
            if let seconds = userExercise.timeInSeconds {
                let minutes = seconds / 60
                let remainingSeconds = seconds % 60
                return "\(minutes):\(String(format: "%02d", remainingSeconds))"
            } else {
                return "N/A"
            }
        }
    }
    
    private func gradeColor(_ grade: Int) -> Color {
        switch grade {
        case 90...100:
            return .green
        case 75..<90:
            return .blue
        case 60..<75:
            return .orange
        case 40..<60:
            return .yellow
        default:
            return .red
        }
    }
}

struct ExerciseDetailView: View {
    let userExercise: UserExercise
    let exercise: Exercise?
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Exercise header
                    if let exercise = exercise {
                        VStack(spacing: 8) {
                            Image(systemName: exercise.type.iconName)
                                .font(.system(size: 50))
                                .foregroundColor(.blue)
                                .padding(.bottom, 8)
                            
                            Text(exercise.name)
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Text(exercise.description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                    }
                    
                    // Performance details
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Performance Details")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        // Performance metrics
                        if let exercise = exercise {
                            VStack(spacing: 0) {
                                // Date
                                DetailRow(
                                    label: "Date",
                                    value: formatDate(userExercise.createdAt),
                                    icon: "calendar"
                                )
                                
                                Divider()
                                    .padding(.leading, 40)
                                
                                // Exercise specific metric
                                DetailRow(
                                    label: metricLabel(for: exercise.type),
                                    value: metricValue(for: userExercise, exerciseType: exercise.type),
                                    icon: metricIcon(for: exercise.type)
                                )
                                
                                Divider()
                                    .padding(.leading, 40)
                                
                                // Grade
                                DetailRow(
                                    label: "Grade",
                                    value: userExercise.grade != nil ? "\(userExercise.grade!)/100" : "N/A",
                                    icon: "star.fill"
                                )
                                
                                if let formScore = userExercise.formScore, formScore > 0 {
                                    Divider()
                                        .padding(.leading, 40)
                                    
                                    DetailRow(
                                        label: "Form Score",
                                        value: "\(formScore)/100",
                                        icon: "figure.walk"
                                    )
                                }
                            }
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                        }
                    }
                    
                    // Feedback
                    if let metadata = userExercise.metadata, let feedback = metadata["feedback"], !feedback.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Feedback")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            Text(feedback)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                        }
                    }
                    
                    // Performance rating
                    if let grade = userExercise.grade {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Performance Rating")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            VStack(spacing: 12) {
                                Text(gradeToRating(grade))
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(gradeColor(grade))
                                
                                Text(ratingDescription(grade))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                        }
                    }
                }
                .padding()
            }
            .navigationBarTitle("Exercise Details", displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
            .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func metricIcon(for exerciseType: ExerciseType) -> String {
        switch exerciseType {
        case .pushup, .situp, .pullup:
            return "number.circle.fill"
        case .run:
            return "clock.fill"
        }
    }
    
    private func metricLabel(for exerciseType: ExerciseType) -> String {
        switch exerciseType {
        case .pushup, .situp, .pullup:
            return "Repetitions"
        case .run:
            return "Time"
        }
    }
    
    private func metricValue(for userExercise: UserExercise, exerciseType: ExerciseType) -> String {
        switch exerciseType {
        case .pushup, .situp, .pullup:
            return "\(userExercise.repetitions ?? 0) repetitions"
        case .run:
            if let seconds = userExercise.timeInSeconds {
                let minutes = seconds / 60
                let remainingSeconds = seconds % 60
                return "\(minutes) minutes \(remainingSeconds) seconds"
            } else {
                return "N/A"
            }
        }
    }
    
    private func gradeColor(_ grade: Int) -> Color {
        switch grade {
        case 90...100:
            return .green
        case 75..<90:
            return .blue
        case 60..<75:
            return .orange
        case 40..<60:
            return .yellow
        default:
            return .red
        }
    }
    
    private func gradeToRating(_ grade: Int) -> String {
        switch grade {
        case 90...100:
            return "Excellent"
        case 75..<90:
            return "Good"
        case 60..<75:
            return "Satisfactory"
        case 40..<60:
            return "Marginal"
        default:
            return "Poor"
        }
    }
    
    private func ratingDescription(_ grade: Int) -> String {
        switch grade {
        case 90...100:
            return "Outstanding performance, exceeding standards"
        case 75..<90:
            return "Above average performance, meeting standards comfortably"
        case 60..<75:
            return "Meets minimum standards, but needs improvement"
        case 40..<60:
            return "Below standards, requires significant improvement"
        default:
            return "Well below standards, requires immediate attention"
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.blue)
                .frame(width: 24)
            
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
    }
}

class HistoryViewModel: ObservableObject {
    @Published var userExercises: [UserExercise] = []
    @Published var exercises: [Exercise] = []
    @Published var isLoading = true
    @Published var selectedType: ExerciseType?
    @Published var selectedRecord: UserExercise?
    
    private var cancellables = Set<AnyCancellable>()
    
    var filteredHistory: [UserExercise] {
        guard let type = selectedType else {
            return userExercises.sorted(by: { $0.createdAt > $1.createdAt })
        }
        
        // Find exercises of the selected type
        let exerciseIds = exercises
            .filter { $0.type == type }
            .map { $0.id }
        
        // Filter user exercises by those exercise IDs
        return userExercises
            .filter { exerciseIds.contains($0.exerciseId) }
            .sorted(by: { $0.createdAt > $1.createdAt })
    }
    
    func loadUserExercises() {
        isLoading = true
        
        // Load exercises and user exercise history in parallel
        Publishers.Zip(
            APIClient.shared.getExercises(),
            APIClient.shared.getUserExercises()
        )
        .receive(on: DispatchQueue.main)
        .sink(receiveCompletion: { [weak self] completion in
            self?.isLoading = false
            
            if case .failure(let error) = completion {
                print("Error loading history: \(error.localizedDescription)")
            }
        }, receiveValue: { [weak self] (exercises, userExercises) in
            self?.exercises = exercises
            self?.userExercises = userExercises
            self?.isLoading = false
        })
        .store(in: &cancellables)
    }
    
    func getExercise(for userExercise: UserExercise) -> Exercise? {
        return exercises.first { $0.id == userExercise.exerciseId }
    }
}

// Preview
struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            HistoryView()
                .environmentObject(AuthManager())
        }
    }
}