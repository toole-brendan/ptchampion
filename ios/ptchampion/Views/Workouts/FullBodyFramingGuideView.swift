import SwiftUI
import Vision
import Foundation

// Simplified framing guide that doesn't depend on complex validator types
struct FullBodyFramingGuideView: View {
    let exercise: ExerciseType
    let orientation: UIDeviceOrientation
    
    // Use simple properties instead of complex validator
    @State private var framingStatus: SimpleFramingStatus = .needsAdjustment
    @State private var guideFeedback: String = "Position yourself in frame"
    @State private var requiredAdjustment: SimpleFramingAdjustment = .none
    @State private var pulseAnimation = false
    
    enum SimpleFramingStatus {
        case perfect
        case needsAdjustment
        case notDetected
    }
    
    enum SimpleFramingAdjustment {
        case none
        case moveCloser
        case moveBack
        case moveLeft
        case moveRight
        case rotateDevice
    }
    
    var body: some View {
        ZStack {
            // Semi-transparent overlay
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
            
            // Body outline guide
            BodyOutlineShape(exercise: exercise, orientation: orientation)
                .stroke(lineWidth: 3)
                .foregroundColor(strokeColor)
                .opacity(0.8)
                .padding(guidePadding)
                .scaleEffect(pulseAnimation && framingStatus == .perfect ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: pulseAnimation)
            
            // Feedback text
            VStack {
                Spacer()
                
                HStack {
                    Image(systemName: feedbackIcon)
                        .font(.title2)
                        .foregroundColor(.white)
                    
                    Text(guideFeedback)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(strokeColor, lineWidth: 2)
                        )
                )
                .padding(.bottom, 100)
            }
            
            // Directional arrows based on adjustment needed
            DirectionalArrows(adjustment: requiredAdjustment)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                pulseAnimation = true
            }
            
            // Set default feedback based on exercise
            updateFeedbackForExercise()
        }
    }
    
    private func updateFeedbackForExercise() {
        switch exercise {
        case .pushup:
            guideFeedback = "Position for push-ups"
            requiredAdjustment = .moveCloser
        case .situp:
            guideFeedback = "Position for sit-ups"
            requiredAdjustment = .moveBack
        case .pullup:
            guideFeedback = "Position for pull-ups"
            requiredAdjustment = .moveBack
        default:
            guideFeedback = "Position yourself in frame"
            requiredAdjustment = .none
        }
    }
    
    private var strokeColor: Color {
        switch framingStatus {
        case .perfect:
            return .green
        case .needsAdjustment:
            return .yellow
        case .notDetected:
            return .red
        }
    }
    
    private var feedbackIcon: String {
        switch framingStatus {
        case .perfect:
            return "checkmark.circle.fill"
        case .needsAdjustment:
            return "exclamationmark.triangle.fill"
        case .notDetected:
            return "person.crop.circle.badge.questionmark"
        }
    }
    
    private var guidePadding: EdgeInsets {
        // Dynamic padding based on device and orientation
        if orientation.isPortrait {
            return EdgeInsets(top: 100, leading: 60, bottom: 100, trailing: 60)
        } else {
            return EdgeInsets(top: 60, leading: 100, bottom: 60, trailing: 100)
        }
    }
}

// MARK: - Body Outline Shape
struct BodyOutlineShape: Shape {
    let exercise: ExerciseType
    let orientation: UIDeviceOrientation
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let scale = min(rect.width, rect.height) / 200
        let centerX = rect.midX
        let centerY = rect.midY
        
        switch exercise {
        case .pushup:
            drawPushupOutline(path: &path, centerX: centerX, centerY: centerY, scale: scale)
        case .situp:
            drawSitupOutline(path: &path, centerX: centerX, centerY: centerY, scale: scale)
        case .pullup:
            drawPullupOutline(path: &path, centerX: centerX, centerY: centerY, scale: scale)
        default:
            drawDefaultOutline(path: &path, centerX: centerX, centerY: centerY, scale: scale)
        }
        
