import Foundation
import CoreImage
import AVFoundation
import Combine
import Vision

/// Analyzes environmental conditions to dynamically adjust detection confidence thresholds
class EnvironmentAnalyzer: ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentEnvironment: EnvironmentConditions = .unknown
    @Published var recommendedConfidence: Float = 0.5
    @Published var lightingQuality: LightingQuality = .unknown
    @Published var motionStability: MotionStability = .stable
    
    // MARK: - Environment Conditions
    enum EnvironmentConditions {
        case optimal
        case good
        case challenging
        case poor
        case unknown
        
        var confidenceAdjustment: Float {
            switch self {
            case .optimal:
                return 0.0      // Keep base confidence
            case .good:
                return 0.05     // Slight increase
            case .challenging:
                return 0.1      // Moderate increase
            case .poor:
                return 0.2      // Significant increase
            case .unknown:
                return 0.1      // Default moderate increase
            }
        }
    }
    
    enum LightingQuality {
        case excellent
        case good
        case moderate
        case poor
        case veryPoor
        case unknown
        
        init(fromAverageConfidence confidence: Float) {
            switch confidence {
            case 0.8...1.0:
                self = .excellent
            case 0.7..<0.8:
                self = .good
            case 0.6..<0.7:
                self = .moderate
            case 0.5..<0.6:
                self = .poor
            case 0.0..<0.5:
                self = .veryPoor
            default:
                self = .unknown
            }
        }
    }
    
    enum MotionStability {
        case stable
        case slightMotion
        case moderateMotion
        case unstable
        
        init(fromVariance variance: Float) {
            switch variance {
            case 0.0..<0.05:
                self = .stable
            case 0.05..<0.1:
                self = .slightMotion
            case 0.1..<0.2:
                self = .moderateMotion
            default:
                self = .unstable
            }
        }
    }
    
    // MARK: - Private Properties
    private var frameHistory: [FrameAnalysis] = []
    private let maxHistorySize = 30
    private let analysisQueue = DispatchQueue(label: "com.ptchampion.environment.analysis", qos: .userInitiated)
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Frame Analysis
    struct FrameAnalysis {
        let timestamp: TimeInterval
        let averageConfidence: Float
        let poseCompleteness: Float
        let jointVisibility: [VNHumanBodyPoseObservation.JointName: Float]
        let frameStability: Float
    }
    
    // MARK: - Initialization
    init() {
        setupAnalysis()
    }
    
    private func setupAnalysis() {
        // Analyze environment periodically
        Timer.publish(every: 0.5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] (_: Date) in
                self?.analyzeEnvironment()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// Analyze a detected body frame and update environment conditions
    func analyzeFrame(_ detectedBody: DetectedBody?, timestamp: TimeInterval = CACurrentMediaTime()) {
        guard let body = detectedBody else { return }
        
        analysisQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Calculate frame metrics
            let avgConfidence = body.allPoints.map { $0.confidence }.reduce(0, +) / Float(body.allPoints.count)
            let poseCompleteness = Float(body.allPoints.filter { $0.confidence > 0.3 }.count) / Float(body.allPoints.count)
            
            // Create joint visibility map
            var jointVisibility: [VNHumanBodyPoseObservation.JointName: Float] = [:]
            for point in body.allPoints {
                jointVisibility[point.name] = point.confidence
            }
            
            // Calculate frame stability (compare to previous frame if available)
            let frameStability = self.calculateFrameStability(currentBody: body)
            
            // Create frame analysis
            let analysis = FrameAnalysis(
                timestamp: timestamp,
                averageConfidence: avgConfidence,
                poseCompleteness: poseCompleteness,
                jointVisibility: jointVisibility,
                frameStability: frameStability
            )
            
            // Update history
            self.frameHistory.append(analysis)
            if self.frameHistory.count > self.maxHistorySize {
                self.frameHistory.removeFirst()
            }
            
            // Update lighting quality immediately
            DispatchQueue.main.async {
                self.lightingQuality = LightingQuality(fromAverageConfidence: avgConfidence)
            }
        }
    }
    
    /// Get dynamic confidence threshold based on current conditions
    func getDynamicConfidence(baseConfidence: Float = 0.5, exercise: ExerciseType? = nil) -> Float {
        var adjustedConfidence = baseConfidence
        
        // Apply environment adjustment
        adjustedConfidence += currentEnvironment.confidenceAdjustment
        
        // Apply exercise-specific adjustments
        if let exercise = exercise {
            switch exercise {
            case .pushup:
                // Push-ups need clear torso and arm visibility
                if lightingQuality == .poor || lightingQuality == .veryPoor {
                    adjustedConfidence += 0.05
                }
            case .situp:
                // Sit-ups need clear torso tracking
                if motionStability == .moderateMotion || motionStability == .unstable {
                    adjustedConfidence += 0.05
                }
            case .pullup:
                // Pull-ups need full body tracking with tolerance for motion
                if motionStability == .unstable {
                    adjustedConfidence += 0.1
                }
            default:
                break
            }
        }
        
        // Clamp to valid range [0.3, 0.8]
        return max(0.3, min(0.8, adjustedConfidence))
    }
    
    /// Get visibility thresholds adjusted for current environment
    func getAdjustedVisibilityThresholds(base: VisibilityThresholds) -> VisibilityThresholds {
        let adjustment = currentEnvironment.confidenceAdjustment
        
        return VisibilityThresholds(
            minimumConfidence: max(0.3, base.minimumConfidence + adjustment),
            criticalJoints: max(0.4, base.criticalJoints + adjustment),
            supportJoints: max(0.3, base.supportJoints + adjustment),
            faceJoints: max(0.2, base.faceJoints + adjustment)
        )
    }
    
    // MARK: - Private Methods
    
    private func analyzeEnvironment() {
        guard frameHistory.count >= 5 else {
            // Not enough data yet
            return
        }
        
        analysisQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Get recent frames
            let recentFrames = Array(self.frameHistory.suffix(10))
            
            // Calculate average metrics
            let avgConfidence = recentFrames.map { $0.averageConfidence }.reduce(0, +) / Float(recentFrames.count)
            let avgCompleteness = recentFrames.map { $0.poseCompleteness }.reduce(0, +) / Float(recentFrames.count)
            let avgStability = recentFrames.map { $0.frameStability }.reduce(0, +) / Float(recentFrames.count)
            
            // Calculate variance for motion detection
            let confidenceVariance = self.calculateVariance(values: recentFrames.map { $0.averageConfidence })
            
            // Determine environment conditions
            let conditions: EnvironmentConditions
            if avgConfidence > 0.75 && avgCompleteness > 0.85 && avgStability > 0.9 {
                conditions = .optimal
            } else if avgConfidence > 0.65 && avgCompleteness > 0.75 && avgStability > 0.8 {
                conditions = .good
            } else if avgConfidence > 0.55 && avgCompleteness > 0.65 {
                conditions = .challenging
            } else if avgConfidence > 0.4 {
                conditions = .poor
            } else {
                conditions = .unknown
            }
            
            // Update motion stability
            let motionStability = MotionStability(fromVariance: confidenceVariance)
            
            // Calculate recommended confidence
            let baseConfidence: Float = 0.5
            let recommendedConfidence = self.getDynamicConfidence(baseConfidence: baseConfidence)
            
            // Update published properties
            DispatchQueue.main.async {
                self.currentEnvironment = conditions
                self.motionStability = motionStability
                self.recommendedConfidence = recommendedConfidence
            }
        }
    }
    
    private func calculateFrameStability(currentBody: DetectedBody) -> Float {
        guard let lastAnalysis = frameHistory.last else {
            return 1.0 // First frame is considered stable
        }
        
        // Compare key joint positions
        let keyJoints: [VNHumanBodyPoseObservation.JointName] = [
            .leftShoulder, .rightShoulder, .leftHip, .rightHip
        ]
        
        var totalMovement: Float = 0
        var jointCount: Float = 0
        
        for joint in keyJoints {
            guard let currentPoint = currentBody.point(joint),
                  let previousConfidence = lastAnalysis.jointVisibility[joint],
                  previousConfidence > 0.3,
                  currentPoint.confidence > 0.3 else {
                continue
            }
            
            // Simple confidence-based stability (in real app, would track actual positions)
            let confidenceDiff = abs(currentPoint.confidence - previousConfidence)
            totalMovement += confidenceDiff
            jointCount += 1
        }
        
        guard jointCount > 0 else { return 0.5 }
        
        let avgMovement = totalMovement / jointCount
        return max(0, 1.0 - avgMovement * 2) // Convert to stability score
    }
    
    private func calculateVariance(values: [Float]) -> Float {
        guard values.count > 1 else { return 0 }
        
        let mean = values.reduce(0, +) / Float(values.count)
        let squaredDifferences = values.map { pow($0 - mean, 2) }
        return squaredDifferences.reduce(0, +) / Float(values.count - 1)
    }
    
    // MARK: - Debug Information
    func getDebugInfo() -> String {
        return """
        Environment: \(currentEnvironment)
        Lighting: \(lightingQuality)
        Motion: \(motionStability)
        Recommended Confidence: \(String(format: "%.2f", recommendedConfidence))
        Frame History: \(frameHistory.count) frames
        """
    }
}

// MARK: - PoseDetectorService Extension
extension PoseDetectorService {
    /// Enable environment-aware detection
    /// - Returns: AnyCancellable that should be stored by the caller
    func enableEnvironmentAwareDetection(_ analyzer: EnvironmentAnalyzer) -> AnyCancellable {
        // Subscribe to detected body updates
        return detectedBodyPublisher
            .sink { [weak analyzer] body in
                analyzer?.analyzeFrame(body)
            }
    }
    
    /// Set dynamic confidence based on environment
    func setDynamicConfidence(from analyzer: EnvironmentAnalyzer) {
        let confidence = analyzer.recommendedConfidence
        // In a real implementation, this would update MediaPipe's confidence thresholds
        print("📊 Dynamic confidence set to: \(confidence)")
    }
}
