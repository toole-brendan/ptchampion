import SwiftUI

/// Real-time feedback overlay that displays form corrections and guidance during exercises
struct RealTimeFeedbackOverlay: View {
    @ObservedObject var feedbackManager: RealTimeFeedbackManager
    let showDetailedFeedback: Bool
    let compactMode: Bool
    
    init(feedbackManager: RealTimeFeedbackManager, showDetailedFeedback: Bool = true, compactMode: Bool = false) {
        self.feedbackManager = feedbackManager
        self.showDetailedFeedback = showDetailedFeedback
        self.compactMode = compactMode
    }
    
    var body: some View {
        ZStack {
            if feedbackManager.isActive {
                VStack(spacing: 0) {
                    // Top HUD with essential info
                    FeedbackHUD(
                        formScore: feedbackManager.formScore,
                        repCount: feedbackManager.repCount,
                        phase: feedbackManager.exercisePhase,
                        compactMode: compactMode
                    )
                    .padding(.top, compactMode ? 10 : 20)
                    
                    Spacer()
                    
                    // Center area for critical errors and corrections
                    if showDetailedFeedback {
                        VStack(spacing: 16) {
                            // Critical errors (always visible)
                            if !feedbackManager.criticalErrors.isEmpty {
                                CriticalErrorAlert(errors: feedbackManager.criticalErrors)
                                    .transition(.scale.combined(with: .opacity))
                            }
                            
                            // Real-time corrections
                            if !feedbackManager.currentFeedback.corrections.isEmpty {
                                FormCorrectionCard(corrections: feedbackManager.currentFeedback.corrections)
                                    .transition(.slide.combined(with: .opacity))
                            }
                        }
                        .animation(.easeInOut(duration: 0.3), value: feedbackManager.criticalErrors.count)
                        .animation(.easeInOut(duration: 0.3), value: feedbackManager.currentFeedback.corrections.count)
                    }
                    
                    Spacer()
                    
                    // Bottom feedback panel
                    if showDetailedFeedback && !compactMode {
                        FeedbackBottomPanel(
                            suggestions: feedbackManager.suggestions,
                            formScore: feedbackManager.formScore,
                            phase: feedbackManager.exercisePhase
                        )
                        .padding(.bottom, 20)
                    }
                }
                
                // Visual cues overlay
                if showDetailedFeedback {
                    VisualCuesOverlay(feedback: feedbackManager.currentFeedback)
                }
            }
        }
    }
}

// MARK: - Feedback HUD

/// Compact heads-up display showing essential exercise metrics
struct FeedbackHUD: View {
    let formScore: Float
    let repCount: Int
    let phase: String
    let compactMode: Bool
    
    var body: some View {
        HStack(spacing: compactMode ? 8 : 16) {
            // Rep counter
            HUDMetric(
                icon: "number.circle",
                value: "\(repCount)",
                label: "Reps",
                color: .blue,
                compactMode: compactMode
            )
            
            if !compactMode {
                Divider()
                    .frame(height: 20)
                    .background(Color.white.opacity(0.3))
            }
            
            // Form score
            HUDMetric(
                icon: "target",
                value: "\(Int(formScore * 100))",
                label: "Form",
                color: formScoreColor,
                compactMode: compactMode
            )
            
            if !compactMode {
                Divider()
                    .frame(height: 20)
                    .background(Color.white.opacity(0.3))
                
                // Exercise phase
                HUDMetric(
                    icon: phaseIcon,
                    value: phase.capitalized,
                    label: "Phase",
                    color: phaseColor,
                    compactMode: compactMode
                )
            }
        }
        .padding(.horizontal, compactMode ? 12 : 20)
        .padding(.vertical, compactMode ? 8 : 12)
        .background(
            RoundedRectangle(cornerRadius: compactMode ? 8 : 12)
                .fill(Color.black.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: compactMode ? 8 : 12)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .padding(.horizontal)
    }
    
    private var formScoreColor: Color {
        switch formScore {
        case 0.8...1.0: return .green
        case 0.6..<0.8: return .white
        case 0.4..<0.6: return .orange
        default: return .red
        }
    }
    
    private var phaseIcon: String {
        switch phase.lowercased() {
        case "up", "down": return "arrow.up.arrow.down"
        case "ascending", "rising": return "arrow.up"
        case "descending", "lowering": return "arrow.down"
        case "pulling": return "arrow.up.circle"
        default: return "circle"
        }
    }
    
    private var phaseColor: Color {
        switch phase.lowercased() {
        case "up", "ascending", "rising": return .green
        case "down", "descending", "lowering": return .blue
        case "pulling": return .purple
        default: return .gray
        }
    }
}

struct HUDMetric: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    let compactMode: Bool
    
