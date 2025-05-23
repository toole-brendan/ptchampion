import Foundation
import Combine
import SwiftUI // For @Published and ObservableObject

class WorkoutTimer: ObservableObject {
    @Published var elapsedTime: Int = 0
    @Published var formattedElapsedTime: String = "00:00"
    @Published var isRunning: Bool = false // True if not paused and timer is active

    private var timerSubscription: Cancellable? = nil
    var workoutStartTime: Date? = nil
    private var accumulatedTime: Int = 0 // To handle pause/resume
    private var internalPauseState: Bool = false

    init() {
        print("DEBUG: [WorkoutTimer] Initializing WorkoutTimer")
        // Update formatted time whenever elapsedTime changes
        $elapsedTime
            .map { seconds in
                print("DEBUG: [WorkoutTimer] elapsedTime changed to \(seconds)")
                return self.formatTime(seconds)
            }
            .assign(to: &$formattedElapsedTime)
        
        print("DEBUG: [WorkoutTimer] WorkoutTimer initialized - initial formattedElapsedTime: \(formattedElapsedTime)")
    }

    func start() {
        guard !isRunning else { 
            print("DEBUG: [WorkoutTimer] start() called but timer is already running")
            return 
        }
        
        print("DEBUG: [WorkoutTimer] Starting timer...")
        resetState() // Reset before starting a new timer session
        workoutStartTime = Date()
        internalPauseState = false
        isRunning = true
        
        print("DEBUG: [WorkoutTimer] Creating timer subscription...")
        timerSubscription = Timer.publish(every: 1, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            guard let self = self, self.isRunning, !self.internalPauseState else { 
                print("DEBUG: [WorkoutTimer] Timer tick skipped - isRunning: \(self?.isRunning ?? false), paused: \(self?.internalPauseState ?? false)")
                return 
            }
            
            self.elapsedTime = self.accumulatedTime + Int(Date().timeIntervalSince(self.workoutStartTime ?? Date()))
            print("DEBUG: [WorkoutTimer] Timer tick - elapsedTime: \(self.elapsedTime), formatted: \(self.formattedElapsedTime)")
        }
        
        print("DEBUG: [WorkoutTimer] Timer started successfully, isRunning: \(isRunning)")
    }

    func pause() {
        guard isRunning, !internalPauseState else { return }
        internalPauseState = true
        //isRunning = false // Or keep isRunning true to indicate timer is active but paused
        accumulatedTime = elapsedTime // Save current elapsed time before pausing timer
        timerSubscription?.cancel() // Stop the timer publisher
        timerSubscription = nil
        print("Timer paused. Accumulated time: \(accumulatedTime)s")
    }

    func resume() {
        guard isRunning, internalPauseState else { return }
        workoutStartTime = Date() // Reset start time for the new interval
        internalPauseState = false
        timerSubscription = Timer.publish(every: 1, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            guard let self = self, self.isRunning, !self.internalPauseState else { return }
            // Calculate elapsed time based on the new interval + previously accumulated time
            self.elapsedTime = self.accumulatedTime + Int(Date().timeIntervalSince(self.workoutStartTime ?? Date()))
        }
        print("Timer resumed. Starting from accumulated: \(accumulatedTime)s")
    }

    func stop() {
        guard isRunning else { return }
        timerSubscription?.cancel()
        timerSubscription = nil
        isRunning = false
        internalPauseState = false
        // elapsed time remains at its last value
        print("Timer stopped at \(formattedElapsedTime)")
    }

    func reset() {
        print("DEBUG: [WorkoutTimer] reset() called")
        stop() // Ensure current timer is stopped
        resetState()
        print("DEBUG: [WorkoutTimer] Timer reset completed.")
    }
    
    private func resetState() {
        print("DEBUG: [WorkoutTimer] resetState() called - resetting all timer state")
        elapsedTime = 0
        accumulatedTime = 0
        workoutStartTime = nil
        internalPauseState = false
        // isRunning will be set by start()
        print("DEBUG: [WorkoutTimer] resetState() completed - elapsedTime: \(elapsedTime), formattedElapsedTime: \(formattedElapsedTime)")
    }

    private func formatTime(_ totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    deinit {
        timerSubscription?.cancel()
        print("WorkoutTimer deinitialized.")
    }
} 