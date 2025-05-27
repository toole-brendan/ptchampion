import SwiftUI

/*
 * CalibrationOverlayViews.swift
 * 
 * CURRENT ARCHITECTURE:
 * - AdaptiveCalibrationGuide: Main full-screen zone-based guide (NEW)
 * - PositioningGuideOverlay: Updated to use AdaptiveCalibrationGuide
 * - Body Outline Components: Still active (used by AdaptiveCalibrationGuide)
 * - SuggestionsCard: Still active (used by AdaptiveCalibrationGuide)
 * 
 * LEGACY COMPONENTS (Commented out):
 * - FramingGuideBox: Replaced by AdaptiveCalibrationGuide
 * - StatusDot: No longer needed
 */

// MARK: - Positioning Guide Overlay

/// Overlay that guides users to position themselves correctly for calibration
struct PositioningGuideOverlay: View {
    let currentFraming: FramingStatus
    let targetFraming: TargetFraming
    let suggestions: [CalibrationSuggestion]
    
    var body: some View {
        // Use the new adaptive guide instead of the old components
        AdaptiveCalibrationGuide(
            framing: currentFraming,
            exerciseType: targetFraming.exercise,
            suggestions: suggestions
        )
    }
}

// MARK: - Legacy FramingGuideBox (Replaced by AdaptiveCalibrationGuide)
// This component has been replaced by AdaptiveCalibrationGuide for better orientation support
// Keeping commented for reference:

/*
/// Visual guide showing optimal body positioning (LEGACY - use AdaptiveCalibrationGuide instead)
struct FramingGuideBox: View {
    let framing: FramingStatus
    let exerciseType: ExerciseType
    
    var body: some View {
        // This has been replaced by AdaptiveCalibrationGuide
        AdaptiveCalibrationGuide(
            framing: framing,
            exerciseType: exerciseType,
            suggestions: []
        )
    }
}
*/

// MARK: - Body Outline Components (ACTIVE - Used by AdaptiveCalibrationGuide)

/// Exercise-specific body outline for positioning guidance
struct ExerciseBodyOutline: View {
    let exercise: ExerciseType
    
    var body: some View {
        switch exercise {
        case .pushup:
            PushupBodyOutline()
        case .situp:
            SitupBodyOutline()
        case .pullup:
            PullupBodyOutline()
        default:
            DefaultBodyOutline()
        }
    }
}

struct PushupBodyOutline: View {
    var body: some View {
        VStack(spacing: 8) { // Increased spacing
            // Head
            Circle()
                .frame(width: 40, height: 40) // Doubled from 20
            
            // Torso and arms
            ZStack {
                // Torso
                RoundedRectangle(cornerRadius: 8)
                    .frame(width: 24, height: 120) // Doubled dimensions
                
                // Arms
                HStack(spacing: 80) { // Doubled spacing
                    RoundedRectangle(cornerRadius: 4)
                        .frame(width: 8, height: 60) // Doubled
                    RoundedRectangle(cornerRadius: 4)
                        .frame(width: 8, height: 60)
                }
                .offset(y: -30)
            }
            
            // Legs
            HStack(spacing: 16) { // Doubled spacing
                RoundedRectangle(cornerRadius: 4)
                    .frame(width: 8, height: 100) // Doubled
                RoundedRectangle(cornerRadius: 4)
                    .frame(width: 8, height: 100)
            }
        }
    }
}

struct SitupBodyOutline: View {
    var body: some View {
        VStack(spacing: 8) { // Increased spacing
            // Head
            Circle()
                .frame(width: 40, height: 40) // Doubled from 20
            
            // Torso
            RoundedRectangle(cornerRadius: 8)
                .frame(width: 24, height: 80) // Doubled dimensions
            
            // Bent legs
            HStack(spacing: 16) { // Doubled spacing
                VStack(spacing: 4) { // Doubled spacing
                    RoundedRectangle(cornerRadius: 4)
                        .frame(width: 8, height: 50) // Doubled
                        .rotationEffect(.degrees(30))
                    RoundedRectangle(cornerRadius: 4)
                        .frame(width: 8, height: 40) // Doubled
                        .rotationEffect(.degrees(-30))
                }
                VStack(spacing: 4) { // Doubled spacing
                    RoundedRectangle(cornerRadius: 4)
                        .frame(width: 8, height: 50) // Doubled
                        .rotationEffect(.degrees(-30))
                    RoundedRectangle(cornerRadius: 4)
                        .frame(width: 8, height: 40) // Doubled
                        .rotationEffect(.degrees(30))
                }
            }
        }
    }
}

