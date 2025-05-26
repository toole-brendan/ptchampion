import SwiftUI

// MARK: - Enhanced Positioning Guide Overlay

/// Enhanced overlay with body silhouette, distance indicator, and color-coded zones
struct EnhancedPositioningGuideOverlay: View {
    let currentFraming: FramingStatus
    let targetFraming: TargetFraming
    let suggestions: [CalibrationSuggestion]
    let environmentAnalyzer: EnvironmentAnalyzer
    @State private var animateArrows = false
    @State private var pulseAnimation = false
    
    var body: some View {
        ZStack {
            // Background positioning grid
            PositioningGrid()
                .opacity(0.3)
            
            // Body silhouette with color-coded zones
            EnhancedBodySilhouette(
                exercise: targetFraming.exercise,
                framing: currentFraming
            )
            
            // Distance indicator bar
            DistanceIndicatorBar(
                currentDistance: estimateDistance(from: currentFraming),
                targetRange: targetFraming.acceptableDistanceRange,
                optimalDistance: targetFraming.optimalDistance
            )
            .frame(height: 60)
            .padding(.horizontal, 40)
            .offset(y: -150)
            
            // Animated adjustment arrows
            if !currentFraming.isAcceptable {
                AdjustmentArrows(
                    framing: currentFraming,
                    animate: animateArrows
                )
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.5).repeatForever()) {
                        animateArrows = true
                    }
                }
            }
            
            // Environment status indicator
            EnvironmentStatusBadge(analyzer: environmentAnalyzer)
                .position(x: UIScreen.main.bounds.width - 80, y: 100)
            
            // Real-time suggestions with enhanced visibility
            if !suggestions.isEmpty {
                EnhancedSuggestionsCard(
                    suggestions: suggestions.filter { $0.priority == .critical || $0.priority == .important }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                pulseAnimation = true
            }
        }
    }
    
    private func estimateDistance(from framing: FramingStatus) -> Float {
        switch framing {
        case .tooClose:
            return 0.8
        case .tooFar:
            return 2.5
        case .optimal:
            return 1.5
        case .acceptable:
            return 1.6
        default:
            return 1.5
        }
    }
}

// MARK: - Positioning Grid

struct PositioningGrid: View {
    let gridSize: CGFloat = 50
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Vertical lines
                ForEach(0..<Int(geometry.size.width / gridSize), id: \.self) { index in
                    Path { path in
                        let x = CGFloat(index) * gridSize
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: geometry.size.height))
                    }
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                }
                
                // Horizontal lines
                ForEach(0..<Int(geometry.size.height / gridSize), id: \.self) { index in
                    Path { path in
                        let y = CGFloat(index) * gridSize
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                    }
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                }
                
                // Center crosshair
                VStack(spacing: 0) {
                    Spacer()
                    HStack(spacing: 0) {
                        Spacer()
                        ZStack {
                            Circle()
                                .stroke(Color.white.opacity(0.5), lineWidth: 2)
                                .frame(width: 80, height: 80)
                            
                            // Crosshair lines
                            Path { path in
                                path.move(to: CGPoint(x: 40, y: 20))
                                path.addLine(to: CGPoint(x: 40, y: 60))
                                path.move(to: CGPoint(x: 20, y: 40))
                                path.addLine(to: CGPoint(x: 60, y: 40))
                            }
                            .stroke(Color.white.opacity(0.7), lineWidth: 2)
                            .frame(width: 80, height: 80)
                        }
                        Spacer()
                    }
                    Spacer()
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}

// MARK: - Enhanced Body Silhouette

struct EnhancedBodySilhouette: View {
    let exercise: ExerciseType
    let framing: FramingStatus
    @State private var opacity: Double = 0.7
    
    var body: some View {
        ZStack {
            // Color-coded zone background
            ColorCodedZone(framing: framing)
                .opacity(0.3)
            
            // Semi-transparent body outline
            Group {
                switch exercise {
                case .pushup:
                    EnhancedPushupSilhouette()
                case .situp:
                    EnhancedSitupSilhouette()
                case .pullup:
                    EnhancedPullupSilhouette()
                default:
                    EnhancedDefaultSilhouette()
                }
            }
            .foregroundColor(silhouetteColor)
            .opacity(opacity)
            .scaleEffect(framing == .optimal ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.5), value: framing)
        }
    }
    
    private var silhouetteColor: Color {
        switch framing {
        case .optimal:
            return .green
        case .acceptable:
            return .blue
        case .tooClose, .tooFar, .tooLeft, .tooRight, .tooHigh, .tooLow:
            return .orange
        case .unknown:
            return .gray
        }
    }
}