    var body: some View {
        VStack(spacing: compactMode ? 2 : 4) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(compactMode ? .caption : .title3)
            
            Text(value)
                .font(compactMode ? .caption : .headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            if !compactMode {
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .frame(minWidth: compactMode ? 40 : 60)
    }
}

// MARK: - Critical Error Alert

/// Prominent alert for critical form errors that require immediate attention
struct CriticalErrorAlert: View {
    let errors: [FeedbackError]
    
    var body: some View {
        VStack(spacing: 12) {
            // Alert header
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                    .font(.title2)
                
                Text("Form Error")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                // Pulsing indicator
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
                    .scaleEffect(1.0)
                    .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: errors.count)
            }
            
            // Error messages
            ForEach(errors.prefix(2)) { error in
                Text(error.message)
                    .font(.body)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.red.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.red, lineWidth: 2)
                )
        )
        .padding(.horizontal)
    }
}

// MARK: - Form Correction Card

/// Card displaying real-time form corrections with visual cues
struct FormCorrectionCard: View {
    let corrections: [FormCorrection]
    
    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Image(systemName: "target")
                    .foregroundColor(.orange)
                    .font(.title3)
                
                Text("Form Correction")
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            // Corrections
            ForEach(corrections.prefix(2), id: \.message) { correction in
                CorrectionRow(correction: correction)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.orange.opacity(0.6), lineWidth: 1)
                )
        )
        .padding(.horizontal)
    }
}

struct CorrectionRow: View {
    let correction: FormCorrection
    
    var body: some View {
        HStack(spacing: 12) {
            // Correction type icon
            Image(systemName: correctionIcon)
                .foregroundColor(severityColor)
                .font(.title3)
                .frame(width: 24)
            
            // Correction message
            Text(correction.message)
                .font(.body)
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
            
            Spacer()
            
            // Visual cue indicator
            if let visualCue = correction.visualCue {
                Image(systemName: visualCueIcon(visualCue))
                    .foregroundColor(.blue)
                    .font(.caption)
            }
        }
    }
    
    private var correctionIcon: String {
        switch correction.type {
        case .bodyAlignment: return "figure.walk"
        case .rangeOfMotion: return "arrow.up.arrow.down"
        case .timing: return "clock"
        case .stability: return "gyroscope"
        case .positioning: return "location"
        }
    }
    
    private var severityColor: Color {
        switch correction.severity {
        case .info: return .blue
        case .medium: return .white
        case .warning: return .orange
        case .high: return .orange
        case .critical: return .red
        }
    }
    
    private func visualCueIcon(_ cue: VisualCueType) -> String {
        switch cue {
        case .bodyLineIndicator: return "line.diagonal"
        case .armExtensionIndicator: return "arrow.up"
        case .depthIndicator: return "arrow.down"
        case .angleGuide: return "angle"
        case .rangeMarker: return "ruler"
        }
    }
}

// MARK: - Bottom Feedback Panel

/// Bottom panel showing suggestions and additional feedback
struct FeedbackBottomPanel: View {
    let suggestions: [FeedbackSuggestion]
    let formScore: Float
    let phase: String
    
    var body: some View {
        VStack(spacing: 12) {
            // Form score bar
            FormScoreBar(score: formScore)
            
            // Suggestions (if any)
            if !suggestions.isEmpty {
                SuggestionsRow(suggestions: suggestions)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .padding(.horizontal)
    }
}

struct FormScoreBar: View {
    let score: Float
    
    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text("Form Quality")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                Text("\(Int(score * 100))%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 4)
                    
                    // Progress
                    RoundedRectangle(cornerRadius: 2)
                        .fill(scoreColor)
                        .frame(width: geometry.size.width * CGFloat(score), height: 4)
                        .animation(.easeInOut(duration: 0.3), value: score)
                }
            }
            .frame(height: 4)
        }
    }
    
    private var scoreColor: Color {
        switch score {
        case 0.8...1.0: return .green
        case 0.6..<0.8: return .white
        case 0.4..<0.6: return .orange
        default: return .red
        }
    }
}

struct SuggestionsRow: View {
    let suggestions: [FeedbackSuggestion]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(suggestions.prefix(3)) { suggestion in
                    SuggestionChip(suggestion: suggestion)
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

struct SuggestionChip: View {
    let suggestion: FeedbackSuggestion
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: suggestionIcon)
                .font(.caption2)
                .foregroundColor(priorityColor)
            
            Text(suggestion.message)
                .font(.caption)
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(priorityColor.opacity(0.2))
                .overlay(
                    Capsule()
                        .stroke(priorityColor.opacity(0.5), lineWidth: 1)
                )
        )
    }
    
    private var suggestionIcon: String {
        switch suggestion.type {
        case .form: return "figure.walk"
        case .technique: return "gear"
        case .range: return "arrow.up.arrow.down"
        case .stability: return "gyroscope"
        case .positioning: return "location"
        }
    }
    
    private var priorityColor: Color {
        switch suggestion.priority {
        case .low: return .blue
        case .medium: return .orange
        case .high: return .red
        }
    }
}