struct PullupBodyOutline: View {
    var body: some View {
        VStack(spacing: 8) { // Increased spacing
            // Arms reaching up
            HStack(spacing: 60) { // Doubled spacing
                RoundedRectangle(cornerRadius: 4)
                    .frame(width: 8, height: 70) // Doubled
                    .rotationEffect(.degrees(-20))
                RoundedRectangle(cornerRadius: 4)
                    .frame(width: 8, height: 70) // Doubled
                    .rotationEffect(.degrees(20))
            }
            
            // Head
            Circle()
                .frame(width: 40, height: 40) // Doubled from 20
            
            // Torso
            RoundedRectangle(cornerRadius: 8)
                .frame(width: 24, height: 100) // Doubled dimensions
            
            // Legs
            HStack(spacing: 16) { // Doubled spacing
                RoundedRectangle(cornerRadius: 4)
                    .frame(width: 8, height: 90) // Doubled
                RoundedRectangle(cornerRadius: 4)
                    .frame(width: 8, height: 90) // Doubled
            }
        }
    }
}

struct DefaultBodyOutline: View {
    var body: some View {
        VStack(spacing: 8) {
            Circle()
                .frame(width: 40, height: 40)
            RoundedRectangle(cornerRadius: 8)
                .frame(width: 24, height: 120)
            HStack(spacing: 16) {
                RoundedRectangle(cornerRadius: 4)
                    .frame(width: 8, height: 100)
                RoundedRectangle(cornerRadius: 4)
                    .frame(width: 8, height: 100)
            }
        }
    }
}

// MARK: - Legacy StatusDot (No longer used)
// This component was used by the old FramingGuideBox and is no longer needed

/*
struct StatusDot: View {
    let color: Color
    
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: 1)
            )
    }
}
*/

// MARK: - Analyzing View

/// View shown during the analysis phase
struct AnalyzingView: View {
    let progress: Double
    
    var body: some View {
        VStack(spacing: 24) {
            // Animated scanning indicator
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 4)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: CGFloat(progress))
                    .stroke(Color.blue, lineWidth: 4)
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.1), value: progress)
                
                VStack(spacing: 4) {
                    Image(systemName: "camera.metering.spot")
                        .font(.title)
                        .foregroundColor(.blue)
                        .scaleEffect(1.0 + sin(Date().timeIntervalSince1970 * 3) * 0.1)
                        .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: progress)
                    
                    Text("\(Int(progress * 100))%")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
            }
            
            // Progress description
            VStack(spacing: 8) {
                Text("Analyzing Your Position")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text("Hold still while we capture your movement patterns")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            
            // Analysis steps
            VStack(spacing: 12) {
                AnalysisStep(
                    title: "Body Measurements",
                    isComplete: progress > 0.2,
                    isActive: progress <= 0.2
                )
                AnalysisStep(
                    title: "Device Position",
                    isComplete: progress > 0.5,
                    isActive: progress > 0.2 && progress <= 0.5
                )
                AnalysisStep(
                    title: "Angle Adjustments",
                    isComplete: progress > 0.8,
                    isActive: progress > 0.5 && progress <= 0.8
                )
                AnalysisStep(
                    title: "Calibration",
                    isComplete: progress >= 1.0,
                    isActive: progress > 0.8
                )
            }
        }
        .padding(.horizontal, 20)
    }
}