// MARK: - Color Coded Zone

struct ColorCodedZone: View {
    let framing: FramingStatus
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Optimal zone (green)
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.green.opacity(0.2))
                    .frame(
                        width: geometry.size.width * 0.5,
                        height: geometry.size.height * 0.6
                    )
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                
                // Acceptable zone (yellow)
                RoundedRectangle(cornerRadius: 30)
                    .fill(Color.yellow.opacity(0.15))
                    .frame(
                        width: geometry.size.width * 0.7,
                        height: geometry.size.height * 0.8
                    )
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                
                // Outer zone (red)
                Rectangle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.clear,
                                Color.red.opacity(0.1)
                            ]),
                            center: .center,
                            startRadius: min(geometry.size.width, geometry.size.height) * 0.4,
                            endRadius: max(geometry.size.width, geometry.size.height) * 0.7
                        )
                    )
            }
        }
    }
}

// MARK: - Enhanced Exercise Silhouettes

struct EnhancedPushupSilhouette: View {
    var body: some View {
        GeometryReader { geometry in
            let scale = min(geometry.size.width, geometry.size.height) / 300
            
            Path { path in
                // Head
                path.addEllipse(in: CGRect(
                    x: geometry.size.width * 0.5 - 15 * scale,
                    y: geometry.size.height * 0.3 - 15 * scale,
                    width: 30 * scale,
                    height: 30 * scale
                ))
                
                // Torso
                path.move(to: CGPoint(x: geometry.size.width * 0.5, y: geometry.size.height * 0.3 + 15 * scale))
                path.addLine(to: CGPoint(x: geometry.size.width * 0.5, y: geometry.size.height * 0.6))
                
                // Arms
                path.move(to: CGPoint(x: geometry.size.width * 0.5, y: geometry.size.height * 0.35))
                path.addLine(to: CGPoint(x: geometry.size.width * 0.3, y: geometry.size.height * 0.45))
                path.addLine(to: CGPoint(x: geometry.size.width * 0.25, y: geometry.size.height * 0.55))
                
                path.move(to: CGPoint(x: geometry.size.width * 0.5, y: geometry.size.height * 0.35))
                path.addLine(to: CGPoint(x: geometry.size.width * 0.7, y: geometry.size.height * 0.45))
                path.addLine(to: CGPoint(x: geometry.size.width * 0.75, y: geometry.size.height * 0.55))
                
                // Legs
                path.move(to: CGPoint(x: geometry.size.width * 0.5, y: geometry.size.height * 0.6))
                path.addLine(to: CGPoint(x: geometry.size.width * 0.45, y: geometry.size.height * 0.75))
                path.addLine(to: CGPoint(x: geometry.size.width * 0.43, y: geometry.size.height * 0.85))
                
                path.move(to: CGPoint(x: geometry.size.width * 0.5, y: geometry.size.height * 0.6))
                path.addLine(to: CGPoint(x: geometry.size.width * 0.55, y: geometry.size.height * 0.75))
                path.addLine(to: CGPoint(x: geometry.size.width * 0.57, y: geometry.size.height * 0.85))
            }
            .stroke(lineWidth: 3 * scale)
        }
    }
}

