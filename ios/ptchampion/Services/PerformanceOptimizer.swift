import Foundation
import Combine
import AVFoundation
import UIKit

/// Manages exercise-specific performance optimizations including dynamic frame rates
class PerformanceOptimizer: ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentFrameRate: Double = 20.0
    @Published var performanceMode: PerformanceMode = .balanced
    @Published var deviceCapability: DeviceCapability = .unknown
    @Published var optimizationSettings: OptimizationSettings?
    
    // MARK: - Performance Modes
    enum PerformanceMode: Equatable {
        case powerSaver     // Lower frame rate, reduced processing
        case balanced       // Default settings
        case performance    // Higher frame rate, full processing
        case custom(fps: Double)
        
        var description: String {
            switch self {
            case .powerSaver:
                return "Power Saver"
            case .balanced:
                return "Balanced"
            case .performance:
                return "Performance"
            case .custom(let fps):
                return "Custom (\(Int(fps)) FPS)"
            }
        }
    }
    
    // MARK: - Device Capability
    enum DeviceCapability {
        case high       // Latest devices with high performance
        case medium     // Mid-range devices
        case low        // Older devices
        case unknown
        
        init() {
            // Determine device capability based on model
            let device = UIDevice.current
            let modelName = device.model
            
            // Simplified device detection - in production would be more comprehensive
            if modelName.contains("iPhone") {
                let systemVersion = device.systemVersion
                if let majorVersion = Int(systemVersion.components(separatedBy: ".").first ?? "0") {
                    if majorVersion >= 15 {
                        self = .high
                    } else if majorVersion >= 13 {
                        self = .medium
                    } else {
                        self = .low
                    }
                } else {
                    self = .unknown
                }
            } else if modelName.contains("iPad") {
                self = .high // iPads generally have good performance
            } else {
                self = .unknown
            }
        }
        
        var maxFrameRate: Double {
            switch self {
            case .high:
                return 30.0
            case .medium:
                return 25.0
            case .low:
                return 20.0
            case .unknown:
                return 20.0
            }
        }
    }
    
    // MARK: - Optimization Settings
    struct OptimizationSettings {
        let targetFrameRate: Double
        let throttleInterval: TimeInterval
        let enableMotionBlur: Bool
        let enableAdvancedTracking: Bool
        let confidenceThreshold: Float
        
        init(exercise: ExerciseType, mode: PerformanceMode, capability: DeviceCapability) {
            // Determine target frame rate based on exercise and mode
            switch mode {
            case .powerSaver:
                self.targetFrameRate = 15.0
            case .balanced:
                self.targetFrameRate = Self.getBalancedFrameRate(for: exercise, capability: capability)
            case .performance:
                self.targetFrameRate = Self.getPerformanceFrameRate(for: exercise, capability: capability)
            case .custom(let fps):
                self.targetFrameRate = fps
            }
            
            self.throttleInterval = 1.0 / targetFrameRate
            self.enableMotionBlur = capability == .high && mode != .powerSaver
            self.enableAdvancedTracking = mode == .performance
            self.confidenceThreshold = mode == .powerSaver ? 0.6 : 0.5
        }
        
        private static func getBalancedFrameRate(for exercise: ExerciseType, capability: DeviceCapability) -> Double {
            switch exercise {
            case .pushup:
                return 20.0  // Moderate movement speed
            case .situp:
                return 25.0  // Faster torso movement
            case .pullup:
                return capability == .high ? 30.0 : 25.0  // Full body tracking needed
            default:
                return 20.0
            }
        }
        
        private static func getPerformanceFrameRate(for exercise: ExerciseType, capability: DeviceCapability) -> Double {
            let maxRate = capability.maxFrameRate
            
            switch exercise {
            case .pushup:
                return min(25.0, maxRate)
            case .situp:
                return min(30.0, maxRate)
            case .pullup:
                return maxRate  // Maximum available
            default:
                return min(25.0, maxRate)
            }
        }
    }
    
    // MARK: - Private Properties
    private var currentExercise: ExerciseType?
    private var performanceMonitor: PerformanceMonitor
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        self.deviceCapability = DeviceCapability()
        self.performanceMonitor = PerformanceMonitor()
        
        setupPerformanceMonitoring()
    }
    
    // MARK: - Public Methods
    
    /// Configure optimizer for specific exercise
    func configure(for exercise: ExerciseType, mode: PerformanceMode? = nil) {
        currentExercise = exercise
        
        // Use provided mode or auto-select based on device
        let selectedMode = mode ?? autoSelectMode()
        performanceMode = selectedMode
        
        // Create optimization settings
        optimizationSettings = OptimizationSettings(
            exercise: exercise,
            mode: selectedMode,
            capability: deviceCapability
        )
        
        // Update frame rate
        if let settings = optimizationSettings {
            currentFrameRate = settings.targetFrameRate
            
            print("🚀 Performance optimization configured:")
            print("  Exercise: \(exercise.displayName)")
            print("  Mode: \(selectedMode.description)")
            print("  Frame Rate: \(Int(settings.targetFrameRate)) FPS")
            print("  Device: \(deviceCapability)")
        }
    }
    
    /// Apply optimizations to pose detector
    func applyOptimizations(to poseDetector: PoseDetectorService) {
        guard let settings = optimizationSettings else { return }
        
        // Configure throttling
        poseDetector.setThrottling(
            enabled: true,
            framesPerSecond: settings.targetFrameRate
        )
        
        // In a real implementation, would also configure:
        // - MediaPipe model complexity
        // - Confidence thresholds
        // - Processing resolution
    }
    
    /// Dynamically adjust performance based on current conditions
    func adjustPerformance(basedOn metrics: PerformanceMetrics) {
        guard let exercise = currentExercise,
              let currentSettings = optimizationSettings else { return }
        
        // Check if we need to adjust
        if metrics.averageFPS < currentSettings.targetFrameRate * 0.8 {
            // Performance is below target, reduce frame rate
            if currentFrameRate > 15.0 {
                currentFrameRate = max(15.0, currentFrameRate - 5.0)
                print("⚠️ Reducing frame rate to \(Int(currentFrameRate)) FPS due to performance")
            }
        } else if metrics.averageFPS > currentSettings.targetFrameRate * 0.95 &&
                  metrics.cpuUsage < 0.7 {
            // Performance is good, can increase if below max
            let maxRate = deviceCapability.maxFrameRate
            if currentFrameRate < maxRate && currentFrameRate < currentSettings.targetFrameRate {
                currentFrameRate = min(maxRate, currentFrameRate + 5.0)
                print("✅ Increasing frame rate to \(Int(currentFrameRate)) FPS")
            }
        }
        
        // Update settings with new frame rate
        optimizationSettings = OptimizationSettings(
            exercise: exercise,
            mode: .custom(fps: currentFrameRate),
            capability: deviceCapability
        )
    }
    
    /// Get recommended settings for calibration
    func getCalibrationSettings() -> OptimizationSettings {
        // Use balanced settings for calibration
        return OptimizationSettings(
            exercise: .pushup, // Default exercise
            mode: .balanced,
            capability: deviceCapability
        )
    }
    
    // MARK: - Private Methods
    
    private func setupPerformanceMonitoring() {
        // Monitor performance metrics
        performanceMonitor.metricsPublisher
            .throttle(for: .seconds(2), scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] metrics in
                self?.adjustPerformance(basedOn: metrics)
            }
            .store(in: &cancellables)
    }
    
    private func autoSelectMode() -> PerformanceMode {
        switch deviceCapability {
        case .high:
            return .performance
        case .medium:
            return .balanced
        case .low:
            return .powerSaver
        case .unknown:
            return .balanced
        }
    }
}

