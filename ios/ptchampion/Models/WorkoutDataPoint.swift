import Foundation

struct WorkoutDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
} 