        return path
    }
    
    private func drawPushupOutline(path: inout Path, centerX: CGFloat, centerY: CGFloat, scale: CGFloat) {
        // Head
        path.addEllipse(in: CGRect(
            x: centerX - 20 * scale,
            y: centerY - 80 * scale,
            width: 40 * scale,
            height: 40 * scale
        ))
        
        // Torso
        path.move(to: CGPoint(x: centerX, y: centerY - 40 * scale))
        path.addLine(to: CGPoint(x: centerX, y: centerY + 40 * scale))
        
        // Arms
        path.move(to: CGPoint(x: centerX, y: centerY - 20 * scale))
        path.addLine(to: CGPoint(x: centerX - 60 * scale, y: centerY + 20 * scale))
        path.move(to: CGPoint(x: centerX, y: centerY - 20 * scale))
        path.addLine(to: CGPoint(x: centerX + 60 * scale, y: centerY + 20 * scale))
        
        // Legs
        path.move(to: CGPoint(x: centerX, y: centerY + 40 * scale))
        path.addLine(to: CGPoint(x: centerX - 15 * scale, y: centerY + 100 * scale))
        path.move(to: CGPoint(x: centerX, y: centerY + 40 * scale))
        path.addLine(to: CGPoint(x: centerX + 15 * scale, y: centerY + 100 * scale))
    }
    
    private func drawSitupOutline(path: inout Path, centerX: CGFloat, centerY: CGFloat, scale: CGFloat) {
        // Head
        path.addEllipse(in: CGRect(
            x: centerX - 20 * scale,
            y: centerY - 80 * scale,
            width: 40 * scale,
            height: 40 * scale
        ))
        
        // Torso (angled for sit-up)
        path.move(to: CGPoint(x: centerX, y: centerY - 40 * scale))
        path.addQuadCurve(
            to: CGPoint(x: centerX - 10 * scale, y: centerY + 20 * scale),
            control: CGPoint(x: centerX - 5 * scale, y: centerY - 10 * scale)
        )
        
        // Arms (crossed on chest)
        path.move(to: CGPoint(x: centerX - 20 * scale, y: centerY - 10 * scale))
        path.addLine(to: CGPoint(x: centerX + 20 * scale, y: centerY))
        path.move(to: CGPoint(x: centerX + 20 * scale, y: centerY - 10 * scale))
        path.addLine(to: CGPoint(x: centerX - 20 * scale, y: centerY))
        
        // Bent legs
        path.move(to: CGPoint(x: centerX - 10 * scale, y: centerY + 20 * scale))
        path.addQuadCurve(
            to: CGPoint(x: centerX - 30 * scale, y: centerY + 80 * scale),
            control: CGPoint(x: centerX - 20 * scale, y: centerY + 50 * scale)
        )
        path.move(to: CGPoint(x: centerX - 10 * scale, y: centerY + 20 * scale))
        path.addQuadCurve(
            to: CGPoint(x: centerX + 10 * scale, y: centerY + 80 * scale),
            control: CGPoint(x: centerX, y: centerY + 50 * scale)
        )
    }
    
    private func drawPullupOutline(path: inout Path, centerX: CGFloat, centerY: CGFloat, scale: CGFloat) {
        // Pull-up bar
        path.move(to: CGPoint(x: centerX - 80 * scale, y: centerY - 120 * scale))
        path.addLine(to: CGPoint(x: centerX + 80 * scale, y: centerY - 120 * scale))
        
        // Arms reaching up
        path.move(to: CGPoint(x: centerX - 30 * scale, y: centerY - 120 * scale))
        path.addLine(to: CGPoint(x: centerX - 20 * scale, y: centerY - 80 * scale))
        path.move(to: CGPoint(x: centerX + 30 * scale, y: centerY - 120 * scale))
        path.addLine(to: CGPoint(x: centerX + 20 * scale, y: centerY - 80 * scale))
        
        // Head
        path.addEllipse(in: CGRect(
            x: centerX - 20 * scale,
            y: centerY - 80 * scale,
            width: 40 * scale,
            height: 40 * scale
        ))
        
        // Torso
        path.move(to: CGPoint(x: centerX, y: centerY - 40 * scale))
        path.addLine(to: CGPoint(x: centerX, y: centerY + 40 * scale))
        
        // Legs
        path.move(to: CGPoint(x: centerX, y: centerY + 40 * scale))
        path.addLine(to: CGPoint(x: centerX - 10 * scale, y: centerY + 100 * scale))
        path.move(to: CGPoint(x: centerX, y: centerY + 40 * scale))
        path.addLine(to: CGPoint(x: centerX + 10 * scale, y: centerY + 100 * scale))
    }
    
    private func drawDefaultOutline(path: inout Path, centerX: CGFloat, centerY: CGFloat, scale: CGFloat) {
        // Basic standing figure
        // Head
        path.addEllipse(in: CGRect(
            x: centerX - 20 * scale,
            y: centerY - 80 * scale,
            width: 40 * scale,
            height: 40 * scale
        ))
        
        // Torso
        path.move(to: CGPoint(x: centerX, y: centerY - 40 * scale))
        path.addLine(to: CGPoint(x: centerX, y: centerY + 40 * scale))
        
        // Arms
        path.move(to: CGPoint(x: centerX, y: centerY - 20 * scale))
        path.addLine(to: CGPoint(x: centerX - 40 * scale, y: centerY + 20 * scale))
        path.move(to: CGPoint(x: centerX, y: centerY - 20 * scale))
        path.addLine(to: CGPoint(x: centerX + 40 * scale, y: centerY + 20 * scale))
        
        // Legs
        path.move(to: CGPoint(x: centerX, y: centerY + 40 * scale))
        path.addLine(to: CGPoint(x: centerX - 20 * scale, y: centerY + 100 * scale))
        path.move(to: CGPoint(x: centerX, y: centerY + 40 * scale))
        path.addLine(to: CGPoint(x: centerX + 20 * scale, y: centerY + 100 * scale))
    }
}