struct EnhancedSitupSilhouette: View {
    var body: some View {
        GeometryReader { geometry in
            let scale = min(geometry.size.width, geometry.size.height) / 300
            
            Path { path in
                // Head
                path.addEllipse(in: CGRect(
                    x: geometry.size.width * 0.5 - 15 * scale,
                    y: geometry.size.height * 0.25 - 15 * scale,
                    width: 30 * scale,
                    height: 30 * scale
                ))
                
                // Torso (angled for sit-up position)
                path.move(to: CGPoint(x: geometry.size.width * 0.5, y: geometry.size.height * 0.25 + 15 * scale))
                path.addQuadCurve(
                    to: CGPoint(x: geometry.size.width * 0.45, y: geometry.size.height * 0.55),
                    control: CGPoint(x: geometry.size.width * 0.48, y: geometry.size.height * 0.4)
                )
                
                // Arms (crossed on chest)
                path.move(to: CGPoint(x: geometry.size.width * 0.45, y: geometry.size.height * 0.35))
                path.addLine(to: CGPoint(x: geometry.size.width * 0.55, y: geometry.size.height * 0.4))
                path.move(to: CGPoint(x: geometry.size.width * 0.55, y: geometry.size.height * 0.35))
                path.addLine(to: CGPoint(x: geometry.size.width * 0.45, y: geometry.size.height * 0.4))
                
                // Bent legs
                path.move(to: CGPoint(x: geometry.size.width * 0.45, y: geometry.size.height * 0.55))
                path.addQuadCurve(
                    to: CGPoint(x: geometry.size.width * 0.35, y: geometry.size.height * 0.75),
                    control: CGPoint(x: geometry.size.width * 0.4, y: geometry.size.height * 0.65)
                )
                path.addLine(to: CGPoint(x: geometry.size.width * 0.4, y: geometry.size.height * 0.85))
                
                path.move(to: CGPoint(x: geometry.size.width * 0.45, y: geometry.size.height * 0.55))
                path.addQuadCurve(
                    to: CGPoint(x: geometry.size.width * 0.55, y: geometry.size.height * 0.75),
                    control: CGPoint(x: geometry.size.width * 0.5, y: geometry.size.height * 0.65)
                )
                path.addLine(to: CGPoint(x: geometry.size.width * 0.6, y: geometry.size.height * 0.85))
            }
            .stroke(lineWidth: 3 * scale)
        }
    }
}

struct EnhancedPullupSilhouette: View {
    var body: some View {
        GeometryReader { geometry in
            let scale = min(geometry.size.width, geometry.size.height) / 300
            
            Path { path in
                // Pull-up bar
                path.move(to: CGPoint(x: geometry.size.width * 0.2, y: geometry.size.height * 0.1))
                path.addLine(to: CGPoint(x: geometry.size.width * 0.8, y: geometry.size.height * 0.1))
                
                // Arms reaching up
                path.move(to: CGPoint(x: geometry.size.width * 0.4, y: geometry.size.height * 0.1))
                path.addLine(to: CGPoint(x: geometry.size.width * 0.45, y: geometry.size.height * 0.25))
                
                path.move(to: CGPoint(x: geometry.size.width * 0.6, y: geometry.size.height * 0.1))
                path.addLine(to: CGPoint(x: geometry.size.width * 0.55, y: geometry.size.height * 0.25))
                
                // Head
                path.addEllipse(in: CGRect(
                    x: geometry.size.width * 0.5 - 15 * scale,
                    y: geometry.size.height * 0.25 - 15 * scale,
                    width: 30 * scale,
                    height: 30 * scale
                ))
                
                // Torso
                path.move(to: CGPoint(x: geometry.size.width * 0.5, y: geometry.size.height * 0.25 + 15 * scale))
                path.addLine(to: CGPoint(x: geometry.size.width * 0.5, y: geometry.size.height * 0.6))
                
                // Legs
                path.move(to: CGPoint(x: geometry.size.width * 0.5, y: geometry.size.height * 0.6))
                path.addLine(to: CGPoint(x: geometry.size.width * 0.47, y: geometry.size.height * 0.8))
                path.addLine(to: CGPoint(x: geometry.size.width * 0.46, y: geometry.size.height * 0.9))
                
                path.move(to: CGPoint(x: geometry.size.width * 0.5, y: geometry.size.height * 0.6))
                path.addLine(to: CGPoint(x: geometry.size.width * 0.53, y: geometry.size.height * 0.8))
                path.addLine(to: CGPoint(x: geometry.size.width * 0.54, y: geometry.size.height * 0.9))
            }
            .stroke(lineWidth: 3 * scale)
        }
    }
}