struct AnalysisStep: View {
    let title: String
    let isComplete: Bool
    let isActive: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 24, height: 24)
                
                if isComplete {
                    Image(systemName: "checkmark")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                } else if isActive {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.6)
                } else {
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            
            Text(title)
                .font(.body)
                .foregroundColor(textColor)
            
            Spacer()
        }
    }
    
    private var backgroundColor: Color {
        if isComplete {
            return .green
        } else if isActive {
            return .blue
        } else {
            return .gray.opacity(0.5)
        }
    }
    
    private var textColor: Color {
        if isComplete || isActive {
            return .white
        } else {
            return .white.opacity(0.6)
        }
    }
}

// MARK: - Adjustment Suggestions View

/// View showing calibration adjustment suggestions
struct AdjustmentSuggestionsView: View {
    let suggestions: [CalibrationSuggestion]
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.title)
                    .foregroundColor(.orange)
                
                Text("Adjustments Needed")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text("Please make these adjustments for better accuracy")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            
            // Suggestions list
            LazyVStack(spacing: 12) {
                ForEach(suggestions) { suggestion in
                    SuggestionCard(suggestion: suggestion)
                }
            }
            .padding(.horizontal)
        }
    }
}

struct SuggestionCard: View {
    let suggestion: CalibrationSuggestion
    
    var body: some View {
        HStack(spacing: 12) {
            // Priority indicator
            Circle()
                .fill(priorityColor)
                .frame(width: 12, height: 12)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 1)
                )
            
            // Suggestion content
            VStack(alignment: .leading, spacing: 4) {
                Text(suggestion.message)
                    .font(.body)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                
                if suggestion.actionRequired {
                    Text("Action Required")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(priorityColor)
                }
            }
            
            Spacer()
            
            // Type icon
            Image(systemName: typeIcon)
                .foregroundColor(.white.opacity(0.7))
                .font(.title3)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(priorityColor.opacity(0.5), lineWidth: 1)
                )
        )
    }
    
    private var priorityColor: Color {
        switch suggestion.priority {
        case .critical:
            return .red
        case .important:
            return .orange
        case .minor:
            return .yellow
        }
    }
    
    private var typeIcon: String {
        switch suggestion.type {
        case .devicePosition:
            return "iphone"
        case .userPosition:
            return "person"
        case .lighting:
            return "lightbulb"
        case .stability:
            return "gyroscope"
        case .bodyVisibility:
            return "eye"
        case .exerciseSetup:
            return "gearshape"
        }
    }
}

// MARK: - Suggestions Card (ACTIVE - Used by AdaptiveCalibrationGuide)

struct SuggestionsCard: View {
    let suggestions: [CalibrationSuggestion]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                Text("Suggestions")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }
            
            ForEach(suggestions.prefix(3)) { suggestion in
                HStack(spacing: 8) {
                    Circle()
                        .fill(suggestion.priority == .critical ? .red : .orange)
                        .frame(width: 6, height: 6)
                    
                    Text(suggestion.message)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(2)
                    
                    Spacer()
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.blue.opacity(0.5), lineWidth: 1)
                )
        )
        .padding(.horizontal)
    }
}

// MARK: - Calibration Complete View

/// View shown when calibration is successfully completed
struct CalibrationCompleteView: View {
    let calibrationQuality: CalibrationQuality
    let calibrationData: CalibrationData?
    
    var body: some View {
        VStack(spacing: 24) {
            // Success animation
            ZStack {
                Circle()
                    .fill(qualityColor.opacity(0.2))
                    .frame(width: 120, height: 120)
                    .scaleEffect(1.0)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: calibrationQuality)
                
                Circle()
                    .stroke(qualityColor, lineWidth: 4)
                    .frame(width: 100, height: 100)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(qualityColor)
            }
            
            // Quality indicator
            VStack(spacing: 8) {
                Text("Calibration Complete!")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(calibrationQuality.description)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // Calibration metrics (if available)
            if let data = calibrationData {
                CalibrationMetricsCard(data: data)
            }
        }
    }
    
    private var qualityColor: Color {
        switch calibrationQuality {
        case .excellent:
            return .green
        case .good:
            return .blue
        case .acceptable:
            return .orange
        case .poor:
            return .red
        case .invalid:
            return .red
        }
    }
}

struct CalibrationMetricsCard: View {
    let data: CalibrationData
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Calibration Details")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack(spacing: 20) {
                MetricItem(
                    title: "Score",
                    value: "\(Int(data.calibrationScore))",
                    subtitle: "out of 100"
                )
                
