import SwiftUI
import AVFoundation

/// Enhanced calibration view with progressive modes, visual guides, and dynamic optimization
struct EnhancedCalibrationView: View {
    @ObservedObject var calibrationManager: CalibrationManager
    @StateObject private var environmentAnalyzer = EnvironmentAnalyzer()
    @StateObject private var performanceOptimizer = PerformanceOptimizer()
    @StateObject private var strategyManager: CalibrationStrategyManager
    
    @State private var calibrationMode: CalibrationMode = .quick
    @State private var calibrationPhase: CalibrationPhase = .modeSelection
    @State private var frameAnalysisProgress: Double = 0
    @State private var showingCompletionSheet = false
    @State private var showingSkipAlert = false
    @State private var hasShownQuickStartTip = false
    
    @Environment(\.dismiss) private var dismiss
    @AppStorage("hasCompletedFullCalibration") private var hasCompletedFullCalibration = false
    @AppStorage("calibrationRepsCount") private var calibrationRepsCount = 0
    
    let exercise: ExerciseType
    let onComplete: (CalibrationData) -> Void
    
    enum CalibrationPhase {
        case modeSelection
        case positioning
        case analyzing
        case adjusting
        case complete
    }
    
    init(calibrationManager: CalibrationManager, exercise: ExerciseType, onComplete: @escaping (CalibrationData) -> Void) {
        self.calibrationManager = calibrationManager
        self.exercise = exercise
        self.onComplete = onComplete
        self._strategyManager = StateObject(wrappedValue: CalibrationStrategyManager(exercise: exercise))
    }
    