struct EnhancedDefaultSilhouette: View {
    var body: some View {
        GeometryReader { geometry in
            let scale = min(geometry.size.width, geometry.size.height) / 300
            
            Path { path in
                // Head
                path.addEllipse(in: CGRect(
                    x: geometry.size.width * 0.5 - 15 * scale,
                    y: geometry.size.height * 0.2 - 15 * scale,
                    width: 30 * scale,
                    height: 30 * scale
                ))
                
                // Torso
                path.move(to: CGPoint(x: geometry.size.width * 0.5, y: geometry.size.height * 0.2 + 15 * scale))
                path.addLine(to: CGPoint(x: geometry.size.width * 0.5, y: geometry.size.height * 0.55))
                
                // Arms
                path.move(to: CGPoint(x: geometry.size.width * 0.5, y: geometry.size.height * 0.3))
                path.addLine(to: CGPoint(x: geometry.size.width * 0.35, y: geometry.size.height * 0.45))
                
                path.move(to: CGPoint(x: geometry.size.width * 0.5, y: geometry.size.height * 0.3))
                path.addLine(to: CGPoint(x: geometry.size.width * 0.65, y: geometry.size.height * 0.45))
                
                // Legs
                path.move(to: CGPoint(x: geometry.size.width * 0.5, y: geometry.size.height * 0.55))
                path.addLine(to: CGPoint(x: geometry.size.width * 0.45, y: geometry.size.height * 0.8))
                path.addLine(to: CGPoint(x: geometry.size.width * 0.43, y: geometry.size.height * 0.9))
                
                path.move(to: CGPoint(x: geometry.size.width * 0.5, y: geometry.size.height * 0.55))
                path.addLine(to: CGPoint(x: geometry.size.width * 0.55, y: geometry.size.height * 0.8))
                path.addLine(to: CGPoint(x: geometry.size.width * 0.57, y: geometry.size.height * 0.9))
            }
            .stroke(lineWidth: 3 * scale)
        }
    }
}

// MARK: - Distance Indicator Bar

struct DistanceIndicatorBar: View {
    let currentDistance: Float
    let targetRange: ClosedRange<Float>
    let optimalDistance: Float
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.black.opacity(0.5))
                
                // Target range highlight
                let rangeStart = CGFloat((targetRange.lowerBound - 0.5) / 2.5) * geometry.size.width
                let rangeWidth = CGFloat((targetRange.upperBound - targetRange.lowerBound) / 2.5) * geometry.size.width
                
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.green.opacity(0.3))
                    .frame(width: rangeWidth)
                    .offset(x: rangeStart)
                
                // Optimal position line
                let optimalPosition = CGFloat((optimalDistance - 0.5) / 2.5) * geometry.size.width
                Rectangle()
                    .fill(Color.green)
                    .frame(width: 3)
                    .offset(x: optimalPosition)
                
                // Current position indicator
                let currentPosition = CGFloat((currentDistance - 0.5) / 2.5) * geometry.size.width
                Circle()
                    .fill(indicatorColor)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
                    .offset(x: currentPosition - 10)
                
                // Labels
                VStack {
                    HStack {
                        Text("Too Close")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        Spacer()
                        Text("Optimal")
                            .font(.caption)
                            .foregroundColor(.green)
                        Spacer()
                        Text("Too Far")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, 4)
                    Spacer()
                }
            }
        }
    }
    
    private var indicatorColor: Color {
        if targetRange.contains(currentDistance) {
            return abs(currentDistance - optimalDistance) < 0.1 ? .green : .blue
        }
        return .orange
    }
}

// MARK: - Adjustment Arrows

struct AdjustmentArrows: View {
    let framing: FramingStatus
    let animate: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                switch framing {
                case .tooClose:
                    ArrowIndicator(direction: .backward, animate: animate)
                        .position(x: geometry.size.width / 2, y: geometry.size.height * 0.8)
                case .tooFar:
                    ArrowIndicator(direction: .forward, animate: animate)
                        .position(x: geometry.size.width / 2, y: geometry.size.height * 0.2)
                case .tooLeft:
                    ArrowIndicator(direction: .right, animate: animate)
                        .position(x: geometry.size.width * 0.8, y: geometry.size.height / 2)
                case .tooRight:
                    ArrowIndicator(direction: .left, animate: animate)
                        .position(x: geometry.size.width * 0.2, y: geometry.size.height / 2)
                case .tooHigh:
                    ArrowIndicator(direction: .down, animate: animate)
                        .position(x: geometry.size.width / 2, y: geometry.size.height * 0.8)
                case .tooLow:
                    ArrowIndicator(direction: .up, animate: animate)
                        .position(x: geometry.size.width / 2, y: geometry.size.height * 0.2)
                default:
                    EmptyView()
                }
            }
        }
    }
}

