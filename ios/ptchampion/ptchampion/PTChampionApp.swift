import SwiftUI
import SwiftData

@main
struct PTChampionApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: WorkoutResultSwiftData.self)
    }
} 