import SwiftUI
import PTDesignSystem
import Vision

struct StartingPositionOverlay: View {
    @ObservedObject var positionValidator: StartingPositionValidator
    let exerciseType: ExerciseType
    @Binding var showStartButton: Bool
    
    private var statusColor: Color {
        switch positionValidator.currentStatus {
        case .correct:
            return .green
        case .needsAdjustment:
            return .yellow
        case .notDetected:
            return .red
        }
    }
    
    private var statusIcon: String {
        switch positionValidator.currentStatus {
        case .correct:
            return "checkmark.circle.fill"
        case .needsAdjustment:
            return "exclamationmark.triangle.fill"
        case .notDetected:
            return "xmark.circle.fill"
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Top Status Bar
                VStack {
                    statusBar
                        .padding(.top, 50)
                    
                    Spacer()
                    
                    // Bottom feedback and controls
                    VStack(spacing: 20) {
                        // Angle indicators
                        angleIndicators
                        
                        // Feedback messages
                        feedbackMessages
                        
                        // Progress indicator for holding position
                        if case .correct = positionValidator.currentStatus {
                            holdProgressView
                        }
                        
                        // Start button (only when ready)
                        if positionValidator.isInPosition && showStartButton {
                            startButton
                        }
                    }
                    .padding(.bottom, 40)
                }
                
                // Ghost overlay showing ideal position
                if case .needsAdjustment = positionValidator.currentStatus {
                    idealPositionOverlay(in: geometry)
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
    
    // MARK: - Status Bar
    private var statusBar: some View {
        HStack {
            Image(systemName: statusIcon)
                .font(.system(size: 24))
                .foregroundColor(statusColor)
            
            Text(statusText)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.7))
        )
        .padding(.horizontal)
    }
    
    private var statusText: String {
        switch positionValidator.currentStatus {
        case .correct:
            return "Hold position..."
        case .needsAdjustment:
            return "Adjust your position"
        case .notDetected:
            return "Position yourself in frame"
        }
    }
    
    // MARK: - Angle Indicators
    private var angleIndicators: some View {
        HStack(spacing: 30) {
            switch exerciseType {
            case .pushup, .pullup:
                AngleIndicator(
                    title: "Arms",
                    currentAngle: positionValidator.armAngle,
                    targetRange: exerciseType == .pushup ? 140...180 : 150...180,
                    unit: "°"
                )
                
                AngleIndicator(
                    title: "Body",
                    currentAngle: positionValidator.bodyAlignment,
                    targetRange: 0...(exerciseType == .pushup ? 30 : 20),
                    unit: "°"
                )
                
            case .situp:
                AngleIndicator(
                    title: "Knees",
                    currentAngle: positionValidator.kneeAngle,
                    targetRange: 80...100,
                    unit: "°"
                )
                
            default:
                EmptyView()
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Feedback Messages
    private var feedbackMessages: some View {
        VStack(spacing: 8) {
            if case .needsAdjustment(let feedback) = positionValidator.currentStatus {
                ForEach(feedback, id: \.self) { message in
                    HStack {
                        Image(systemName: "arrow.right.circle.fill")
                            .foregroundColor(.yellow)
                        Text(message)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.black.opacity(0.7))
                    )
                }
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Hold Progress View
    private var holdProgressView: some View {
        VStack(spacing: 8) {
            Text("Hold for \(Int(ceil(2.0 - positionValidator.timeInCorrectPosition))) seconds")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            
            ProgressView(value: positionValidator.timeInCorrectPosition, total: 2.0)
                .progressViewStyle(LinearProgressViewStyle(tint: .green))
                .frame(width: 200)
                .scaleEffect(x: 1, y: 2, anchor: .center)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.7))
        )
    }
    
    // MARK: - Start Button
    private var startButton: some View {
        Button(action: {
            // This will trigger the parent view to start countdown
            showStartButton = false
        }) {
            HStack {
                Image(systemName: "play.fill")
                    .font(.system(size: 20))
                Text("START WORKOUT")
                    .font(.system(size: 18, weight: .bold))
                    .tracking(1)
            }
            .foregroundColor(.black)
            .padding(.horizontal, 30)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.green)
            )
        }
        .shadow(radius: 5)
    }
    
    // MARK: - Ideal Position Overlay
    private func idealPositionOverlay(in geometry: GeometryProxy) -> some View {
        // Ghost overlay showing ideal position with dotted lines
        ZStack {
            switch exerciseType {
            case .pushup:
                PushupIdealPositionGuide()
                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [5, 5]))
                    .foregroundColor(.green.opacity(0.5))
                
            case .pullup:
                PullupIdealPositionGuide()
                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [5, 5]))
                    .foregroundColor(.green.opacity(0.5))
                
            case .situp:
                SitupIdealPositionGuide()
                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [5, 5]))
                    .foregroundColor(.green.opacity(0.5))
                
            default:
                EmptyView()
            }
        }
        .frame(width: geometry.size.width, height: geometry.size.height)
    }
}

