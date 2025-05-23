import Foundation
import Combine
import Vision
import UIKit

/// View model for APFT-compliant workout sessions using enhanced graders
class APFTWorkoutViewModel: ObservableObject {
    
    // MARK: - Enhanced Graders
    @Published var pushupGrader = EnhancedPushupGrader()
    @Published var pullupGrader = EnhancedPullupGrader()
    @Published var situpGrader = EnhancedSitupGrader()
    
    // MARK: - Current Exercise State
    @Published var currentExercise: ExerciseType = .pushup
    @Published var isWorkoutActive: Bool = false
    @Published var workoutDuration: TimeInterval = 0
    
    // MARK: - Real-time Feedback
    @Published var currentFeedback: String = ""
    @Published var currentPhase: String = ""
    @Published var repCount: Int = 0
    @Published var formIssues: [String] = []
    @Published var problemJoints: Set<VNHumanBodyPoseObservation.JointName> = []
    
    // MARK: - Workout Results
    @Published var finalScores: [ExerciseType: Double] = [:]
    @Published var totalReps: [ExerciseType: Int] = [:]
    @Published var formQuality: [ExerciseType: Double] = [:]
    
    // MARK: - Timer
    private var workoutTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupGraderObservation()
    }
    
    // MARK: - Setup
    private func setupGraderObservation() {
        // Observe pushup grader changes
        pushupGrader.objectWillChange
            .sink { [weak self] _ in
                self?.updateUIFromCurrentGrader()
            }
            .store(in: &cancellables)
        
        // Observe pullup grader changes
        pullupGrader.objectWillChange
            .sink { [weak self] _ in
                self?.updateUIFromCurrentGrader()
            }
            .store(in: &cancellables)
        
        // Observe situp grader changes
        situpGrader.objectWillChange
            .sink { [weak self] _ in
                self?.updateUIFromCurrentGrader()
            }
            .store(in: &cancellables)
    }
    
    private func updateUIFromCurrentGrader() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            switch self.currentExercise {
            case .pushup:
                self.repCount = self.pushupGrader.repCount
                self.currentPhase = self.pushupGrader.currentPhaseDescription
                self.currentFeedback = self.pushupGrader.getDetailedFeedback()
                self.formIssues = self.pushupGrader.pushupFormIssues
                self.problemJoints = self.pushupGrader.problemJoints
                
            case .pullup:
                self.repCount = self.pullupGrader.repCount
                self.currentPhase = self.pullupGrader.currentPhaseDescription
                self.currentFeedback = self.pullupGrader.getDetailedFeedback()
                self.formIssues = self.pullupGrader.pullupFormIssues
                self.problemJoints = self.pullupGrader.problemJoints
                
            case .situp:
                self.repCount = self.situpGrader.repCount
                self.currentPhase = self.situpGrader.currentPhaseDescription
                self.currentFeedback = self.situpGrader.getDetailedFeedback()
                self.formIssues = self.situpGrader.situpFormIssues
                self.problemJoints = self.situpGrader.problemJoints
            default:
                break
            }
        }
    }
    
    // MARK: - Workout Control
    func startWorkout(exercise: ExerciseType) {
        currentExercise = exercise
        isWorkoutActive = true
        workoutDuration = 0
        
        // Reset the appropriate grader
        switch exercise {
        case .pushup:
            pushupGrader.resetState()
        case .pullup:
            pullupGrader.resetState()
        case .situp:
            situpGrader.resetState()
        default:
            break
        }
        
        // Start timer
        startTimer()
        
        print("APFT Workout started for \(exercise)")
    }
    
    func pauseWorkout() {
        isWorkoutActive = false
        stopTimer()
    }
    
    func resumeWorkout() {
        isWorkoutActive = true
        startTimer()
    }
    
    func stopWorkout() {
        isWorkoutActive = false
        stopTimer()
        
        // Calculate final scores
        calculateFinalScores()
        
        print("APFT Workout stopped. Final score: \(finalScores[currentExercise] ?? 0)")
    }
    
    func switchExercise(to exercise: ExerciseType) {
        // Save current exercise results
        saveCurrentExerciseResults()
        
        // Switch to new exercise
        currentExercise = exercise
        
        // Reset new exercise grader
        switch exercise {
        case .pushup:
            pushupGrader.resetState()
        case .pullup:
            pullupGrader.resetState()
        case .situp:
            situpGrader.resetState()
        default:
            break
        }
        
        updateUIFromCurrentGrader()
        print("Switched to \(exercise)")
    }
    
    // MARK: - Pose Processing
    func processDetectedBody(_ body: DetectedBody) {
        guard isWorkoutActive else { return }
        
        switch currentExercise {
        case .pushup:
            let result = pushupGrader.gradePose(body: body)
            handleGradingResult(result)
            
        case .pullup:
            let result = pullupGrader.gradePose(body: body)
            handleGradingResult(result)
            
        case .situp:
            let result = situpGrader.gradePose(body: body)
            handleGradingResult(result)
            
        default:
            break
        }
    }
    
    private func handleGradingResult(_ result: GradingResult) {
        switch result {
        case .repCompleted(let formQuality):
            // Handle successful rep
            handleRepCompleted(formQuality: formQuality)
            
        case .incorrectForm(let feedback):
            // Update UI with form feedback
            currentFeedback = feedback
            
        case .inProgress(let phase):
            // Update phase information
            currentPhase = phase ?? "In Progress"
            
        case .invalidPose(let reason):
            currentFeedback = reason
            
        case .noChange:
            // No update needed
            break
        }
    }
    
    private func handleRepCompleted(formQuality: Double) {
        // Provide haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Update UI
        currentFeedback = "Great rep! Keep going."
        
        // Log the rep
        print("Rep completed with form quality: \(formQuality)")
    }
    
    // MARK: - Timer Management
    private func startTimer() {
        workoutTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.workoutDuration += 1
        }
    }
    
    private func stopTimer() {
        workoutTimer?.invalidate()
        workoutTimer = nil
    }
    
    // MARK: - Results Management
    private func saveCurrentExerciseResults() {
        switch currentExercise {
        case .pushup:
            totalReps[.pushup] = pushupGrader.repCount
            formQuality[.pushup] = pushupGrader.formQualityAverage
        case .pullup:
            totalReps[.pullup] = pullupGrader.repCount
            formQuality[.pullup] = pullupGrader.formQualityAverage
        case .situp:
            totalReps[.situp] = situpGrader.repCount
            formQuality[.situp] = situpGrader.formQualityAverage
        default:
            break
        }
    }
    
    private func calculateFinalScores() {
        saveCurrentExerciseResults()
        
        // Calculate APFT scores for each exercise
        for exercise in [ExerciseType.pushup, .pullup, .situp] {
            if let reps = totalReps[exercise] {
                let score = ScoreRubrics.score(for: exercise, reps: reps)
                finalScores[exercise] = Double(score)
            }
        }
    }
    
    // MARK: - Configuration
    func configurePullupBar(height: Float) {
        pullupGrader.setBarHeight(height)
    }
    
    func useOutdoorPullupBar() {
        pullupGrader = EnhancedPullupGrader.forOutdoorBar()
        setupGraderObservation()
    }
    
    func useIndoorPullupBar() {
        pullupGrader = EnhancedPullupGrader.forIndoorBar()
        setupGraderObservation()
    }
    
    // MARK: - Performance Metrics
    func getRepProgress() -> Double {
        switch currentExercise {
        case .pushup:
            return pushupGrader.getRepProgress()
        case .pullup:
            return pullupGrader.getRepProgress()
        case .situp:
            return situpGrader.getRepProgress()
        default:
            return 0.0
        }
    }
    
    func getCurrentFormScore() -> Double {
        switch currentExercise {
        case .pushup:
            return pushupGrader.formQualityAverage
        case .pullup:
            return pullupGrader.formQualityAverage
        case .situp:
            return situpGrader.formQualityAverage
        default:
            return 0.0
        }
    }
    
    func getEstimatedAPFTScore() -> Int {
        let totalScore = finalScores.values.reduce(0, +)
        return Int(totalScore)
    }
    
    // MARK: - Cleanup
    deinit {
        stopTimer()
        cancellables.forEach { $0.cancel() }
    }
}

