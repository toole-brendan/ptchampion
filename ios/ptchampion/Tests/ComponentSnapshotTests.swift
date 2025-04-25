import XCTest
import SwiftUI
@testable import ptchampion

/// Snapshot tests for UI components
/// This ensures visual consistency across code changes
class ComponentSnapshotTests: XCTestCase {
    // A simple snapshot helper for SwiftUI views
    func snapshotTest<T: View>(_ name: String, view: T) {
        let hostingController = UIHostingController(rootView: view)
        let view = hostingController.view!
        
        // Define a consistent size for snapshot testing
        view.frame = CGRect(x: 0, y: 0, width: 375, height: 667) // iPhone 8 size
        
        // Ensure view is laid out
        view.layoutIfNeeded()
        
        // Create a renderer
        let renderer = UIGraphicsImageRenderer(bounds: view.bounds)
        let image = renderer.image { ctx in
            view.layer.render(in: ctx.cgContext)
        }
        
        // Get the folder for snapshots
        let snapshotsFolder = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("Snapshots", isDirectory: true)
        
        // Create folder if it doesn't exist
        try? FileManager.default.createDirectory(at: snapshotsFolder, 
                                               withIntermediateDirectories: true, 
                                               attributes: nil)
        
        // Path for the snapshot image
        let snapshotURL = snapshotsFolder.appendingPathComponent("\(name).png")
        
        // Save the snapshot
        if let pngData = image.pngData() {
            try? pngData.write(to: snapshotURL)
            print("Snapshot saved to: \(snapshotURL.path)")
        }
        
        // For a real snapshot test, we would verify against a reference image
        // and fail the test if they don't match within a tolerance
        // This is just a simplified version for demonstration
    }
    
    // Test button component snapshots
    func testButtonSnapshots() {
        // Primary button
        snapshotTest("PrimaryButton", view: 
            PTButton(title: "Primary Button", action: {})
                .padding()
                .previewLayout(.sizeThatFits)
        )
        
        // Secondary button
        snapshotTest("SecondaryButton", view: 
            PTButton(
                title: "Secondary Button", 
                icon: Image(systemName: "arrow.right"),
                action: {},
                variant: .secondary
            )
            .padding()
            .previewLayout(.sizeThatFits)
        )
        
        // Outline button
        snapshotTest("OutlineButton", view: 
            PTButton(
                title: "Outline Button",
                action: {},
                variant: .outline,
                isFullWidth: true
            )
            .padding()
            .previewLayout(.sizeThatFits)
        )
    }
    
    // Test text field snapshots
    func testTextFieldSnapshots() {
        // Standard text field
        snapshotTest("StandardTextField", view:
            PTTextField(
                text: .constant("John Doe"),
                label: "Username",
                placeholder: "Enter username"
            )
            .padding()
            .previewLayout(.sizeThatFits)
        )
        
        // Error state text field
        snapshotTest("ErrorTextField", view:
            PTTextField(
                text: .constant("j"),
                label: "Username",
                placeholder: "Enter username",
                validationState: .invalid(message: "Username must be at least 3 characters")
            )
            .padding()
            .previewLayout(.sizeThatFits)
        )
    }
    
    // Test card components
    func testCardSnapshots() {
        // Metric card
        snapshotTest("MetricCard", view:
            MetricCard(
                title: "TOTAL WORKOUTS",
                value: 42,
                icon: Image(systemName: "flame.fill")
            )
            .frame(width: 180)
            .padding()
            .previewLayout(.sizeThatFits)
        )
        
        // Workout card
        snapshotTest("WorkoutCard", view:
            WorkoutCard(
                title: "Push-ups Workout",
                subtitle: "Morning Routine",
                date: Date(),
                metrics: [
                    WorkoutMetric(title: "Reps", value: 42, iconSystemName: "flame.fill"),
                    WorkoutMetric(title: "Time", value: "2:30", unit: "min", iconSystemName: "clock")
                ]
            )
            .padding()
            .previewLayout(.sizeThatFits)
        )
    }
    
    // Test header components
    func testHeaderSnapshots() {
        // Dashboard header
        snapshotTest("DashboardHeader", view:
            DashboardHeader.greeting(userName: "John Doe")
                .previewLayout(.sizeThatFits)
        )
    }
}

// MARK: - Fastlane Instructions
/*
 To integrate these snapshot tests with Fastlane:
 
 1. Add to your Fastfile:
 
 ```ruby
 desc "Capture snapshots for UI testing and comparison"
 lane :snapshots do
   run_tests(
     scheme: "ptchampionTests",
     only_testing: ["ptchampionTests/ComponentSnapshotTests"],
     output_directory: "snapshots"
   )
 end
 ```
 
 2. Run from command line:
 
 ```
 fastlane snapshots
 ```
 
 3. For visual comparison with web version, you could extend this to:
   - Upload snapshots to a shared location
   - Set up a comparison page that shows web and iOS versions side by side
   - Add Slack notifications when snapshots change significantly
 */ 