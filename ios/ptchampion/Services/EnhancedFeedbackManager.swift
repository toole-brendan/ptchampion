import Foundation
import Vision
import Combine
import SwiftUI
import AudioToolbox
#if canImport(UIKit)
import UIKit
#endif

/// Enhanced feedback manager that provides real-time visual and audio cues
class EnhancedFeedbackManager: ObservableObject {
    
    // MARK: - Feedback Types
    enum FeedbackType: Equatable {
        case formCorrection(message: String, severity: Severity)
        case repProgress(phase: String, progress: Float)
        case milestone(message: String)
        case encouragement(message: String)
        
        enum Severity: Equatable {
            case minor    // Yellow warning
            case major    // Orange warning
            case critical // Red warning
        }
    }
    
    // MARK: - Visual Feedback State
    @Published var currentFeedback: FeedbackType?
    @Published var formQualityScore: Float = 100.0
    @Published var currentPhaseProgress: Float = 0.0
    @Published var problemJoints: Set<VNHumanBodyPoseObservation.JointName> = []
    @Published var showFormQualityMeter: Bool = true
    @Published var showRepProgressArc: Bool = true
    
    // MARK: - Audio Settings
    @Published var isAudioEnabled: Bool = true
    @Published var hapticFeedbackEnabled: Bool = true
    
    // MARK: - Rep Tracking
    private var currentRepStartTime: Date?
    private var repDurations: [TimeInterval] = []
    private var formScores: [Float] = []
    
    // MARK: - Encouragement Messages
    private let encouragementMessages = [
        5: "Great start! Keep it up!",
        10: "Double digits! You're doing great!",
        15: "Halfway to 30! Stay strong!",
        20: "20 reps! Outstanding!",
        25: "25 and counting! Push through!",
        30: "30 reps! Military standard achieved!",
        40: "40 reps! You're crushing it!",
        50: "50 reps! Incredible performance!",
        60: "60 reps! Elite level!",
        70: "70 reps! You're a machine!",
        80: "80 reps! Maximum score territory!",
        90: "90 reps! Legendary!",
        100: "100 REPS! CHAMPION!"
    ]
    
    // MARK: - Form Quality Tracking
    private let formQualityThresholds = (
        excellent: Float(95.0),
        good: Float(85.0),
        acceptable: Float(75.0),
        poor: Float(60.0)
    )
    
    // MARK: - Public Methods
    
    /// Process rep completion and provide appropriate feedback
    func processRepCompletion(repCount: Int, formQuality: Float) {
        // Update form quality average
        formScores.append(formQuality)
        updateFormQualityScore()
        
        // Check for milestone
        if let encouragement = encouragementMessages[repCount] {
            provideFeedback(.milestone(message: encouragement))
            playMilestoneSound()
        }
        
        // Provide form-based feedback
        if formQuality < formQualityThresholds.poor {
            provideFeedback(.formCorrection(message: "Focus on form - quality over quantity", severity: .critical))
        } else if formQuality < formQualityThresholds.acceptable && repCount % 5 == 0 {
            provideFeedback(.formCorrection(message: "Maintain proper form", severity: .major))
        }
        
        // Track rep duration
        if let startTime = currentRepStartTime {
            let duration = Date().timeIntervalSince(startTime)
            repDurations.append(duration)
            
            // Provide pacing feedback
            if repDurations.count >= 3 {
                checkPacingAndProvideFeedback()
            }
        }
        currentRepStartTime = Date()
    }
    
    /// Update phase progress for visual feedback
    func updatePhaseProgress(phase: String, progress: Float) {
        currentPhaseProgress = progress
        
        // Provide phase-specific feedback
        switch phase.lowercased() {
        case "descending", "pulling", "rising":
            if progress > 0.8 && currentFeedback == nil {
                provideFeedback(.repProgress(phase: phase, progress: progress))
            }
        default:
            break
        }
    }
    
    /// Process form issues and provide correction feedback
    func processFormIssues(_ issues: [String], joints: Set<VNHumanBodyPoseObservation.JointName>) {
        problemJoints = joints
        
        if !issues.isEmpty {
            // Prioritize the most important issue
            if let primaryIssue = issues.first {
                let severity: FeedbackType.Severity = issues.count > 2 ? .critical : (issues.count > 1 ? .major : .minor)
                provideFeedback(.formCorrection(message: primaryIssue, severity: severity))
            }
            
            // Update form quality based on number of issues
            let qualityReduction = Float(issues.count) * 10.0
            formQualityScore = max(0, 100.0 - qualityReduction)
        } else {
            // No issues - gradually restore form quality
            formQualityScore = min(100.0, formQualityScore + 2.0)
            problemJoints.removeAll()
        }
    }
    
    /// Provide workout summary feedback
    func provideWorkoutSummary(totalReps: Int, avgFormQuality: Float, duration: TimeInterval) {
        let summary = generateWorkoutSummary(totalReps: totalReps, avgFormQuality: avgFormQuality, duration: duration)
        provideFeedback(.milestone(message: summary))
    }
    
    // MARK: - Private Methods
    