// MARK: - Helper Extensions
extension APFTWorkoutViewModel {
    
    /// Get military fitness standards feedback
    func getMilitaryStandardsFeedback() -> String {
        let reps = repCount
        let exercise = currentExercise
        
        // Provide feedback based on military standards
        switch exercise {
        case .pushup:
            if reps >= 77 { return "Outstanding! Maximum APFT score!" }
            else if reps >= 60 { return "Excellent performance!" }
            else if reps >= 42 { return "Good, keep pushing!" }
            else if reps >= 31 { return "Passing standard met" }
            else { return "Below minimum standard" }
            
        case .pullup:
            if reps >= 20 { return "Outstanding! Maximum score!" }
            else if reps >= 15 { return "Excellent performance!" }
            else if reps >= 10 { return "Good, keep going!" }
            else if reps >= 6 { return "Passing standard met" }
            else { return "Below minimum standard" }
            
        case .situp:
            if reps >= 78 { return "Outstanding! Maximum score!" }
            else if reps >= 60 { return "Excellent performance!" }
            else if reps >= 42 { return "Good, keep going!" }
            else if reps >= 32 { return "Passing standard met" }
            else { return "Below minimum standard" }
            
        default:
            return ""
        }
    }
    
    /// Check if current performance meets minimum military standards
    var meetsMinimumStandard: Bool {
        switch currentExercise {
        case .pushup: return repCount >= 31
        case .pullup: return repCount >= 6
        case .situp: return repCount >= 32
        default: return false
        }
    }
} 