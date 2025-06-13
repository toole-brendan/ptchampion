//
//  USMCPFTViewModel.swift
//  ptchampion
//
//  USMC PFT Workout View Model
//  Handles Marine Corps Physical Fitness Test workout sessions
//

import Foundation
import SwiftUI
import Combine

@MainActor
class USMCPFTViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var currentExercise: ExerciseType = .pushup
    @Published var totalReps: [ExerciseType: Int] = [:]
    @Published var finalScores: [ExerciseType: Double] = [:]
    @Published var workoutDuration: TimeInterval = 0
    @Published var isWorkoutActive = false
    @Published var exercisePhase: ExercisePhase = .notStarted
    @Published var currentRepCount = 0
    @Published var detectedBodyParts: Set<String> = []
    @Published var feedbackMessage = ""
    @Published var exerciseScore: Double = 0
    @Published var formScore: Double = 0
    @Published var plankHoldTime: TimeInterval = 0
    @Published var isPlankActive = false
    
    // User profile (needed for age/gender-based scoring)
    @Published var userAge: Int = 25  // Default age
    @Published var userGender: String = "male"  // Default gender
    
    // MARK: - Private Properties
    
    private var workoutTimer: Timer?
    private var plankTimer: Timer?
    private let workoutService = WorkoutService.shared
    private let graderFactory = ExerciseGraderFactory()
    
    // Graders for each exercise
    private var pushupGrader: ExerciseGraderProtocol?
    private var pullupGrader: ExerciseGraderProtocol?
    private var plankGrader: ExerciseGraderProtocol?
    
    // Exercise tracking
    private var exerciseStartTime: Date?
    private var workoutStartTime: Date?
    
    // MARK: - Exercise Phase
    
    enum ExercisePhase {
        case notStarted
        case calibrating
        case ready
        case active
        case resting
        case completed
    }
    
    // MARK: - Initialization
    
    init() {
        setupGraders()
        loadUserProfile()
    }
    
    private func setupGraders() {
        pushupGrader = graderFactory.createGrader(for: .pushup)
        pullupGrader = graderFactory.createGrader(for: .pullup)
        plankGrader = graderFactory.createGrader(for: .plank)
    }
    
    private func loadUserProfile() {
        // TODO: Load actual user profile from storage/service
        // For now, using defaults
    }
    
    // MARK: - Workout Control
    
    func startWorkout() {
        isWorkoutActive = true
        workoutStartTime = Date()
        exercisePhase = .calibrating
        
        // Start workout timer
        workoutTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            Task { @MainActor in
                self.updateWorkoutDuration()
            }
        }
        
        // Initialize current exercise
        switchToExercise(currentExercise)
    }
    
    func stopWorkout() {
        isWorkoutActive = false
        exercisePhase = .completed
        workoutTimer?.invalidate()
        plankTimer?.invalidate()
        
        calculateFinalScores()
        saveWorkoutResults()
    }
    
    func pauseWorkout() {
        exercisePhase = .resting
        if currentExercise == .plank {
            plankTimer?.invalidate()
        }
    }
    
    func resumeWorkout() {
        exercisePhase = .active
        if currentExercise == .plank && isPlankActive {
            startPlankTimer()
        }
    }
    
    // MARK: - Exercise Management
    
    func switchToExercise(_ exercise: ExerciseType) {
        // Save current exercise results
        saveCurrentExerciseResults()
        
        // Stop plank timer if switching from plank
        if currentExercise == .plank {
            plankTimer?.invalidate()
            isPlankActive = false
        }
        
        // Update current exercise
        currentExercise = exercise
        exerciseStartTime = Date()
        currentRepCount = 0
        exercisePhase = .calibrating
        
        // Reset appropriate grader
        switch exercise {
        case .pushup:
            pushupGrader?.resetState()
        case .pullup:
            pullupGrader?.resetState()
        case .plank:
            plankGrader?.resetState()
            plankHoldTime = 0
        default:
            break
        }
        
        // Provide feedback
        feedbackMessage = "Get ready for \(exercise.displayName)"
    }
    
    // MARK: - Pose Detection Processing
    
    func processDetectedBody(_ bodyParts: [String: CGPoint]) {
        detectedBodyParts = Set(bodyParts.keys)
        
        guard exercisePhase == .active else { return }
        
        switch currentExercise {
        case .pushup:
            processPushupPose(bodyParts)
        case .pullup:
            processPullupPose(bodyParts)
        case .plank:
            processPlankPose(bodyParts)
        default:
            break
        }
    }
    
    private func processPushupPose(_ bodyParts: [String: CGPoint]) {
        guard let grader = pushupGrader else { return }
        
        let result = grader.processBodyPosition(bodyParts)
        
        if result.isRep {
            currentRepCount += 1
            totalReps[.pushup, default: 0] += 1
            feedbackMessage = "Rep \(currentRepCount) - \(result.feedback)"
        } else {
            feedbackMessage = result.feedback
        }
        
        formScore = result.formScore
    }
    
    private func processPullupPose(_ bodyParts: [String: CGPoint]) {
        guard let grader = pullupGrader else { return }
        
        let result = grader.processBodyPosition(bodyParts)
        
        if result.isRep {
            currentRepCount += 1
            totalReps[.pullup, default: 0] += 1
            feedbackMessage = "Rep \(currentRepCount) - \(result.feedback)"
        } else {
            feedbackMessage = result.feedback
        }
        
        formScore = result.formScore
    }
    
    private func processPlankPose(_ bodyParts: [String: CGPoint]) {
        guard let grader = plankGrader else { return }
        
        let result = grader.processBodyPosition(bodyParts)
        
        if result.isValidPosition {
            if !isPlankActive {
                // Start plank timer
                isPlankActive = true
                startPlankTimer()
                feedbackMessage = "Hold position!"
            }
            formScore = result.formScore
        } else {
            if isPlankActive {
                // Stop plank timer if form breaks
                isPlankActive = false
                plankTimer?.invalidate()
                feedbackMessage = "Form break - reset position"
            } else {
                feedbackMessage = result.feedback
            }
            formScore = 0
        }
    }
    
    // MARK: - Plank Timer
    
    private func startPlankTimer() {
        plankTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            Task { @MainActor in
                self.plankHoldTime += 0.1
                
                // Update score in real-time
                let seconds = Int(self.plankHoldTime)
                self.exerciseScore = Double(USMCPFTScoring.scorePlank(seconds: seconds))
                
                // Check if max time reached (3:45 = 225 seconds)
                if seconds >= 225 {
                    self.plankTimer?.invalidate()
                    self.isPlankActive = false
                    self.feedbackMessage = "Maximum time reached! Great job!"
                }
            }
        }
    }
    
    // MARK: - Scoring
    
    private func calculateFinalScores() {
        saveCurrentExerciseResults()
        
        // Calculate scores using USMC PFT standards
        
        // Push-ups (max 70 points)
        if let pushupReps = totalReps[.pushup] {
            let score = USMCPFTScoring.scorePushups(
                reps: pushupReps,
                age: userAge,
                gender: userGender
            )
            finalScores[.pushup] = Double(score)
        }
        
        // Pull-ups (max 100 points)
        if let pullupReps = totalReps[.pullup] {
            let score = USMCPFTScoring.scorePullups(
                reps: pullupReps,
                age: userAge,
                gender: userGender
            )
            finalScores[.pullup] = Double(score)
        }
        
        // Plank (max 100 points)
        let plankSeconds = Int(plankHoldTime)
        let plankScore = USMCPFTScoring.scorePlank(seconds: plankSeconds)
        finalScores[.plank] = Double(plankScore)
        totalReps[.plank] = plankSeconds  // Store seconds as "reps" for consistency
    }
    
    private func saveCurrentExerciseResults() {
        // Save results for the current exercise before switching
        if exercisePhase == .active {
            switch currentExercise {
            case .plank:
                // Plank results are continuously updated
                break
            default:
                // Other exercises already update totalReps in real-time
                break
            }
        }
    }
    
    // MARK: - Workout Persistence
    
    private func saveWorkoutResults() {
        Task {
            do {
                // Save each exercise result
                for (exercise, score) in finalScores {
                    let reps = totalReps[exercise] ?? 0
                    let duration = exercise == .plank ? Int(plankHoldTime) : nil
                    
                    let request = CreateWorkoutRequest(
                        exerciseType: exercise,
                        repetitions: exercise == .plank ? nil : reps,
                        durationSeconds: duration,
                        formScore: Int(formScore),
                        grade: Int(score),
                        isPublic: false,
                        completedAt: Date()
                    )
                    
                    try await workoutService.createWorkout(request)
                }
            } catch {
                print("Failed to save workout results: \(error)")
            }
        }
    }
    
    // MARK: - Timer Updates
    
    private func updateWorkoutDuration() {
        guard let startTime = workoutStartTime else { return }
        workoutDuration = Date().timeIntervalSince(startTime)
    }
    
    // MARK: - Utility Methods
    
    func getTotalScore() -> Int {
        // Calculate total PFT score
        // Note: Users must choose either push-ups OR pull-ups
        let pushupScore = Int(finalScores[.pushup] ?? 0)
        let pullupScore = Int(finalScores[.pullup] ?? 0)
        let plankScore = Int(finalScores[.plank] ?? 0)
        let runScore = 0  // Run is handled separately in RunWorkoutViewModel
        
        return USMCPFTScoring.calculateTotalScore(
            pushups: pushupScore > 0 ? pushupScore : nil,
            pullups: pullupScore > 0 ? pullupScore : nil,
            plank: plankScore,
            run: runScore
        )
    }
    
    func getPerformanceClass() -> String {
        let totalScore = getTotalScore()
        return USMCPFTScoring.getPerformanceClass(totalScore: totalScore)
    }
    
    deinit {
        workoutTimer?.invalidate()
        plankTimer?.invalidate()
    }
} 