    var body: some View {
        ZStack {
            // Camera preview background
            CameraPreviewView(session: calibrationManager.cameraSession, cameraService: calibrationManager.cameraService)
                .edgesIgnoringSafeArea(.all)
                .onAppear {
                    startCameraSession()
                    setupEnvironmentAnalysis()
                }
                .onDisappear {
                    stopCameraSession()
                }
            
            // Dark overlay for better visibility
            Color.black.opacity(0.3)
                .edgesIgnoringSafeArea(.all)
            
            // Main content
            VStack(spacing: 20) {
                // Top bar with mode indicator
                EnhancedCalibrationTopBar(
                    phase: calibrationPhase,
                    mode: calibrationMode,
                    exercise: exercise,
                    currentFraming: calibrationManager.currentFraming,
                    strategy: strategyManager.currentStrategy
                )
                .padding(.top, 20)
                
                Spacer()
                
                // Phase-specific content
                Group {
                    switch calibrationPhase {
                    case .modeSelection:
                        CalibrationModeSelectionView(
                            selectedMode: $calibrationMode,
                            hasCompletedFull: hasCompletedFullCalibration,
                            onModeSelected: handleModeSelection
                        )
                        .transition(.scale)
                        
                    case .positioning:
                        EnhancedPositioningGuideOverlay(
                            currentFraming: calibrationManager.currentFraming,
                            targetFraming: calibrationManager.getTargetFraming(for: exercise),
                            suggestions: calibrationManager.adjustmentSuggestions,
                            environmentAnalyzer: environmentAnalyzer
                        )
                        .transition(.opacity)
                        
                    case .analyzing:
                        AnalyzingView(progress: frameAnalysisProgress)
                            .transition(.scale)
                        
                    case .adjusting:
                        EnhancedAdjustmentView(
                            suggestions: calibrationManager.adjustmentSuggestions,
                            strategy: strategyManager.currentStrategy,
                            onFallback: handleStrategyFallback
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
                
                // Bottom controls
                EnhancedCalibrationControls(
                    phase: calibrationPhase,
                    mode: calibrationMode,
                    isReady: calibrationManager.isReadyForNextPhase,
                    progress: frameAnalysisProgress,
                    onCancel: handleCancel,
                    onAction: handlePhaseAction,
                    onSkip: handleSkipCalibration
                )
                .padding(.bottom, 40)
            }
            
            // Performance overlay (debug mode)
            #if DEBUG
            PerformanceOverlay(optimizer: performanceOptimizer)
                .position(x: 80, y: UIScreen.main.bounds.height - 100)
            #endif
        }
        .navigationBarHidden(true)
        .onAppear {
            startCalibration()
        }
        .onDisappear {
            calibrationManager.stopCalibration()
        }
        .onChange(of: calibrationManager.calibrationData) { calibrationData in
            if calibrationData != nil && calibrationPhase != .complete {
                withAnimation(.easeInOut(duration: 0.5)) {
                    calibrationPhase = .complete
                }
            }
        }
        .alert("Skip Calibration?", isPresented: $showingSkipAlert) {
            Button("Skip", role: .destructive) {
                performQuickStart()
            }
            Button("Continue", role: .cancel) {}
        } message: {
            Text("You can always calibrate later for better accuracy. Start with basic tracking now?")
        }
        .sheet(isPresented: $showingCompletionSheet) {
            if let calibrationData = calibrationManager.calibrationData {
                CalibrationResultsSheet(
                    calibrationData: calibrationData,
                    quality: calibrationManager.calibrationQuality,
                    onAccept: {
                        showingCompletionSheet = false
                        completeCalibration(calibrationData)
                    },
                    onRetry: {
                        showingCompletionSheet = false
                        restartCalibration()
                    }
                )
            }
        }
    }
    
    // MARK: - Setup Methods
    
    private func startCameraSession() {
        DispatchQueue.global(qos: .userInitiated).async {
            if !calibrationManager.cameraSession.isRunning {
                calibrationManager.cameraSession.startRunning()
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
    
    private func setupEnvironmentAnalysis() {
        // Connect environment analyzer to pose detector
        calibrationManager.poseDetectorService.enableEnvironmentAwareDetection(environmentAnalyzer)
        
        // Configure performance optimizer
        performanceOptimizer.configure(for: exercise, mode: .balanced)
        performanceOptimizer.applyOptimizations(to: calibrationManager.poseDetectorService)
    }
    
    private func startCalibration() {
        // Show mode selection only if user hasn't completed full calibration
        if !hasCompletedFullCalibration && calibrationRepsCount < 5 {
            calibrationPhase = .modeSelection
        } else {
            // Auto-select mode based on history
            calibrationMode = hasCompletedFullCalibration ? .basic : .full
            handleModeSelection(calibrationMode)
        }
    }
    
    // MARK: - Phase Handlers
    
    private func handleModeSelection(_ mode: CalibrationMode) {
        calibrationMode = mode
        
        if mode == .quick {
            // Skip directly to completion with default calibration
            performQuickStart()
        } else {
            // Configure calibration manager for selected mode
            calibrationManager.requiredFrames = mode.requiredFrames
            calibrationManager.startCalibration(for: exercise)
            
            // Select appropriate strategy
            calibrationManager.poseDetectorService.detectedBodyPublisher
                .first()
                .sink { [weak self] body in
                    self?.strategyManager.selectStrategy(for: body)
                }
                .store(in: &calibrationManager.cancellables)
            
            withAnimation(.easeInOut(duration: 0.3)) {
                calibrationPhase = .positioning
            }
        }
    }
    
    private func handlePhaseAction() {
        switch calibrationPhase {
        case .modeSelection:
            // Handled by mode selection view
            break
            
        case .positioning:
            if calibrationManager.isFramingAcceptable && calibrationManager.isReadyForNextPhase {
                withAnimation(.easeInOut(duration: 0.3)) {
                    calibrationPhase = .analyzing
                }
                startAnalysis()
            }
            
        case .analyzing:
            // Automatic progression
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
                    completeCalibration(calibrationData)
                }
            }
        }
    }
    
    private func handleSkipCalibration() {
        if calibrationPhase == .positioning && !hasShownQuickStartTip {
            hasShownQuickStartTip = true
            showingSkipAlert = true
        } else {
            performQuickStart()
        }
    }
    
    private func handleCancel() {
        calibrationManager.stopCalibration()
        dismiss()
    }
    
    private func handleStrategyFallback() {
        strategyManager.fallbackToNextStrategy()
        
        // Reset to positioning with new strategy
        withAnimation(.easeInOut(duration: 0.3)) {
            calibrationPhase = .positioning
        }
    }
    
    // MARK: - Calibration Methods
    
    private func startAnalysis() {
        frameAnalysisProgress = 0
        
        // Use strategy-specific frame requirements
        let requiredFrames = strategyManager.currentStrategy?.requiredFrames ?? calibrationMode.requiredFrames
        
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
        // Use strategy manager to perform calibration
        if let calibrationData = strategyManager.performCalibration(frames: calibrationManager.calibrationFrames) {
            calibrationManager.calibrationData = calibrationData
            calibrationManager.calibrationQuality = calibrationManager.evaluateCalibrationQuality(calibrationData)
        } else if calibrationManager.adjustmentSuggestions.contains(where: { $0.actionRequired }) {
            withAnimation(.easeInOut(duration: 0.3)) {
                calibrationPhase = .adjusting
            }
        }
    }
    
    private func performQuickStart() {
        // Use default calibration profile
        let defaultCalibration = DefaultCalibrationProfiles.getDefault(for: exercise)
        
        // Apply environment adjustments
        let adjustedThresholds = environmentAnalyzer.getAdjustedVisibilityThresholds(
            base: defaultCalibration.visibilityThresholds
        )
        
        let quickCalibration = CalibrationData(
            id: defaultCalibration.id,
            timestamp: Date(),
            exercise: exercise,
            deviceHeight: defaultCalibration.deviceHeight,
            deviceAngle: defaultCalibration.deviceAngle,
            deviceDistance: defaultCalibration.deviceDistance,
            deviceStability: defaultCalibration.deviceStability,
            userHeight: defaultCalibration.userHeight,
            armSpan: defaultCalibration.armSpan,
            torsoLength: defaultCalibration.torsoLength,
            legLength: defaultCalibration.legLength,
            angleAdjustments: defaultCalibration.angleAdjustments,
            visibilityThresholds: adjustedThresholds,
            poseNormalization: defaultCalibration.poseNormalization,
            calibrationScore: 70.0,
            confidenceLevel: 0.7,
            frameCount: 0,
            validationRanges: defaultCalibration.validationRanges
        )
        
        completeCalibration(quickCalibration)
    }
    
    private func completeCalibration(_ calibrationData: CalibrationData) {
        // Update completion status
        if calibrationMode == .full {
            hasCompletedFullCalibration = true
        }
        
        // Track calibration progress
        let progress = CalibrationProgress(
            exercise: exercise,
            mode: calibrationMode,
            completedReps: calibrationRepsCount,
            lastPromptDate: Date(),
            hasCompletedFullCalibration: calibrationMode == .full
        )
        
        // Save progress (in real app, would persist this)
        print("📊 Calibration completed: \(progress)")
        
        onComplete(calibrationData)
    }
    
    private func restartCalibration() {
        calibrationManager.stopCalibration()
        calibrationPhase = .modeSelection
        frameAnalysisProgress = 0
        hasShownQuickStartTip = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            startCalibration()
        }
    }
}

// MARK: - Supporting Views

/// Enhanced top bar with mode and strategy information
struct EnhancedCalibrationTopBar: View {
    let phase: EnhancedCalibrationView.CalibrationPhase
    let mode: CalibrationMode
    let exercise: ExerciseType
    let currentFraming: FramingStatus
    let strategy: CalibrationStrategy?
    
    var body: some View {
        VStack(spacing: 12) {
            // Mode indicator
            if phase != .modeSelection {
                HStack {
                    Label(mode.displayName, systemImage: "speedometer")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    
                    if let strategy = strategy {
                        Divider()
                            .frame(height: 12)
                            .background(Color.white.opacity(0.5))
                        
                        Text(strategy.strategyName)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.2))
                )
            }
            
            // Standard instruction bar
            CalibrationInstructionBar(
                phase: mapPhase(phase),
                exercise: exercise,
                currentFraming: currentFraming
            )
        }
    }
    
    private func mapPhase(_ phase: EnhancedCalibrationView.CalibrationPhase) -> CalibrationView.CalibrationPhase {
        switch phase {
        case .modeSelection, .positioning:
            return .positioning
        case .analyzing:
            return .analyzing
        case .adjusting:
            return .adjusting
        case .complete:
            return .complete
        }
    }
}

/// Mode selection view for progressive calibration
struct CalibrationModeSelectionView: View {
    @Binding var selectedMode: CalibrationMode
    let hasCompletedFull: Bool
    let onModeSelected: (CalibrationMode) -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Choose Calibration Mode")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Select how you'd like to set up exercise tracking")
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
            
            VStack(spacing: 16) {
                ForEach(CalibrationMode.allCases, id: \.self) { mode in
                    CalibrationModeCard(
                        mode: mode,
                        isRecommended: recommendedMode == mode,
                        action: {
                            selectedMode = mode
                            onModeSelected(mode)
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var recommendedMode: CalibrationMode {
        hasCompletedFull ? .quick : .basic
    }
}

struct CalibrationModeCard: View {
    let mode: CalibrationMode
    let isRecommended: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: modeIcon)
                        .font(.title2)
                        .foregroundColor(modeColor)
                    
                    Text(mode.displayName)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    if isRecommended {
                        Text("Recommended")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(modeColor)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                }
                
                Text(mode.description)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.leading)
                
                if mode.requiredFrames > 0 {
                    HStack {
                        Image(systemName: "clock")
                            .font(.caption)
                        Text("\(mode.requiredFrames / 20) seconds")
                            .font(.caption)
                    }
                    .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isRecommended ? modeColor : Color.white.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
    
    private var modeIcon: String {
        switch mode {
        case .quick: return "hare"
        case .basic: return "gauge"
        case .full: return "star"
        }
    }
    
    private var modeColor: Color {
        switch mode {
        case .quick: return .green
        case .basic: return .blue
        case .full: return .purple
        }
    }
}

/// Enhanced adjustment view with fallback options
struct EnhancedAdjustmentView: View {
    let suggestions: [CalibrationSuggestion]
    let strategy: CalibrationStrategy?
    let onFallback: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            AdjustmentSuggestionsView(suggestions: suggestions)
            
            if let strategy = strategy,
               !(strategy is ManualCalibrationStrategy) {
                VStack(spacing: 12) {
                    Text("Having trouble?")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Button("Try Different Method") {
                        onFallback()
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.orange)
                    .cornerRadius(8)
                }
                .padding(.top, 20)
            }
        }
    }
}

/// Enhanced controls with skip option
struct EnhancedCalibrationControls: View {
    let phase: EnhancedCalibrationView.CalibrationPhase
    let mode: CalibrationMode
    let isReady: Bool
    let progress: Double
    let onCancel: () -> Void
    let onAction: () -> Void
    let onSkip: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Progress indicator
            if phase == .analyzing {
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .frame(height: 4)
                    .background(Color.white.opacity(0.3))
                    .cornerRadius(2)
                    .padding(.horizontal)
            }
            
            // Action buttons
            HStack(spacing: 16) {
                // Cancel/Skip button
                Button(action: phase == .positioning ? onSkip : onCancel) {
                    Text(phase == .positioning ? "Skip" : "Cancel")
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(8)
                }
                
                Spacer()
                
                // Primary action button
                if phase != .modeSelection {
                    CalibrationActionButton(
                        phase: mapPhase(phase),
                        isReady: isReady,
                        action: onAction
                    )
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func mapPhase(_ phase: EnhancedCalibrationView.CalibrationPhase) -> CalibrationView.CalibrationPhase {
        switch phase {
        case .modeSelection, .positioning:
            return .positioning
        case .analyzing:
            return .analyzing
        case .adjusting:
            return .adjusting
        case .complete:
            return .complete
        }
    }
}

/// Performance overlay for debugging
struct PerformanceOverlay: View {
    @ObservedObject var optimizer: PerformanceOptimizer
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Performance")
                .font(.caption2)
                .fontWeight(.bold)
            
            Text("\(Int(optimizer.currentFrameRate)) FPS")
                .font(.caption)
            
            Text(optimizer.performanceMode.description)
                .font(.caption2)
        }
        .foregroundColor(.white)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.7))
        )
    }
}

// MARK: - Preview

struct EnhancedCalibrationView_Previews: PreviewProvider {
    static var previews: some View {
        EnhancedCalibrationView(
            calibrationManager: CalibrationManager(poseDetectorService: PoseDetectorService()),
            exercise: .pushup
        ) { _ in
            print("Calibration complete")
        }
    }
}