// MARK: - Performance Monitor

/// Monitors real-time performance metrics
class PerformanceMonitor: ObservableObject {
    @Published var currentMetrics: PerformanceMetrics = PerformanceMetrics()
    
    let metricsPublisher = PassthroughSubject<PerformanceMetrics, Never>()
    
    private var frameTimestamps: [TimeInterval] = []
    private var timer: Timer?
    
    init() {
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    func recordFrame() {
        let timestamp = CACurrentMediaTime()
        frameTimestamps.append(timestamp)
        
        // Keep only recent frames (last 2 seconds)
        let cutoff = timestamp - 2.0
        frameTimestamps.removeAll { $0 < cutoff }
    }
    
    private func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateMetrics()
        }
    }
    
    private func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateMetrics() {
        let now = CACurrentMediaTime()
        let recentFrames = frameTimestamps.filter { now - $0 <= 1.0 }
        
        let fps = Double(recentFrames.count)
        let cpuUsage = getCurrentCPUUsage()
        let memoryUsage = getCurrentMemoryUsage()
        
        let metrics = PerformanceMetrics(
            averageFPS: fps,
            cpuUsage: cpuUsage,
            memoryUsage: memoryUsage,
            timestamp: now
        )
        
        currentMetrics = metrics
        metricsPublisher.send(metrics)
    }
    
    private func getCurrentCPUUsage() -> Double {
        // Simplified CPU usage - in production would use proper system APIs
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        return result == KERN_SUCCESS ? Double(info.resident_size) / Double(1024 * 1024 * 1024) : 0.5
    }
    
    private func getCurrentMemoryUsage() -> Double {
        // Simplified memory usage
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if result == KERN_SUCCESS {
            let usedMemory = Double(info.resident_size) / Double(1024 * 1024) // MB
            let totalMemory = Double(ProcessInfo.processInfo.physicalMemory) / Double(1024 * 1024) // MB
            return usedMemory / totalMemory
        }
        
        return 0.5
    }
}

// MARK: - Performance Metrics

struct PerformanceMetrics {
    let averageFPS: Double
    let cpuUsage: Double
    let memoryUsage: Double
    let timestamp: TimeInterval
    
    init(averageFPS: Double = 0, cpuUsage: Double = 0, memoryUsage: Double = 0, timestamp: TimeInterval = 0) {
        self.averageFPS = averageFPS
        self.cpuUsage = cpuUsage
        self.memoryUsage = memoryUsage
        self.timestamp = timestamp
    }
    
    var description: String {
        return String(format: "FPS: %.1f | CPU: %.1f%% | Memory: %.1f%%",
                     averageFPS,
                     cpuUsage * 100,
                     memoryUsage * 100)
    }
}

// MARK: - PoseDetectorService Extension

extension PoseDetectorService {
    /// Record frame for performance monitoring
    func recordFrameForPerformance(_ monitor: PerformanceMonitor) {
        monitor.recordFrame()
    }
}