    private func provideFeedback(_ feedback: FeedbackType) {
        DispatchQueue.main.async {
            self.currentFeedback = feedback
            
            // Auto-clear feedback after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                if case feedback = self.currentFeedback ?? feedback {
                    self.currentFeedback = nil
                }
            }
        }
        
        // Provide haptic feedback for important events
        #if canImport(UIKit)
        if hapticFeedbackEnabled {
            switch feedback {
            case .milestone:
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            case .formCorrection(_, let severity):
                switch severity {
                case .critical:
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                case .major:
                    UINotificationFeedbackGenerator().notificationOccurred(.warning)
                case .minor:
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            default:
                break
            }
        }
        #endif
    }
    
    private func updateFormQualityScore() {
        guard !formScores.isEmpty else { return }
        
        // Calculate weighted average (recent scores weighted more heavily)
        let recentScores = Array(formScores.suffix(10))
        let weights = (1...recentScores.count).map { Float($0) }
        let weightedSum = zip(recentScores, weights).reduce(0) { $0 + ($1.0 * $1.1) }
        let totalWeight = weights.reduce(0, +)
        
        formQualityScore = weightedSum / totalWeight
    }
    
    private func checkPacingAndProvideFeedback() {
        let recentDurations = Array(repDurations.suffix(5))
        let avgDuration = recentDurations.reduce(0, +) / Double(recentDurations.count)
        
        // Check if pacing is too fast or too slow
        if avgDuration < 1.5 {
            provideFeedback(.formCorrection(message: "Slow down - control the movement", severity: .minor))
        } else if avgDuration > 4.0 {
            provideFeedback(.encouragement(message: "Pick up the pace - you've got this!"))
        }
    }
    
    private func generateWorkoutSummary(totalReps: Int, avgFormQuality: Float, duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        let timeString = String(format: "%d:%02d", minutes, seconds)
        
        var summary = "Workout Complete! "
        summary += "\(totalReps) reps in \(timeString). "
        
        if avgFormQuality >= formQualityThresholds.excellent {
            summary += "Excellent form throughout! 💪"
        } else if avgFormQuality >= formQualityThresholds.good {
            summary += "Good form maintained! 👍"
        } else if avgFormQuality >= formQualityThresholds.acceptable {
            summary += "Decent effort. Focus on form next time."
        } else {
            summary += "Remember: quality over quantity."
        }
        
        return summary
    }
    
    // MARK: - Audio Feedback
    
    private func playMilestoneSound() {
        guard isAudioEnabled else { return }
        
        // Play a pleasant chime for milestones
        AudioServicesPlaySystemSound(1057) // Tweet sound
    }
    
    func playRepCompletionSound() {
        guard isAudioEnabled else { return }
        
        // Play a subtle tick for each rep
        AudioServicesPlaySystemSound(1104)
    }
    
    func playWarningSound() {
        guard isAudioEnabled else { return }
        
        // Play warning sound for form issues
        AudioServicesPlaySystemSound(1073)
    }
    
    // MARK: - Reset
    
    func reset() {
        currentFeedback = nil
        formQualityScore = 100.0
        currentPhaseProgress = 0.0
        problemJoints.removeAll()
        currentRepStartTime = nil
        repDurations.removeAll()
        formScores.removeAll()
    }
}

// MARK: - Feedback Display View
struct FeedbackDisplayView: View {
    @ObservedObject var feedbackManager: EnhancedFeedbackManager
    
    var body: some View {
        VStack(spacing: 16) {
            // Current feedback message
            if let feedback = feedbackManager.currentFeedback {
                feedbackMessageView(for: feedback)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            // Form quality meter
            if feedbackManager.showFormQualityMeter {
                FormQualityMeter(score: feedbackManager.formQualityScore)
            }
            
            // Rep progress arc
            if feedbackManager.showRepProgressArc && feedbackManager.currentPhaseProgress > 0 {
                RepProgressArc(progress: feedbackManager.currentPhaseProgress)
            }
        }
        .animation(.spring(), value: feedbackManager.currentFeedback != nil)
    }
    
    @ViewBuilder
    private func feedbackMessageView(for feedback: EnhancedFeedbackManager.FeedbackType) -> some View {
        let (message, color, icon) = feedbackContent(for: feedback)
        
        HStack {
            Image(systemName: icon)
                .font(.system(size: 20))
            Text(message)
                .font(.system(size: 16, weight: .medium))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(color.opacity(0.9))
        )
        .shadow(radius: 5)
    }
    
    private func feedbackContent(for feedback: EnhancedFeedbackManager.FeedbackType) -> (String, Color, String) {
        switch feedback {
        case .formCorrection(let message, let severity):
            let color: Color = {
                switch severity {
                case .critical: return .red
                case .major: return .orange
                case .minor: return .yellow
                }
            }()
            return (message, color, "exclamationmark.triangle.fill")
            
        case .repProgress(let phase, _):
            return ("Keep going - \(phase)", .blue, "arrow.right.circle.fill")
            
        case .milestone(let message):
            return (message, .green, "star.fill")
            
        case .encouragement(let message):
            return (message, .purple, "hand.thumbsup.fill")
        }
    }
}

// MARK: - Form Quality Meter View
struct FormQualityMeter: View {
    let score: Float
    
    private var color: Color {
        if score >= 95 { return .green }
        else if score >= 85 { return .yellow }
        else if score >= 75 { return .orange }
        else { return .red }
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Text("Form Quality")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.gray)
            
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 150, height: 8)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(color)
                    .frame(width: 150 * CGFloat(score / 100), height: 8)
            }
            
            Text("\(Int(score))%")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(color)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.7))
        )
    }
}

// MARK: - Rep Progress Arc View
struct RepProgressArc: View {
    let progress: Float
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                .frame(width: 60, height: 60)
            
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(Color.green, lineWidth: 8)
                .frame(width: 60, height: 60)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.1), value: progress)
            
            Text("\(Int(progress * 100))%")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(8)
        .background(
            Circle()
                .fill(Color.black.opacity(0.7))
        )
    }
}
