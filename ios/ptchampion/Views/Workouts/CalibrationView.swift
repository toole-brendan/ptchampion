import SwiftUI
import AVFoundation

/// Main calibration view that guides users through device calibration for optimal pose detection
struct CalibrationView: View {
    @ObservedObject var calibrationManager: CalibrationManager
    @State private var calibrationPhase: CalibrationPhase = .positioning
    @State private var frameAnalysisProgress: Double = 0
    @State private var showingCompletionSheet = false
    @State private var currentOrientation = UIDevice.current.orientation
    @Environment(\.dismiss) private var dismiss
    
    let exercise: ExerciseType
    let onComplete: (CalibrationData) -> Void
    
    enum CalibrationPhase {
        case positioning
        case analyzing
        case adjusting
        case complete
    }
    
    var body: some View {
        ZStack {
            // Camera preview background
            CameraPreviewView(session: calibrationManager.cameraSession, cameraService: calibrationManager.cameraService)
                .edgesIgnoringSafeArea(.all)
                .onAppear {
                    checkCameraPermission()
                }
                .onDisappear {
                    stopCameraSession()
                }
            
            // Dark overlay for better text visibility
            Color.black.opacity(0.3)
                .edgesIgnoringSafeArea(.all)
            
            // Main calibration content
            VStack(spacing: 20) {
                // Top instruction bar
                CalibrationInstructionBar(
                    phase: calibrationPhase,
                    exercise: exercise,
                    currentFraming: calibrationManager.currentFraming
                )
                .padding(.top, 20)
                
                Spacer()
                
                // Phase-specific content
                Group {
                    switch calibrationPhase {
                    case .positioning:
                        AdaptiveCalibrationGuide(
                            framing: calibrationManager.currentFraming,
                            exerciseType: exercise,
                            suggestions: calibrationManager.adjustmentSuggestions
                        )
                        .edgesIgnoringSafeArea(.all)
                        .transition(.opacity)
                        
                    case .analyzing:
                        AnalyzingView(progress: frameAnalysisProgress)
                            .transition(.scale)
                        
                    case .adjusting:
                        AdjustmentSuggestionsView(
                            suggestions: calibrationManager.adjustmentSuggestions
                        )
                        .transition(.slide)
                        
                    case .complete:
                        CalibrationCompleteView(
                            calibrationQuality: calibrationManager.calibrationQuality,
                            calibrationData: calibrationManager.calibrationData
                        )
                        .transition(.scale)
                    }
                }
                .frame(maxWidth: .infinity)
                
                Spacer()
                
                // Bottom action controls
                VStack(spacing: 16) {
                    // Progress indicator (if applicable)
                    if calibrationPhase == .analyzing {
                        ProgressView(value: frameAnalysisProgress)
                            .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                            .frame(height: 4)
                            .background(Color.white.opacity(0.3))
                            .cornerRadius(2)
                            .padding(.horizontal)
                    }
                    
                    // Action buttons
                    HStack(spacing: 16) {
                        // Cancel button
                        Button("Cancel") {
                            calibrationManager.stopCalibration()
                            dismiss()
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(8)
                        
                        Spacer()
                        
                        // Primary action button
                        CalibrationActionButton(
                            phase: calibrationPhase,
                            isReady: calibrationManager.isReadyForNextPhase,
                            action: handlePhaseAction
                        )
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 40)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            calibrationManager.startCalibration(for: exercise)
        }
        .onDisappear {
            calibrationManager.stopCalibration()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                currentOrientation = UIDevice.current.orientation
                // Force recalculation of framing
                calibrationManager.reevaluateFraming()
            }
        }
        .onChange(of: calibrationManager.calibrationData) { calibrationData in
            if calibrationData != nil && calibrationPhase != .complete {
                withAnimation(.easeInOut(duration: 0.5)) {
                    calibrationPhase = .complete
                }
            }
        }
        .sheet(isPresented: $showingCompletionSheet) {
            if let calibrationData = calibrationManager.calibrationData {
                CalibrationResultsSheet(
                    calibrationData: calibrationData,
                    quality: calibrationManager.calibrationQuality,
                    onAccept: {
                        showingCompletionSheet = false
                        onComplete(calibrationData)
                    },
                    onRetry: {
                        showingCompletionSheet = false
                        restartCalibration()
                    }
                )
            }
        }
    }
    
    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            startCameraSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    DispatchQueue.main.async {
                        self.startCameraSession()
                    }
                }
            }
        default:
            print("❌ Camera permission denied")
        }
    }
    
    private func startCameraSession() {
        // Add a small delay to ensure the view is fully loaded
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            DispatchQueue.global(qos: .userInitiated).async {
                if !self.calibrationManager.cameraSession.isRunning {
                    self.calibrationManager.cameraSession.startRunning()
                    print("📷 Camera session started")
                }
            }
        }
    }
    
    private func stopCameraSession() {
        DispatchQueue.global(qos: .userInitiated).async {
            if calibrationManager.cameraSession.isRunning {
                calibrationManager.cameraSession.stopRunning()
            }
        }
    }
    
    private func handlePhaseAction() {
        switch calibrationPhase {
        case .positioning:
            if calibrationManager.isFramingAcceptable && calibrationManager.isReadyForNextPhase {
                withAnimation(.easeInOut(duration: 0.3)) {
                    calibrationPhase = .analyzing
                }
                startAnalysis()
            }
        case .analyzing:
            // Automatic progression - no user action needed
            break
        case .adjusting:
            withAnimation(.easeInOut(duration: 0.3)) {
                calibrationPhase = .positioning
            }
        case .complete:
            if let calibrationData = calibrationManager.calibrationData {
                if calibrationManager.calibrationQuality == .poor || calibrationManager.calibrationQuality == .invalid {
                    showingCompletionSheet = true
                } else {
                    onComplete(calibrationData)
                }
            }
        }
    }
    
    private func startAnalysis() {
        frameAnalysisProgress = 0
        calibrationManager.beginFrameCollection { progress in
            withAnimation(.linear(duration: 0.1)) {
                frameAnalysisProgress = progress
            }
            
            if progress >= 1.0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    processCalibrationResults()
                }
            }
        }
    }
    
    private func processCalibrationResults() {
        // Check if we need adjustments or if calibration is complete
        if calibrationManager.adjustmentSuggestions.contains(where: { $0.actionRequired }) {
            withAnimation(.easeInOut(duration: 0.3)) {
                calibrationPhase = .adjusting
            }
        } else {
            // Calibration will be completed automatically by the manager
            // The view will transition to .complete when calibrationData is set
        }
    }
    
    private func restartCalibration() {
        calibrationManager.stopCalibration()
        calibrationPhase = .positioning
        frameAnalysisProgress = 0
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            calibrationManager.startCalibration(for: exercise)
        }
    }
}