struct ArrowIndicator: View {
    enum Direction {
        case up, down, left, right, forward, backward
        
        var rotation: Double {
            switch self {
            case .up: return -90
            case .down: return 90
            case .left: return 180
            case .right: return 0
            case .forward: return -90
            case .backward: return 90
            }
        }
        
        var systemImage: String {
            switch self {
            case .forward, .backward:
                return "arrow.up.and.down"
            default:
                return "arrow.right"
            }
        }
    }
    
    let direction: Direction
    let animate: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: direction.systemImage)
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(.orange)
                .rotationEffect(.degrees(direction.rotation))
                .scaleEffect(animate ? 1.2 : 1.0)
                .opacity(animate ? 0.8 : 1.0)
            
            Text(instructionText)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.orange.opacity(0.8))
                )
        }
    }
    
    private var instructionText: String {
        switch direction {
        case .up: return "Move Up"
        case .down: return "Move Down"
        case .left: return "Move Left"
        case .right: return "Move Right"
        case .forward: return "Move Closer"
        case .backward: return "Step Back"
        }
    }
}

// MARK: - Environment Status Badge

struct EnvironmentStatusBadge: View {
    @ObservedObject var analyzer: EnvironmentAnalyzer
    
    var body: some View {
        VStack(spacing: 4) {
            // Environment icon
            Image(systemName: environmentIcon)
                .font(.title2)
                .foregroundColor(environmentColor)
            
            // Status text
            Text(environmentText)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.white)
            
            // Confidence value
            Text("\(Int(analyzer.recommendedConfidence * 100))%")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(environmentColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(environmentColor.opacity(0.5), lineWidth: 1)
                )
        )
    }
    
    private var environmentIcon: String {
        switch analyzer.lightingQuality {
        case .excellent, .good:
            return "sun.max.fill"
        case .moderate:
            return "sun.min.fill"
        case .poor, .veryPoor:
            return "moon.fill"
        case .unknown:
            return "questionmark.circle"
        }
    }
    
    private var environmentColor: Color {
        switch analyzer.currentEnvironment {
        case .optimal:
            return .green
        case .good:
            return .blue
        case .challenging:
            return .yellow
        case .poor:
            return .orange
        case .unknown:
            return .gray
        }
    }
    
    private var environmentText: String {
        switch analyzer.currentEnvironment {
        case .optimal:
            return "Optimal"
        case .good:
            return "Good"
        case .challenging:
            return "Fair"
        case .poor:
            return "Poor"
        case .unknown:
            return "Detecting..."
        }
    }
}

// MARK: - Enhanced Suggestions Card

struct EnhancedSuggestionsCard: View {
    let suggestions: [CalibrationSuggestion]
    @State private var showExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with toggle
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                    .font(.title3)
                
                Text("Quick Tips")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: { showExpanded.toggle() }) {
                    Image(systemName: showExpanded ? "chevron.down" : "chevron.up")
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            // Suggestions
            if showExpanded {
                ForEach(suggestions) { suggestion in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(priorityColor(for: suggestion.priority))
                            .frame(width: 8, height: 8)
                        
                        Text(suggestion.message)
                            .font(.body)
                            .foregroundColor(.white.opacity(0.9))
                            .lineLimit(2)
                        
                        Spacer()
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            } else {
                // Show only the most critical suggestion
                if let critical = suggestions.first(where: { $0.priority == .critical }) ?? suggestions.first {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(priorityColor(for: critical.priority))
                            .frame(width: 8, height: 8)
                        
                        Text(critical.message)
                            .font(.body)
                            .foregroundColor(.white.opacity(0.9))
                            .lineLimit(1)
                        
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.yellow.opacity(0.5), lineWidth: 1)
                )
        )
        .padding(.horizontal)
        .padding(.bottom, 20)
        .animation(.easeInOut(duration: 0.3), value: showExpanded)
    }
    
    private func priorityColor(for priority: CalibrationSuggestion.Priority) -> Color {
        switch priority {
        case .critical:
            return .red
        case .important:
            return .orange
        case .minor:
            return .yellow
        }
    }
}

// MARK: - Preview

struct EnhancedPositioningGuides_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black
            
            EnhancedPositioningGuideOverlay(
                currentFraming: .tooFar,
                targetFraming: Targ