// MARK: - Directional Arrows
struct DirectionalArrows: View {
    let adjustment: FullBodyFramingGuideView.SimpleFramingAdjustment
    @State private var animateArrows = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                switch adjustment {
                case .moveCloser:
                    FramingArrowIndicator(
                        direction: .forward,
                        animate: animateArrows
                    )
                    .position(x: geometry.size.width / 2, y: geometry.size.height * 0.2)
                    
                case .moveBack:
                    FramingArrowIndicator(
                        direction: .backward,
                        animate: animateArrows
                    )
                    .position(x: geometry.size.width / 2, y: geometry.size.height * 0.8)
                    
                case .moveLeft:
                    FramingArrowIndicator(
                        direction: .left,
                        animate: animateArrows
                    )
                    .position(x: geometry.size.width * 0.2, y: geometry.size.height / 2)
                    
                case .moveRight:
                    FramingArrowIndicator(
                        direction: .right,
                        animate: animateArrows
                    )
                    .position(x: geometry.size.width * 0.8, y: geometry.size.height / 2)
                    
                case .rotateDevice:
                    RotateDeviceIndicator(animate: animateArrows)
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                    
                case .none:
                    EmptyView()
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever()) {
                animateArrows = true
            }
        }
    }
}

// MARK: - Framing Arrow Indicator
struct FramingArrowIndicator: View {
    enum Direction {
        case forward, backward, left, right
        
        var systemImage: String {
            switch self {
            case .forward: return "arrow.up"
            case .backward: return "arrow.down"
            case .left: return "arrow.left"
            case .right: return "arrow.right"
            }
        }
        
        var instruction: String {
            switch self {
            case .forward: return "Move Closer"
            case .backward: return "Step Back"
            case .left: return "Move Left"
            case .right: return "Move Right"
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
                .scaleEffect(animate ? 1.2 : 1.0)
                .opacity(animate ? 0.8 : 1.0)
            
            Text(direction.instruction)
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
}

// MARK: - Rotate Device Indicator
struct RotateDeviceIndicator: View {
    let animate: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "rotate.right")
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(.blue)
                .rotationEffect(.degrees(animate ? 360 : 0))
            
            Text("Rotate Device")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.blue.opacity(0.8))
                )
        }
    }
}

// MARK: - Preview
struct FullBodyFramingGuideView_Previews: PreviewProvider {
    static var previews: some View {
        FullBodyFramingGuideView(
            exercise: .pushup,
            orientation: .portrait
        )
        .background(Color.black)
    }
} 