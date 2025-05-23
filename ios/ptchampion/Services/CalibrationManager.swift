import Foundation
import Combine
import CoreMotion
import AVFoundation
import simd
import Vision

/// Manages device calibration for accurate pose detection across different devices and user setups
class CalibrationManager: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentFraming: FramingStatus = .unknown
    @Published var isFramingAcceptable = false
    @Published var adjustmentSuggestions: [CalibrationSuggestion] = []
    @Published var calibrationData: CalibrationData?
    @Published var calibrationQuality: CalibrationQuality = .invalid
    @Published var isReadyForNextPhase = false
    @Published var isCalibrating = false
    @Published var collectionProgress: Double = 0.0
    @Published var detectedPosition: DevicePositionDetector.Position = .unknown
    @Published var positionStability: Float = 0.0
    
    // MARK: - Dependencies
    private let poseDetectorService: PoseDetectorService
    private let motionManager = CMMotionManager()
    private let calibrationRepository: CalibrationRepository
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Calibration State
    private var currentExercise: ExerciseType = .pushup
    private var calibrationFrames: [CalibrationFrame] = []
    private let requiredFrames = 60 // Increased for better accuracy
    private var frameCollectionTimer: Timer?
    private var deviceOrientation: DeviceMotionData?
    private var lastFrameTimestamp: TimeInterval = 0
    private let frameThrottleInterval: TimeInterval = 0.033 // ~30 FPS
    
    // MARK: - Camera Session
    let cameraSession = AVCaptureSession()
    let cameraService: CameraServiceProtocol
    
    // MARK: - Device Position Detection
    private var motionHistory: [DeviceMotionData] = []
    private let maxMotionHistory = 30
    
    // MARK: - Constants
    private struct CalibrationConstants {
        static let stabilityThreshold: Float = 0.1
        static let minConfidenceThreshold: Float = 0.7
        static let frameAnalysisWindow: TimeInterval = 2.0
        static let motionUpdateInterval: TimeInterval = 0.1
    }
    
    // MARK: - Initialization
    init(poseDetectorService: PoseDetectorService, cameraService: CameraServiceProtocol? = nil, calibrationRepository: CalibrationRepository? = nil) {
        self.poseDetectorService = poseDetectorService
        self.cameraService = cameraService ?? CameraService()
        self.calibrationRepository = calibrationRepository ?? CalibrationRepository()
        super.init()
        setupMotionManager()
        setupPoseDetection()
        
        // Migrate any existing UserDefaults calibrations on first run
        Task {
            await self.calibrationRepository.migrateFromUserDefaults()
        }
    }
    
    // MARK: - Setup Methods
    private func setupMotionManager() {
        guard motionManager.isDeviceMotionAvailable else {
            print("⚠️ Device motion not available")
            return
        }
        
        motionManager.deviceMotionUpdateInterval = CalibrationConstants.motionUpdateInterval
    }
    
    private func setupPoseDetection() {
        poseDetectorService.detectedBodyPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] detectedBody in
                self?.handleDetectedPose(detectedBody)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Interface
    func startCalibration(for exercise: ExerciseType) {
        print("🎯 Starting calibration for \(exercise.displayName)")
        
        currentExercise = exercise
        isCalibrating = true
        calibrationFrames.removeAll()
        adjustmentSuggestions.removeAll()
        collectionProgress = 0.0
        isReadyForNextPhase = false
        
        // Start motion tracking
        startMotionTracking()
        
        DispatchQueue.main.async {
            self.currentFraming = .unknown
            self.isFramingAcceptable = false
        }
    }
    
    func stopCalibration() {
        print("🛑 Stopping calibration")
        
        isCalibrating = false
        frameCollectionTimer?.invalidate()
        frameCollectionTimer = nil
        motionManager.stopDeviceMotionUpdates()
        
        calibrationFrames.removeAll()
        collectionProgress = 0.0
        isReadyForNextPhase = false
        
        DispatchQueue.main.async {
            self.currentFraming = .unknown
            self.isFramingAcceptable = false
            self.adjustmentSuggestions.removeAll()
        }
    }
    
    func beginFrameCollection(progressHandler: @escaping (Double) -> Void) {
        print("📊 Beginning frame collection")
        
        calibrationFrames.removeAll()
        collectionProgress = 0.0
        
        frameCollectionTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            let progress = Double(self.calibrationFrames.count) / Double(self.requiredFrames)
            self.collectionProgress = progress
            progressHandler(progress)
            
            if self.calibrationFrames.count >= self.requiredFrames {
                timer.invalidate()
                self.frameCollectionTimer = nil
                self.performCalibration()
            }
        }
    }
    
    func getTargetFraming(for exercise: ExerciseType) -> TargetFraming {
        return TargetFraming.getTargetFraming(for: exercise)
    }
    
    // MARK: - Motion Tracking
    private func startMotionTracking() {
        guard motionManager.isDeviceMotionAvailable else { return }
        
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let motion = motion else {
                if let error = error {
                    print("❌ Motion tracking error: \(error)")
                }
                return
            }
            
            let motionData = DeviceMotionData(from: motion)
            self?.deviceOrientation = motionData
            
            // Update motion history for position detection
            self?.updateMotionHistory(motionData)
            
            // Detect device position continuously
            self?.updateDevicePosition()
        }
    }
    
    private func updateMotionHistory(_ motionData: DeviceMotionData) {
        motionHistory.append(motionData)
        
        // Keep only recent motion data
        if motionHistory.count > maxMotionHistory {
            motionHistory.removeFirst()
        }
    }
    
    private func updateDevicePosition() {
        guard !calibrationFrames.isEmpty else { return }
        
        // Use recent frames and motion history for position detection
        let recentFrames = Array(calibrationFrames.suffix(20))
        let position = DevicePositionDetector.detectPositionContinuous(
            recentFrames: recentFrames,
            motionHistory: motionHistory
        )
        
        DispatchQueue.main.async {
            self.detectedPosition = position
            self.positionStability = position.isStable ? 1.0 : 0.0
            
            // Update suggestions based on position
            self.updatePositionSuggestions(position)
        }
    }
    
    private func updatePositionSuggestions(_ position: DevicePositionDetector.Position) {
        var suggestions = adjustmentSuggestions.filter { $0.type != .devicePosition }
        
        switch position {
        case .handheld:
            suggestions.append(CalibrationSuggestion(
                type: .devicePosition,
                priority: .critical,
                message: "Place device on stable surface for better calibration",
                actionRequired: true
            ))
        case .ground(let angle) where abs(angle) > 45:
            suggestions.append(CalibrationSuggestion(
                type: .devicePosition,
                priority: .important,
                message: "Adjust device angle for better viewing (currently \(Int(angle))°)",
                actionRequired: false
            ))
        case .elevated(_, let angle) where abs(angle) > 60:
            suggestions.append(CalibrationSuggestion(
                type: .devicePosition,
                priority: .important,
                message: "Reduce device angle for more accurate pose detection",
                actionRequired: false
            ))
        default:
            break
        }
        
        self.adjustmentSuggestions = suggestions
    }
    
    // MARK: - Pose Analysis
    private func handleDetectedPose(_ detectedBody: DetectedBody?) {
        guard isCalibrating, let body = detectedBody else { return }
        
        // Throttle frame processing
        let currentTime = CACurrentMediaTime()
        guard currentTime - lastFrameTimestamp >= frameThrottleInterval else { return }
        lastFrameTimestamp = currentTime
        
        // Analyze framing
        let framing = evaluateFraming(body)
        
        DispatchQueue.main.async {
            self.currentFraming = framing
            self.isFramingAcceptable = framing.isAcceptable
            self.generateSuggestions(for: body, framing: framing)
        }
        
        // Collect calibration frames when framing is acceptable
        if framing.isAcceptable && calibrationFrames.count < requiredFrames {
            let frame = createCalibrationFrame(from: body)
            calibrationFrames.append(frame)
            
            DispatchQueue.main.async {
                self.collectionProgress = Double(self.calibrationFrames.count) / Double(self.requiredFrames)
            }
        }
    }
    
    private func evaluateFraming(_ body: DetectedBody) -> FramingStatus {
        let targetFraming = getTargetFraming(for: currentExercise)
        
        // Check if required body parts are visible
        let visibleParts = targetFraming.bodyParts.filter { joint in
            body.point(joint)?.confidence ?? 0 > CalibrationConstants.minConfidenceThreshold
        }
        
        let visibilityRatio = Float(visibleParts.count) / Float(targetFraming.bodyParts.count)
        
        guard visibilityRatio >= targetFraming.minBodyCoverage else {
            return determineFramingIssue(body: body, targetFraming: targetFraming)
        }
        
        // Calculate body center and size
        let bodyCenter = calculateBodyCenter(body)
        let bodySize = calculateBodySize(body)
        
        // Evaluate positioning
        if bodySize < Float(targetFraming.acceptableDistanceRange.lowerBound) {
            return .tooFar
        } else if bodySize > Float(targetFraming.acceptableDistanceRange.upperBound) {
            return .tooClose
        }
        
        if bodyCenter.x < CGFloat(targetFraming.horizontalCenterRange.lowerBound) {
            return .tooLeft
        } else if bodyCenter.x > CGFloat(targetFraming.horizontalCenterRange.upperBound) {
            return .tooRight
        }
        
        if bodyCenter.y < CGFloat(targetFraming.verticalCenterRange.lowerBound) {
            return .tooHigh
        } else if bodyCenter.y > CGFloat(targetFraming.verticalCenterRange.upperBound) {
            return .tooLow
        }
        
        // Check if optimal
        let isOptimalSize = abs(bodySize - targetFraming.optimalDistance) < 0.1
        let isOptimalPosition = abs(bodyCenter.x - 0.5) < 0.1 && abs(bodyCenter.y - 0.5) < 0.1
        
        return (isOptimalSize && isOptimalPosition) ? .optimal : .acceptable
    }
    
    private func determineFramingIssue(body: DetectedBody, targetFraming: TargetFraming) -> FramingStatus {
        let bodyCenter = calculateBodyCenter(body)
        let bodySize = calculateBodySize(body)
        
        // Prioritize distance issues over positioning issues when visibility is poor
        if bodySize < targetFraming.acceptableDistanceRange.lowerBound * 0.8 {
            return .tooFar
        } else if bodySize > targetFraming.acceptableDistanceRange.upperBound * 1.2 {
            return .tooClose
        }
        
        // Check positioning
        if bodyCenter.x < 0.2 {
            return .tooLeft
        } else if bodyCenter.x > 0.8 {
            return .tooRight
        }
        
        if bodyCenter.y < 0.2 {
            return .tooHigh
        } else if bodyCenter.y > 0.8 {
            return .tooLow
        }
        
        return .unknown
    }
    
    private func calculateBodyCenter(_ body: DetectedBody) -> CGPoint {
        let relevantJoints: [VNHumanBodyPoseObservation.JointName] = [
            .leftShoulder, .rightShoulder, .leftHip, .rightHip
        ]
        
        var totalX: CGFloat = 0
        var totalY: CGFloat = 0
        var count = 0
        
        for joint in relevantJoints {
            if let point = body.point(joint), point.confidence > CalibrationConstants.minConfidenceThreshold {
                totalX += point.location.x
                totalY += point.location.y
                count += 1
            }
        }
        
        guard count > 0 else { return CGPoint(x: 0.5, y: 0.5) }
        
        return CGPoint(x: totalX / CGFloat(count), y: totalY / CGFloat(count))
    }
    
    private func calculateBodySize(_ body: DetectedBody) -> Float {
        guard let leftShoulder = body.point(.leftShoulder),
              let rightShoulder = body.point(.rightShoulder),
              let leftHip = body.point(.leftHip),
              let rightHip = body.point(.rightHip) else {
            return 0.5 // Default medium size
        }
        
        // Calculate shoulder width and torso height
        let shoulderWidth = leftShoulder.distance(to: rightShoulder)
        let hipWidth = leftHip.distance(to: rightHip)
        let torsoHeight = abs(leftShoulder.location.y - leftHip.location.y)
        
        // Combine measurements for overall body size estimate
        return Float((shoulderWidth + hipWidth + torsoHeight) / 3.0)
    }
    
    // MARK: - Calibration Frame Creation
    private func createCalibrationFrame(from body: DetectedBody) -> CalibrationFrame {
        let frameQuality = assessFrameQuality(body)
        
        return CalibrationFrame(
            timestamp: CACurrentMediaTime(),
            poseData: body,
            deviceMotion: deviceOrientation,
            frameQuality: frameQuality
        )
    }
    
    private func assessFrameQuality(_ body: DetectedBody) -> CalibrationFrame.FrameQuality {
        let targetFraming = getTargetFraming(for: currentExercise)
        
        // Calculate joint visibility scores
        var jointVisibility: [VNHumanBodyPoseObservation.JointName: Float] = [:]
        var totalConfidence: Float = 0
        var visibleJoints = 0
        
        for joint in targetFraming.bodyParts {
            if let point = body.point(joint) {
                jointVisibility[joint] = point.confidence
                totalConfidence += point.confidence
                if point.confidence > CalibrationConstants.minConfidenceThreshold {
                    visibleJoints += 1
                }
            } else {
                jointVisibility[joint] = 0
            }
        }
        
        let overallConfidence = targetFraming.bodyParts.isEmpty ? 1.0 : totalConfidence / Float(targetFraming.bodyParts.count)
        let bodyCompleteness = targetFraming.bodyParts.isEmpty ? 1.0 : Float(visibleJoints) / Float(targetFraming.bodyParts.count)
        
        // Assess stability based on device motion
        let stability = assessStability()
        
        // Simple lighting assessment based on confidence
        let lighting = min(1.0, overallConfidence * 1.2)
        
        return CalibrationFrame.FrameQuality(
            overallConfidence: overallConfidence,
            jointVisibility: jointVisibility,
            bodyCompleteness: bodyCompleteness,
            stability: stability,
            lighting: lighting
        )
    }
    
    private func assessStability() -> Float {
        guard let motion = deviceOrientation else { return 0.5 }
        
        // Calculate stability based on rotation rates
        let rotationMagnitude = sqrt(
            motion.rotationRate.x * motion.rotationRate.x +
            motion.rotationRate.y * motion.rotationRate.y +
            motion.rotationRate.z * motion.rotationRate.z
        )
        
        // Convert to stability score (lower rotation = higher stability)
        let stability = max(0.0, 1.0 - Float(rotationMagnitude / 2.0))
        return stability
    }
    
    // MARK: - Suggestion Generation
    private func generateSuggestions(for body: DetectedBody, framing: FramingStatus) {
        var suggestions: [CalibrationSuggestion] = []
        
        // Framing suggestions
        if !framing.isAcceptable {
            suggestions.append(CalibrationSuggestion(
                type: .userPosition,
                priority: .critical,
                message: framing.instruction,
                actionRequired: true
            ))
        }
        
        // Stability suggestions
        let stability = assessStability()
        if stability < 0.7 {
            suggestions.append(CalibrationSuggestion(
                type: .stability,
                priority: .important,
                message: "Hold device steady during calibration",
                actionRequired: true
            ))
        }
        
        // Lighting suggestions
        let avgConfidence = body.allPoints.map(\.confidence).reduce(0, +) / Float(body.allPoints.count)
        if avgConfidence < 0.6 {
            suggestions.append(CalibrationSuggestion(
                type: .lighting,
                priority: .important,
                message: "Improve lighting conditions for better detection",
                actionRequired: false
            ))
        }
        
        // Body visibility suggestions
        let targetFraming = getTargetFraming(for: currentExercise)
        let visibleParts = targetFraming.bodyParts.filter { joint in
            body.point(joint)?.confidence ?? 0 > CalibrationConstants.minConfidenceThreshold
        }
        
        if Float(visibleParts.count) / Float(targetFraming.bodyParts.count) < 0.8 {
            suggestions.append(CalibrationSuggestion(
                type: .bodyVisibility,
                priority: .important,
                message: "Ensure full body is visible in camera frame",
                actionRequired: true
            ))
        }
        
        self.adjustmentSuggestions = suggestions
        self.isReadyForNextPhase = suggestions.isEmpty || !suggestions.contains { $0.actionRequired }
    }
    
    // MARK: - Calibration Processing
    private func performCalibration() {
        print("🔬 Performing calibration analysis...")
        
        guard calibrationFrames.count >= requiredFrames else {
            print("❌ Insufficient frames for calibration")
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // Detect final device position
            let devicePosition = DevicePositionDetector.detectPosition(
                from: self.calibrationFrames,
                motionData: self.deviceOrientation?.toCMDeviceMotion()
            )
            
            let measurements = self.calculateUserMeasurements(from: self.calibrationFrames)
            let deviceMetrics = self.calculateDeviceMetrics(from: self.calibrationFrames, position: devicePosition)
            let angleAdjustments = self.calculateAngleAdjustments(
                for: self.currentExercise,
                devicePosition: devicePosition,
                userHeight: measurements.height
            )
            
            let calibration = CalibrationData(
                id: UUID(),
                timestamp: Date(),
                exercise: self.currentExercise,
                deviceHeight: deviceMetrics.height,
                deviceAngle: deviceMetrics.angle,
                deviceDistance: deviceMetrics.distance,
                deviceStability: deviceMetrics.stability,
                userHeight: measurements.height,
                armSpan: measurements.armSpan,
                torsoLength: measurements.torsoLength,
                legLength: measurements.legLength,
                angleAdjustments: angleAdjustments,
                visibilityThresholds: self.calculateVisibilityThresholds(deviceMetrics),
                poseNormalization: self.calculateNormalization(measurements),
                calibrationScore: self.calculateCalibrationScore(),
                confidenceLevel: self.calculateConfidence(),
                frameCount: self.calibrationFrames.count,
                validationRanges: self.calculateValidationRanges()
            )
            
            DispatchQueue.main.async {
                self.calibrationData = calibration
                self.calibrationQuality = self.evaluateCalibrationQuality(calibration)
                
                // Save to repository
                Task {
                    do {
                        try await self.calibrationRepository.saveCalibration(calibration)
                        print("✅ Calibration saved to repository with quality: \(self.calibrationQuality)")
                    } catch {
                        print("❌ Failed to save calibration to repository: \(error)")
                        // Fallback to UserDefaults for backward compatibility
                        self.saveCalibrationToUserDefaults(calibration)
                    }
                }
            }
        }
    }
    
    // MARK: - Measurement Calculations
    private func calculateUserMeasurements(from frames: [CalibrationFrame]) -> (height: Float, armSpan: Float, torsoLength: Float, legLength: Float) {
        var heights: [Float] = []
        var armSpans: [Float] = []
        var torsoLengths: [Float] = []
        var legLengths: [Float] = []
        
        for frame in frames {
            let body = frame.poseData
            
            // Calculate height (head to foot)
            if let nose = body.point(.nose),
               let leftAnkle = body.point(.leftAnkle),
               let rightAnkle = body.point(.rightAnkle) {
                let ankleCenter = CGPoint(
                    x: (leftAnkle.location.x + rightAnkle.location.x) / 2,
                    y: (leftAnkle.location.y + rightAnkle.location.y) / 2
                )
                let height = Float(nose.distance(to: DetectedPoint(name: .nose, location: ankleCenter, confidence: 1.0)))
                heights.append(height)
            }
            
            // Calculate arm span (wrist to wrist)
            if let leftWrist = body.point(.leftWrist),
               let rightWrist = body.point(.rightWrist) {
                let armSpan = Float(leftWrist.distance(to: rightWrist))
                armSpans.append(armSpan)
            }
            
            // Calculate torso length (shoulder to hip)
            if let leftShoulder = body.point(.leftShoulder),
               let rightShoulder = body.point(.rightShoulder),
               let leftHip = body.point(.leftHip),
               let rightHip = body.point(.rightHip) {
                let shoulderCenter = CGPoint(
                    x: (leftShoulder.location.x + rightShoulder.location.x) / 2,
                    y: (leftShoulder.location.y + rightShoulder.location.y) / 2
                )
                let hipCenter = CGPoint(
                    x: (leftHip.location.x + rightHip.location.x) / 2,
                    y: (leftHip.location.y + rightHip.location.y) / 2
                )
                let torsoLength = Float(sqrt(pow(shoulderCenter.x - hipCenter.x, 2) + pow(shoulderCenter.y - hipCenter.y, 2)))
                torsoLengths.append(torsoLength)
            }
            
            // Calculate leg length (hip to ankle)
            if let leftHip = body.point(.leftHip),
               let leftAnkle = body.point(.leftAnkle) {
                let legLength = Float(leftHip.distance(to: leftAnkle))
                legLengths.append(legLength)
            }
        }
        
        // Calculate averages, filtering outliers
        let height = filterOutliersAndAverage(heights)
        let armSpan = filterOutliersAndAverage(armSpans)
        let torsoLength = filterOutliersAndAverage(torsoLengths)
        let legLength = filterOutliersAndAverage(legLengths)
        
        return (height, armSpan, torsoLength, legLength)
    }
    
    private func calculateDeviceMetrics(from frames: [CalibrationFrame], position: DevicePositionDetector.Position) -> (height: Float, angle: Float, distance: Float, stability: Float) {
        
        // Extract basic metrics from motion data
        var angles: [Float] = []
        var stabilities: [Float] = []
        
        for frame in frames {
            if let motion = frame.deviceMotion {
                let angle = Float(atan2(motion.gravity.x, motion.gravity.y) * 180.0 / .pi)
                angles.append(abs(angle))
                stabilities.append(frame.frameQuality.stability)
            }
        }
        
        let averageAngle = filterOutliersAndAverage(angles)
        let averageStability = filterOutliersAndAverage(stabilities)
        
        // Use detected position for more accurate metrics
        switch position {
        case .ground(let angle):
            return (0.1, angle, 1.2, averageStability)
        case .elevated(let height, let angle):
            return (height, angle, 1.5, averageStability)
        case .tripod(let height, let angle):
            return (height, angle, 1.8, min(1.0, averageStability + 0.2)) // Bonus for tripod stability
        case .handheld:
            return (1.0, averageAngle, 1.0, max(0.3, averageStability - 0.3)) // Penalty for handheld
        case .unknown:
            return (1.0, averageAngle, 1.5, averageStability)
        }
    }
    
    private func calculateVisibilityThresholds(_ devicePosition: (height: Float, angle: Float, distance: Float, stability: Float)) -> VisibilityThresholds {
        // Adjust thresholds based on device position and stability
        let baseConfidence: Float = 0.5
        let stabilityBonus = devicePosition.stability * 0.2
        let distanceAdjustment = max(-0.1, min(0.1, (1.5 - devicePosition.distance) * 0.1))
        
        let adjustedConfidence = baseConfidence + stabilityBonus + distanceAdjustment
        
        return VisibilityThresholds(
            minimumConfidence: max(0.3, adjustedConfidence - 0.1),
            criticalJoints: max(0.4, adjustedConfidence),
            supportJoints: max(0.3, adjustedConfidence - 0.2),
            faceJoints: max(0.2, adjustedConfidence - 0.3)
        )
    }
    
    private func calculateNormalization(_ measurements: (height: Float, armSpan: Float, torsoLength: Float, legLength: Float)) -> PoseNormalization {
        // Normalize measurements to create scaling factors
        // Using average human proportions as baseline
        let avgHeight: Float = 1.7 // meters
        let heightRatio = measurements.height / avgHeight
        
        return PoseNormalization(
            shoulderWidth: measurements.armSpan * 0.2, // Approximate shoulder width
            hipWidth: measurements.armSpan * 0.15,     // Approximate hip width
            armLength: measurements.armSpan * 0.5,     // Half of arm span
            legLength: measurements.legLength,
            headSize: measurements.height * 0.13       // Approximate head size ratio
        )
    }
    
    private func calculateValidationRanges() -> ValidationRanges {
        // Define acceptable ranges for validation
        return ValidationRanges(
            angleTolerances: [
                "pushup_elbow": 10.0,
                "situp_torso": 15.0,
                "pullup_arm": 10.0,
                "body_alignment": 20.0
            ],
            positionTolerances: [
                "horizontal_drift": 0.1,
                "vertical_drift": 0.1,
                "distance_variation": 0.2
            ],
            movementThresholds: [
                "max_speed": 30.0,
                "min_speed": 2.0,
                "stability_window": 5.0
            ]
        )
    }
    
    private func calculateCalibrationScore() -> Float {
        guard !calibrationFrames.isEmpty else { return 0 }
        
        let avgQuality = calibrationFrames.map(\.frameQuality.overallConfidence).reduce(0, +) / Float(calibrationFrames.count)
        let avgStability = calibrationFrames.compactMap(\.frameQuality.stability).reduce(0, +) / Float(calibrationFrames.count)
        let avgCompleteness = calibrationFrames.map(\.frameQuality.bodyCompleteness).reduce(0, +) / Float(calibrationFrames.count)
        
        let score = (avgQuality * 0.4 + avgStability * 0.3 + avgCompleteness * 0.3) * 100
        return min(100, max(0, score))
    }
    
    private func calculateConfidence() -> Float {
        let score = calculateCalibrationScore()
        return score / 100.0
    }
    
    private func evaluateCalibrationQuality(_ calibration: CalibrationData) -> CalibrationQuality {
        let score = calibration.calibrationScore
        
        switch score {
        case 90...100: return .excellent
        case 80..<90: return .good
        case 70..<80: return .acceptable
        case 60..<70: return .poor
        default: return .invalid
        }
    }
    
    // MARK: - Angle Adjustment Calculations
    private func calculateAngleAdjustments(
        for exercise: ExerciseType,
        devicePosition: DevicePositionDetector.Position,
        userHeight: Float
    ) -> AngleAdjustments {
        // Base angles from APFT standards
        var pushupElbowUp: Float = 170
        var pushupElbowDown: Float = 90
        var pushupBodyAlignment: Float = 15 // degrees of acceptable deviation
        var situpTorsoUp: Float = 90
        var situpTorsoDown: Float = 45
        var situpKneeAngle: Float = 90
        var pullupArmExtended: Float = 170
        var pullupArmFlexed: Float = 90
        var pullupBodyVertical: Float = 10 // degrees of acceptable swing
        
        // Apply adjustments based on device position
        switch devicePosition {
        case .ground(let angle):
            // Camera on ground - adjust angles based on viewing angle
            if angle < 30 {
                pushupElbowDown -= 5
                situpTorsoDown += 5
            } else if angle > 45 {
                pushupElbowDown += 5
                situpTorsoDown -= 5
            }
            
        case .elevated(let height, let angle):
            // Camera elevated - adjust based on height and angle
            if height > 1.5 {
                pushupElbowDown += 5
                pullupArmFlexed -= 5
            }
            if angle > 60 {
                pushupElbowDown += 5
                situpTorsoDown -= 5
            }
            
        case .tripod(let height, let angle):
            // Tripod mounted - most stable, minimal adjustments
            if angle > 45 {
                pushupBodyAlignment += 5
                situpTorsoDown -= 3
            }
            
        case .handheld:
            // Handheld - increase tolerances due to instability
            pushupBodyAlignment += 10
            pullupBodyVertical += 5
            
        case .unknown:
            // Keep defaults
            break
        }
        
        // Adjust based on user height (taller users may need different angles)
        let heightFactor = userHeight / 1.7 // Normalize to average height
        if heightFactor > 1.1 {
            // Taller users
            pushupElbowDown += 3
            situpTorsoDown += 3
        } else if heightFactor < 0.9 {
            // Shorter users
            pushupElbowDown -= 3
            situpTorsoDown -= 3
        }
        
        // Create and return the immutable struct with final values
        return AngleAdjustments(
            pushupElbowUp: pushupElbowUp,
            pushupElbowDown: pushupElbowDown,
            pushupBodyAlignment: pushupBodyAlignment,
            situpTorsoUp: situpTorsoUp,
            situpTorsoDown: situpTorsoDown,
            situpKneeAngle: situpKneeAngle,
            pullupArmExtended: pullupArmExtended,
            pullupArmFlexed: pullupArmFlexed,
            pullupBodyVertical: pullupBodyVertical
        )
    }
    
    // MARK: - Utility Methods
    private func filterOutliersAndAverage(_ values: [Float]) -> Float {
        guard !values.isEmpty else { return 0 }
        guard values.count > 2 else { return values.reduce(0, +) / Float(values.count) }
        
        let sorted = values.sorted()
        let q1 = sorted[sorted.count / 4]
        let q3 = sorted[3 * sorted.count / 4]
        let iqr = q3 - q1
        let lowerBound = q1 - 1.5 * iqr
        let upperBound = q3 + 1.5 * iqr
        
        let filtered = values.filter { $0 >= lowerBound && $0 <= upperBound }
        return filtered.isEmpty ? values.reduce(0, +) / Float(values.count) : filtered.reduce(0, +) / Float(filtered.count)
    }
    
    // MARK: - Repository Integration
    private func saveCalibrationToUserDefaults(_ calibration: CalibrationData) {
        // Fallback method for backward compatibility
        do {
            let data = try JSONEncoder().encode(calibration)
            UserDefaults.standard.set(data, forKey: "calibration_\(calibration.exercise.rawValue)")
            print("💾 Calibration saved to UserDefaults as fallback")
        } catch {
            print("❌ Failed to save calibration to UserDefaults: \(error)")
        }
    }
    
    func loadSavedCalibration(for exercise: ExerciseType) async -> CalibrationData? {
        // Try repository first
        if let calibration = await calibrationRepository.getBestCalibration(for: exercise) {
            return calibration
        }
        
        // Fallback to UserDefaults
        guard let data = UserDefaults.standard.data(forKey: "calibration_\(exercise.rawValue)"),
              let calibration = try? JSONDecoder().decode(CalibrationData.self, from: data) else {
            print("⚠️ No saved calibration found for \(exercise.displayName)")
            return nil
        }
        
        // Migrate to repository
        Task {
            do {
                try await calibrationRepository.saveCalibration(calibration)
                UserDefaults.standard.removeObject(forKey: "calibration_\(exercise.rawValue)")
                print("🔄 Migrated calibration for \(exercise.displayName) from UserDefaults")
            } catch {
                print("❌ Failed to migrate calibration: \(error)")
            }
        }
        
        return calibration
    }
    
    // MARK: - Cleanup
    deinit {
        stopCalibration()
        cancellables.forEach { $0.cancel() }
    }
}

// MARK: - Device Motion Extension
private extension DeviceMotionData {
    func toCMDeviceMotion() -> CMDeviceMotion? {
        // This is a simplified conversion - in practice, you might need to create a mock CMDeviceMotion
        // or store the original CMDeviceMotion reference
        // For now, we'll return nil and rely on the DeviceMotionData directly
        return nil
    }
}