// MARK: - Visual Cues Overlay

/// Overlay providing visual cues and indicators for form corrections
struct VisualCuesOverlay: View {
    let feedback: ExerciseFeedback
    
    var body: some View {
        ZStack {
            // Visual cues for active corrections
            ForEach(feedback.corrections.compactMap(\.visualCue), id: \.self) { cue in
                VisualCueView(cue: cue)
            }
        }
    }
}

struct VisualCueView: View {
    let cue: VisualCueType
    
    var body: some View {
        switch cue {
        case .bodyLineIndicator:
            BodyLineIndicator()
        case .armExtensionIndicator:
            ArmExtensionIndicator()
        case .depthIndicator:
            DepthIndicator()
        case .angleGuide:
            AngleGuideIndicator()
        case .rangeMarker:
            RangeMarkerIndicator()
        @unknown default:
            EmptyView()
        }
    }
}

// MARK: - Individual Visual Cue Components

struct BodyLineIndicator: View {
    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                Spacer()
                
                // Vertical reference line
                Rectangle()
                    .fill(Color.blue.opacity(0.6))
                    .frame(width: 2, height: 200)
                    .overlay(
                        VStack(spacing: 40) {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 8, height: 8)
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 8, height: 8)
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 8, height: 8)
                        }
                    )
                
                Spacer()
            }
            
            Spacer()
        }
    }
}

struct ArmExtensionIndicator: View {
    var body: some View {
        VStack {
            HStack {
                Spacer()
                
                VStack(spacing: 4) {
                    Image(systemName: "arrow.up")
                        .foregroundColor(.green)
                        .font(.title2)
                        .scaleEffect(1.0)
                        .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: UUID())
                    
                    Text("Extend Arms")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.green.opacity(0.8))
                        )
                }
                
                Spacer()
            }
            .padding(.top, 100)
            
            Spacer()
        }
    }
}

struct DepthIndicator: View {
    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                VStack(spacing: 4) {
                    Image(systemName: "arrow.down")
                        .foregroundColor(.orange)
                        .font(.title2)
                        .scaleEffect(1.0)
                        .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: UUID())
                    
                    Text("Go Deeper")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.orange.opacity(0.8))
                        )
                }
                .padding(.leading, 20)
                
                Spacer()
            }
            
            Spacer()
        }
    }
}

struct AngleGuideIndicator: View {
    var body: some View {
        VStack {
            HStack {
                Spacer()
                
                // Angle guide visualization
                ZStack {
                    // Arc showing target angle
                    Circle()
                        .trim(from: 0, to: 0.25)
                        .stroke(Color.blue.opacity(0.6), lineWidth: 3)
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                    
                    // Target angle indicator
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 6, height: 6)
                        .offset(x: 30, y: 0)
                }
                .padding(.trailing, 40)
                .padding(.top, 80)
                
                Spacer()
            }
            
            Spacer()
        }
    }
}

struct RangeMarkerIndicator: View {
    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                Spacer()
                
                // Range markers
                VStack(spacing: 20) {
                    // Upper marker
                    HStack {
                        Rectangle()
                            .fill(Color.green)
                            .frame(width: 40, height: 2)
                        Text("Target")
                            .font(.caption2)
                            .foregroundColor(.white)
                    }
                    
                    // Lower marker
                    HStack {
                        Rectangle()
                            .fill(Color.red)
                            .frame(width: 40, height: 2)
                        Text("Current")
                            .font(.caption2)
                            .foregroundColor(.white)
                    }
                }
                .padding(.trailing, 20)
                
                Spacer()
            }
            
            Spacer()
        }
    }
}

// MARK: - Preview

struct RealTimeFeedbackOverlay_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Normal mode
            RealTimeFeedbackOverlay(
                feedbackManager: createMockFeedbackManager(),
                showDetailedFeedback: true,
                compactMode: false
            )
            .background(Color.black)
            .previewDisplayName("Normal Mode")
            
            // Compact mode
            RealTimeFeedbackOverlay(
                feedbackManager: createMockFeedbackManager(),
                showDetailedFeedback: true,
                compactMode: true
            )
            .background(Color.black)
            .previewDisplayName("Compact Mode")
        }
    }
    
    static func createMockFeedbackManager() -> RealTimeFeedbackManager {
        let poseDetector = PoseDetectorService()
        let validator = APFTRepValidator()
        let manager = RealTimeFeedbackManager(poseDetectorService: poseDetector, apftValidator: validator)
        
        // Set some mock data
        manager.isActive = true
        return manager
    }
}