// MARK: - Angle Indicator Component
struct AngleIndicator: View {
    let title: String
    let currentAngle: Float
    let targetRange: ClosedRange<Float>
    let unit: String
    
    private var isInRange: Bool {
        targetRange.contains(currentAngle)
    }
    
    private var color: Color {
        isInRange ? .green : .yellow
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)
            
            Text("\(Int(currentAngle))\(unit)")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(color)
            
            Text("\(Int(targetRange.lowerBound))-\(Int(targetRange.upperBound))\(unit)")
                .font(.system(size: 12))
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(color, lineWidth: 2)
                )
        )
    }
}

// MARK: - Ideal Position Guide Shapes
struct PushupIdealPositionGuide: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Draw a stick figure in push-up position
        let centerX = rect.width / 2
        let centerY = rect.height / 2
        
        // Head
        path.addEllipse(in: CGRect(x: centerX - 15, y: centerY - 100, width: 30, height: 30))
        
        // Body line (straight)
        path.move(to: CGPoint(x: centerX, y: centerY - 70))
        path.addLine(to: CGPoint(x: centerX + 60, y: centerY - 50))
        
        // Arms extended
        path.move(to: CGPoint(x: centerX, y: centerY - 70))
        path.addLine(to: CGPoint(x: centerX - 30, y: centerY - 30))
        path.addLine(to: CGPoint(x: centerX - 40, y: centerY))
        
        // Legs
        path.move(to: CGPoint(x: centerX + 60, y: centerY - 50))
        path.addLine(to: CGPoint(x: centerX + 100, y: centerY - 30))
        
        return path
    }
}

struct PullupIdealPositionGuide: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let centerX = rect.width / 2
        let topY = rect.height * 0.2
        
        // Bar
        path.move(to: CGPoint(x: centerX - 60, y: topY))
        path.addLine(to: CGPoint(x: centerX + 60, y: topY))
        
        // Head
        path.addEllipse(in: CGRect(x: centerX - 15, y: topY + 40, width: 30, height: 30))
        
        // Body (straight, hanging)
        path.move(to: CGPoint(x: centerX, y: topY + 70))
        path.addLine(to: CGPoint(x: centerX, y: topY + 150))
        
        // Arms extended up
        path.move(to: CGPoint(x: centerX - 30, y: topY))
        path.addLine(to: CGPoint(x: centerX - 15, y: topY + 40))
        path.move(to: CGPoint(x: centerX + 30, y: topY))
        path.addLine(to: CGPoint(x: centerX + 15, y: topY + 40))
        
        // Legs
        path.move(to: CGPoint(x: centerX, y: topY + 150))
        path.addLine(to: CGPoint(x: centerX - 10, y: topY + 200))
        path.move(to: CGPoint(x: centerX, y: topY + 150))
        path.addLine(to: CGPoint(x: centerX + 10, y: topY + 200))
        
        return path
    }
}

struct SitupIdealPositionGuide: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let centerX = rect.width / 2
        let centerY = rect.height / 2
        
        // Head
        path.addEllipse(in: CGRect(x: centerX - 50, y: centerY - 10, width: 30, height: 30))
        
        // Torso (on ground)
        path.move(to: CGPoint(x: centerX - 35, y: centerY + 5))
        path.addLine(to: CGPoint(x: centerX + 30, y: centerY + 5))
        
        // Arms crossed on chest
        path.move(to: CGPoint(x: centerX - 20, y: centerY))
        path.addLine(to: CGPoint(x: centerX + 10, y: centerY - 10))
        path.move(to: CGPoint(x: centerX - 20, y: centerY - 10))
        path.addLine(to: CGPoint(x: centerX + 10, y: centerY))
        
        // Legs bent at 90 degrees
        path.move(to: CGPoint(x: centerX + 30, y: centerY + 5))
        path.addLine(to: CGPoint(x: centerX + 60, y: centerY + 30))
        path.addLine(to: CGPoint(x: centerX + 60, y: centerY + 60))
        
        return path
    }
}