                MetricItem(
                    title: "Confidence",
                    value: "\(Int(data.confidenceLevel * 100))%",
                    subtitle: "accuracy"
                )
                
                MetricItem(
                    title: "Frames",
                    value: "\(data.frameCount)",
                    subtitle: "analyzed"
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
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

struct MetricItem: View {
    let title: String
    let value: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Calibration Results Sheet

struct CalibrationResultsSheet: View {
    let calibrationData: CalibrationData
    let quality: CalibrationQuality
    let onAccept: () -> Void
    let onRetry: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Quality header
                VStack(spacing: 16) {
                    Image(systemName: quality == .poor || quality == .invalid ? "exclamationmark.triangle" : "checkmark.circle")
                        .font(.system(size: 50))
                        .foregroundColor(quality == .poor || quality == .invalid ? .orange : .green)
                    
                    Text(quality.description)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                }
                
                // Detailed metrics
                CalibrationResultsDetails(data: calibrationData)
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 12) {
                    if quality == .poor || quality == .invalid {
                        Button("Retry Calibration") {
                            onRetry()
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.orange)
                        .cornerRadius(12)
                        
                        Button("Use Anyway") {
                            onAccept()
                        }
                        .foregroundColor(.orange)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.orange, lineWidth: 1)
                        )
                    } else {
                        Button("Continue") {
                            onAccept()
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.green)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
            }
            .padding()
            .navigationTitle("Calibration Results")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct CalibrationResultsDetails: View {
    let data: CalibrationData
    
    var body: some View {
        VStack(spacing: 16) {
            // Score and confidence
            HStack(spacing: 30) {
                VStack {
                    Text("\(Int(data.calibrationScore))")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    Text("Score")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("\(Int(data.confidenceLevel * 100))%")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    Text("Confidence")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            // Device metrics
            VStack(alignment: .leading, spacing: 8) {
                Text("Device Position")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("Angle: \(Int(data.deviceAngle))°")
                        Text("Stability: \(Int(data.deviceStability * 100))%")
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("Distance: \(String(format: "%.1f", data.deviceDistance))m")
                        Text("Height: \(String(format: "%.1f", data.deviceHeight))m")
                    }
                }
                .font(.body)
                .foregroundColor(.secondary)
            }
            
            Divider()
            
            // Exercise specific
            VStack(alignment: .leading, spacing: 8) {
                Text("Exercise: \(data.exercise.displayName)")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Frames analyzed: \(data.frameCount)")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - Adaptive Calibration Guide

/// Full-screen zone-based guide that works in any orientation
struct AdaptiveCalibrationGuide: View {
    let framing: FramingStatus
    let exerciseType: ExerciseType
    let suggestions: [CalibrationSuggestion]
    
    @State private var orientation = UIDevice.current.orientation
    @State private var pulseAnimation = false
    
    var body: some View {
        GeometryReader { geometry in
            let isLandscape = orientation.isLandscape || 
                (orientation.isFlat && geometry.size.width > geometry.size.height)
            
            ZStack {
                // Layer 1: Background zones (outer to inner)
                zonesLayer(geometry: geometry, isLandscape: isLandscape)
                
                // Layer 2: Body silhouette
                bodyOutlineLayer(isLandscape: isLandscape)
                
                // Layer 3: Instructions and feedback
                overlayLayer(geometry: geometry, isLandscape: isLandscape)
            }
            .edgesIgnoringSafeArea(.all)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                orientation = UIDevice.current.orientation
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                pulseAnimation = true
            }
        }
    }
    
    // MARK: - Zone Layers
    
    @ViewBuilder
    private func zonesLayer(geometry: GeometryProxy, isLandscape: Bool) -> some View {
        // Too far zone - very subtle
        Rectangle()
            .fill(
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color.clear,
                        Color.red.opacity(0.03)
                    ]),
                    center: .center,
                    startRadius: geometry.size.width * 0.4,
                    endRadius: geometry.size.width * 0.8
                )
            )
            .edgesIgnoringSafeArea(.all)
        
        // Acceptable zone - subtle yellow
        RoundedRectangle(cornerRadius: 40)
            .stroke(Color.yellow.opacity(0.3), lineWidth: 2)
            .background(
                RoundedRectangle(cornerRadius: 40)
                    .fill(Color.yellow.opacity(0.05))
            )
            .frame(
                width: geometry.size.width * (isLandscape ? 0.8 : 0.9),
                height: geometry.size.height * (isLandscape ? 0.9 : 0.85)
            )
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        
        // Optimal zone - subtle green
        RoundedRectangle(cornerRadius: 30)
            .stroke(Color.green.opacity(0.4), lineWidth: 2)
            .background(
                RoundedRectangle(cornerRadius: 30)
                    .fill(Color.green.opacity(0.08))
            )
            .frame(
                width: geometry.size.width * (isLandscape ? 0.65 : 0.75),
                height: geometry.size.height * (isLandscape ? 0.8 : 0.7)
            )
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        
        // Current position indicator - more prominent
        RoundedRectangle(cornerRadius: 25)
            .stroke(frameColor, lineWidth: 4)
            .shadow(color: frameColor.opacity(0.5), radius: 10)
            .frame(
                width: geometry.size.width * currentZoneWidth(isLandscape),
                height: geometry.size.height * currentZoneHeight(isLandscape)
            )
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            .scaleEffect(pulseAnimation && framing == .optimal ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.5), value: framing)
    }
    
    // MARK: - Body Outline Layer
    
    @ViewBuilder
    private func bodyOutlineLayer(isLandscape: Bool) -> some View {
        // Exercise-specific body outline
        ExerciseBodyOutline(exercise: exerciseType)
            .foregroundColor(bodyOutlineColor)
            .scaleEffect(isLandscape ? 2.5 : 3.0)
            .rotationEffect(isLandscape ? .degrees(90) : .degrees(0))
            .opacity(0.4)
            .animation(.easeInOut(duration: 0.3), value: isLandscape)
    }
    
    // MARK: - Overlay Layer (Instructions & Feedback)
    
    @ViewBuilder
    private func overlayLayer(geometry: GeometryProxy, isLandscape: Bool) -> some View {
        VStack {
            // Top section: Distance indicator
            if isLandscape {
                HStack {
                    distanceIndicator
                        .padding(.leading, 40)
                    Spacer()
                }
                .padding(.top, 20)
            } else {
                HStack {
                    Spacer()
                    distanceIndicator
                    Spacer()
                }
                .padding(.top, 50)
            }
            
            Spacer()
            
            // Bottom section: Instructions and suggestions
            VStack(spacing: 20) {
                // Body detection status
                bodyDetectionStatus
                
                // Main instruction
                instructionBadge
                
                // Critical suggestions (if any)
                if !suggestions.filter({ $0.priority == .critical }).isEmpty {
                    SuggestionsCard(suggestions: suggestions.filter { $0.priority == .critical })
                        .frame(maxWidth: isLandscape ? 400 : .infinity)
                }
            }
            .padding(.horizontal, isLandscape ? 40 : 20)
            .padding(.bottom, isLandscape ? 20 : 100)
        }
    }
    
    // MARK: - UI Components
    
    private var distanceIndicator: some View {
        VStack(spacing: 4) {
            // Add an icon for better visual
            Image(systemName: distanceIcon)
                .font(.title3)
                .foregroundColor(.white)
            
            Text(distanceText)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Distance")
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(backgroundGradient)
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
    }
    
    private var instructionBadge: some View {
        HStack(spacing: 12) {
            Image(systemName: directionIcon)
                .font(.title3)
                .foregroundColor(.white)
            
            Text(framing.instruction)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.8))
                .overlay(
                    Capsule()
                        .stroke(frameColor.opacity(0.5), lineWidth: 1)
                )
        )
    }
    
