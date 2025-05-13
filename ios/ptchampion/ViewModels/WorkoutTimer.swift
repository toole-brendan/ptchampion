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
        // Update formatted time whenever elapsedTime changes
        $elapsedTime
            .map { self.formatTime($0) }
            .assign(to: &$formattedElapsedTime)
    }

    func start() {
        guard !isRunning else { return }
        resetState() // Reset before starting a new timer session
        workoutStartTime = Date()
        internalPauseState = false
        isRunning = true
        timerSubscription = Timer.publish(every: 1, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            guard let self = self, self.isRunning, !self.internalPauseState else { return }
            self.elapsedTime = self.accumulatedTime + Int(Date().timeIntervalSince(self.workoutStartTime ?? Date()))
        }
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
        stop() // Ensure current timer is stopped
        resetState()
        print("Timer reset.")
    }
    
    private func resetState() {
        elapsedTime = 0
        accumulatedTime = 0
        workoutStartTime = nil
        internalPauseState = false
        // isRunning will be set by start()
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