// MARK: - Supporting Views

/// Instruction bar at the top showing current phase and guidance
struct CalibrationInstructionBar: View {
    let phase: CalibrationView.CalibrationPhase
    let exercise: ExerciseType
    let currentFraming: FramingStatus
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: phaseIcon)
                    .foregroundColor(.white)
                    .font(.title2)
                
                Text(phaseTitle)
                    .font(.headline)
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // Status indicator
                Circle()
                    .fill(statusColor)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
            }
            
            Text(instructionText)
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.leading)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 20)
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
    
    private var phaseIcon: String {
        switch phase {
        case .positioning: return "viewfinder"
        case .analyzing: return "camera.metering.spot"
        case .adjusting: return "slider.horizontal.3"
        case .complete: return "checkmark.circle"
        }
    }
    
    private var phaseTitle: String {
        switch phase {
        case .positioning: return "Position Yourself"
        case .analyzing: return "Analyzing..."
        case .adjusting: return "Adjustments Needed"
        case .complete: return "Calibration Complete"
        }
    }
    
    private var instructionText: String {
        switch phase {
        case .positioning:
            if currentFraming.isAcceptable {
                return "Perfect! Hold steady and tap 'Begin Analysis' when ready."
            } else {
                return currentFraming.instruction
            }
        case .analyzing:
            return "Stay still while we analyze your position and movement patterns."
        case .adjusting:
            return "Please make the suggested adjustments and reposition yourself."
        case .complete:
            return "Calibration successful! Your \(exercise.displayName) detection is now optimized."
        }
    }
    
    private var statusColor: Color {
        switch phase {
        case .positioning:
            return currentFraming.isAcceptable ? .green : .orange
        case .analyzing:
            return .blue
        case .adjusting:
            return .red
        case .complete:
            return .green
        }
    }
}

/// Action button that changes based on the current calibration phase
struct CalibrationActionButton: View {
    let phase: CalibrationView.CalibrationPhase
    let isReady: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                if phase == .analyzing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: buttonIcon)
                        .font(.title3)
                }
                
                Text(buttonText)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(buttonColor)
            .cornerRadius(8)
        }
        .disabled(!isReady && phase != .complete)
        .opacity((!isReady && phase != .complete) ? 0.6 : 1.0)
    }
    
    private var buttonText: String {
        switch phase {
        case .positioning:
            return isReady ? "Begin Analysis" : "Position Yourself"
        case .analyzing:
            return "Analyzing..."
        case .adjusting:
            return "Reposition"
        case .complete:
            return "Continue"
        }
    }
    
    private var buttonIcon: String {
        switch phase {
        case .positioning:
            return "play.circle"
        case .analyzing:
            return "hourglass"
        case .adjusting:
            return "arrow.clockwise"
        case .complete:
            return "checkmark"
        }
    }
    
    private var buttonColor: Color {
        switch phase {
        case .positioning:
            return isReady ? .blue : .gray
        case .analyzing:
            return .blue
        case .adjusting:
            return .orange
        case .complete:
            return .green
        }
    }
}

// MARK: - Preview
struct CalibrationView_Previews: PreviewProvider {
    static var previews: some View {
        CalibrationView(
            calibrationManager: CalibrationManager(poseDetectorService: PoseDetectorService()),
            exercise: .pushup
        ) { _ in
            print("Calibration complete")
        }
    }
}