    // Add visual feedback for body detection:
    private var bodyDetectionStatus: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(bodyDetected ? Color.green : Color.orange)
                .frame(width: 8, height: 8)
            
            Text(bodyDetected ? "Body Detected" : "No Body Detected")
                .font(.caption)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.6))
        )
    }
    
    // MARK: - Helper Properties
    
    private var frameColor: Color {
        switch framing {
        case .optimal: return .green
        case .acceptable: return .blue
        case .tooClose, .tooFar: return .orange
        case .tooLeft, .tooRight, .tooHigh, .tooLow: return .yellow
        case .unknown: return .gray
        }
    }
    
    private var bodyOutlineColor: Color {
        switch framing {
        case .optimal: return .green
        case .acceptable: return .white
        default: return .orange
        }
    }
    
    private var distanceText: String {
        switch framing {
        case .optimal: 
            return "~5 ft"
        case .acceptable: 
            return "~6 ft"
        case .tooClose: 
            return "<3 ft"
        case .tooFar: 
            return ">8 ft"
        case .tooLeft, .tooRight:
            return "~5-6 ft"  // Add distance for left/right
        case .tooHigh, .tooLow:
            return "~5-6 ft"  // Add distance for up/down
        case .unknown:
            return "Detecting..."  // Better than "---"
        }
    }
    
    private var directionIcon: String {
        switch framing {
        case .tooClose: return "arrow.backward"
        case .tooFar: return "arrow.forward"
        case .tooLeft: return "arrow.right"
        case .tooRight: return "arrow.left"
        case .tooHigh: return "arrow.down"
        case .tooLow: return "arrow.up"
        case .optimal: return "checkmark.circle"
        case .acceptable: return "circle"
        case .unknown: return "questionmark.circle"
        }
    }
    
    // Add distance icon:
    private var distanceIcon: String {
        switch framing {
        case .optimal: return "checkmark.circle.fill"
        case .acceptable: return "circle.fill"
        case .tooClose: return "arrow.down.circle.fill"
        case .tooFar: return "arrow.up.circle.fill"
        default: return "circle.dashed"
        }
    }
    
    // Add gradient for better visibility:
    private var backgroundGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                frameColor.opacity(0.9),
                frameColor.opacity(0.7)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    // Add property to track body detection:
    private var bodyDetected: Bool {
        framing != .unknown
    }
    
    private func currentZoneWidth(_ isLandscape: Bool) -> CGFloat {
        let baseWidth = switch framing {
        case .optimal: 0.75
        case .acceptable: 0.85
        case .tooClose: 0.95
        case .tooFar: 0.6
        case .tooLeft: 0.9
        case .tooRight: 0.9
        default: 0.85
        }
        
        // Adjust for landscape
        return isLandscape ? baseWidth * 0.85 : baseWidth
    }
    
    private func currentZoneHeight(_ isLandscape: Bool) -> CGFloat {
        let baseHeight = switch framing {
        case .optimal: 0.7
        case .acceptable: 0.8
        case .tooClose: 0.9
        case .tooFar: 0.55
        case .tooHigh: 0.85
        case .tooLow: 0.85
        default: 0.8
        }
        
        // Adjust for landscape
        return isLandscape ? baseHeight * 1.1 : baseHeight
    }
}

// MARK: - Dynamic Framing Guide (Legacy - kept for compatibility)

/// Alternative approach - Use the actual pose overlay bounds
struct DynamicFramingGuide: View {
    let currentFraming: FramingStatus
    let targetFraming: TargetFraming
    @State private var showFullBodyGuide = true
    
    var body: some View {
        // Use the new adaptive guide instead
        AdaptiveCalibrationGuide(
            framing: currentFraming,
            exerciseType: targetFraming.exercise,
            suggestions: []
        )
    }
}

// MARK: - Preview

struct CalibrationOverlayViews_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            PositioningGuideOverlay(
                currentFraming: .acceptable,
                targetFraming: TargetFraming.getTargetFraming(for: .pushup),
                suggestions: []
            )
            .previewDisplayName("Positioning Guide")
            
            AnalyzingView(progress: 0.6)
                .previewDisplayName("Analyzing View")
                .background(Color.black)
            
            CalibrationCompleteView(
                calibrationQuality: .excellent,
                calibrationData: nil
            )
            .previewDisplayName("Completion View")
            .background(Color.black)
        }
    }
} 