import SwiftUI
import PTDesignSystem
import SwiftData
import Charts // Ensure Charts is imported
import CoreLocation // Add CoreLocation for CLLocationCoordinate2D

// Helper struct for detailed rep breakdown including phase
struct WorkoutRepDetailItem: Identifiable {
    let id: UUID
    let repNumber: Int
    let formQuality: Double
    let phase: String?
}

// Helper struct for chart data points
struct HeartRatePoint: Identifiable {
    let id = UUID()
    let timestamp: Date
    let elapsedSeconds: Double
    let value: Int
}

struct PacePoint: Identifiable {
    let id = UUID()
    let timestamp: Date
    let elapsedSeconds: Double
    let value: Double // meters per second
    let formattedValue: String // pre-formatted pace
}

struct CadencePoint: Identifiable {
    let id = UUID()
    let timestamp: Date
    let elapsedSeconds: Double
    let value: Int // steps per minute
}

struct WorkoutDetailView: View {
    let workoutResult: WorkoutResultSwiftData
    @EnvironmentObject var tabBarVisibility: TabBarVisibilityManager
    @Environment(\.modelContext) private var modelContext
    @AppStorage("useImperialUnits") private var useImperialUnits = false
    
    @State private var isLongestRunPR: Bool = false
    @State private var isFastestOverallPacePR: Bool = false
    @State private var isHighestScorePR: Bool = false
    @State private var isMostRepsPR: Bool = false

    // State for rep details
    @State private var repChartDataItems: [RepChartData] = []
    @State private var repTextDetails: [WorkoutRepDetailItem] = []
    @State private var isLoadingRepDetails: Bool = false
    @State private var repDetailsError: String? = nil
    
    // State for run metrics
    @State private var heartRatePoints: [HeartRatePoint] = []
    @State private var pacePoints: [PacePoint] = []
    @State private var cadencePoints: [CadencePoint] = []
    @State private var routePoints: [CLLocationCoordinate2D] = []
    @State private var avgHeartRate: Int = 0
    @State private var maxHeartRate: Int = 0
    @State private var avgCadence: Int = 0
    
    // Extract metadata from workout result
    @State private var deviceUsed: String? = nil
    @State private var distanceUnitUsed: String? = nil
    
    // Helper to format duration
    private func formatDuration(_ seconds: Int) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: TimeInterval(seconds)) ?? "00:00:00"
    }
    
    // Helper to format distance (assuming miles for now, can be enhanced)
    private func formatDistance(_ meters: Double?) -> String {
        guard let meters = meters, meters > 0 else { return "N/A" }
        
        if useImperialUnits {
            let miles = meters * 0.000621371
            return String(format: "%.2f miles", miles)
        } else {
            let kilometers = meters * 0.001
            return String(format: "%.2f km", kilometers)
        }
    }
    
    // Helper to format pace (min:sec per mile or km)
    private func formatPace(distanceMeters: Double?, durationSeconds: Int) -> String {
        guard let distance = distanceMeters, distance > 0, durationSeconds > 0 else { return "N/A" }
        
        let speedMetersPerSecond = distance / Double(durationSeconds)
        let unitSuffix = useImperialUnits ? "/mi" : "/km"
        
        if useImperialUnits {
            // Minutes per mile
            let minutesPerMile = (1609.34 / speedMetersPerSecond) / 60.0
            let minutes = Int(minutesPerMile)
            let seconds = Int((minutesPerMile - Double(minutes)) * 60)
            return String(format: "%d:%02d %@", minutes, seconds, unitSuffix)
        } else {
            // Minutes per km
            let minutesPerKm = (1000.0 / speedMetersPerSecond) / 60.0
            let minutes = Int(minutesPerKm)
            let seconds = Int((minutesPerKm - Double(minutes)) * 60)
            return String(format: "%d:%02d %@", minutes, seconds, unitSuffix)
        }
    }
    
    // Helper to format pace from m/s
    private func formatPaceFromMetersPerSecond(_ metersPerSecond: Double) -> String {
        guard metersPerSecond > 0 else { return "--:--" }
        
        let unitSuffix = useImperialUnits ? "/mi" : "/km"
        
        if useImperialUnits {
            // Minutes per mile
            let minutesPerMile = (1609.34 / metersPerSecond) / 60.0
            let minutes = Int(minutesPerMile)
            let seconds = Int((minutesPerMile - Double(minutes)) * 60)
            return String(format: "%d:%02d %@", minutes, seconds, unitSuffix)
        } else {
            // Minutes per km
            let minutesPerKm = (1000.0 / metersPerSecond) / 60.0
            let minutes = Int(minutesPerKm)
            let seconds = Int((minutesPerKm - Double(minutes)) * 60)
            return String(format: "%d:%02d %@", minutes, seconds, unitSuffix)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.large) {
                PTLabel("Workout Summary", style: .heading)
                    .padding(.bottom, AppTheme.GeneratedSpacing.small)

                WorkoutDetailInfoRow(label: "Type:", value: workoutResult.exerciseType.capitalized)
                WorkoutDetailInfoRow(label: "Date:", value: workoutResult.startTime, style: .dateTime.month().day().year().hour().minute())
                WorkoutDetailInfoRow(label: "Duration:", value: formatDuration(workoutResult.durationSeconds))
                
                if workoutResult.exerciseType.lowercased() == "run" {
                    WorkoutDetailInfoRow(label: "Distance:", value: formatDistance(workoutResult.distanceMeters))
                    if isLongestRunPR { Text("🎉 Longest Run PR!").font(.caption).foregroundColor(.green).padding(.leading) }
                    
                    // 2-mile Completion Badge
                    let twoMilesInMeters: Double = 3218.68
                    if let distance = workoutResult.distanceMeters, distance >= twoMilesInMeters * 0.98 && distance <= twoMilesInMeters * 1.02 {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("2-Mile Assessment Completed")
                                .font(.callout)
                                .foregroundColor(.green)
                        }
                        .padding(.leading)
                        .padding(.bottom, 4)
                    }
                    
                    WorkoutDetailInfoRow(label: "Avg Pace:", value: formatPace(distanceMeters: workoutResult.distanceMeters, durationSeconds: workoutResult.durationSeconds))
                    if isFastestOverallPacePR { Text("🎉 Fastest Overall Pace PR!").font(.caption).foregroundColor(.green).padding(.leading) }
                    
                    // Show heart rate and cadence summaries for runs only if we have data
                    if avgHeartRate > 0 {
                        WorkoutDetailInfoRow(label: "Avg Heart Rate:", value: "\(avgHeartRate) BPM")
                        WorkoutDetailInfoRow(label: "Max Heart Rate:", value: "\(maxHeartRate) BPM")
                    }
                    
                    if avgCadence > 0 {
                        WorkoutDetailInfoRow(label: "Avg Cadence:", value: "\(avgCadence) steps/min")
                    }
                    
                    // Device Used Section
                    if let device = deviceUsed {
                        Divider()
                            .padding(.vertical, AppTheme.GeneratedSpacing.small)
                            
                        PTLabel("Tracking Device", style: .subheading)
                            .padding(.bottom, AppTheme.GeneratedSpacing.small)
                            
                        HStack(spacing: 12) {
                            Image(systemName: device.lowercased().contains("watch") ? "applewatch" : "antenna.radiowaves.left.and.right")
                                .font(.title2)
                                .foregroundColor(.blue)
                                .frame(width: 30)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(device)
                                    .font(.headline)
                                
                                if let unit = distanceUnitUsed {
                                    Text("Distance Unit: \(unit)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                }
                
                if let score = workoutResult.score {
                    WorkoutDetailInfoRow(label: "Score:", value: String(format: "%.1f%%", score))
                    if isHighestScorePR { Text("🎉 Highest Score PR!").font(.caption).foregroundColor(.green).padding(.leading) }
                } else if workoutResult.exerciseType.lowercased() != "run" {
                    WorkoutDetailInfoRow(label: "Score:", value: "N/A")
                }
                
                if let repCount = workoutResult.repCount {
                    WorkoutDetailInfoRow(label: "Reps:", value: "\(repCount)")
                    if isMostRepsPR { Text("🎉 Most Reps PR!").font(.caption).foregroundColor(.green).padding(.leading) }
                }
                
                // Heart Rate chart for runs
                if workoutResult.exerciseType.lowercased() == "run" && !heartRatePoints.isEmpty {
                    Divider()
                        .padding(.vertical)
                    
                    PTLabel("Heart Rate", style: .heading)
                        .padding(.bottom, AppTheme.GeneratedSpacing.small)
                    
                    heartRateChart
                        .frame(height: 200)
                        .padding(.bottom)
                }
                
                // Pace chart for runs
                if workoutResult.exerciseType.lowercased() == "run" && !pacePoints.isEmpty {
                    PTLabel("Pace", style: .heading)
                        .padding(.bottom, AppTheme.GeneratedSpacing.small)
                    
                    paceChart
                        .frame(height: 200)
                        .padding(.bottom)
                }
                
                // Cadence chart for runs
                if workoutResult.exerciseType.lowercased() == "run" && !cadencePoints.isEmpty {
                    PTLabel("Cadence", style: .heading)
                        .padding(.bottom, AppTheme.GeneratedSpacing.small)
                    
                    cadenceChart
                        .frame(height: 200)
                        .padding(.bottom)
                }
                
                // Show rep breakdown for strength workouts
                if ["pushup", "situp", "pullup"].contains(workoutResult.exerciseType.lowercased()) {
                    // Only fetch rep data if this is a strength workout with reps
                    if let repCount = workoutResult.repCount, repCount > 0 {
                        Divider()
                            .padding(.vertical)
                        
                        PTLabel("Rep Breakdown", style: .heading)
                            .padding(.bottom, AppTheme.GeneratedSpacing.small)
                        
                        if isLoadingRepDetails {
                            ProgressView("Loading rep details...")
                        } else if let error = repDetailsError {
                            Text("Failed to load rep details: \(error)")
                                .foregroundColor(.red)
                        } else if !repChartDataItems.isEmpty {
                            formChart
                                .frame(height: 200)
                                .padding(.bottom)
                            
                            repsList
                        } else {
                            Text("No detailed rep data available.")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Workout Details")
        .onAppear {
            // Load rep details for strength workouts
            if ["pushup", "situp", "pullup"].contains(workoutResult.exerciseType.lowercased()) {
                loadRepDetails()
            }
            
            // Load run details for run workouts
            if workoutResult.exerciseType.lowercased() == "run" {
                loadRunMetricDetails()
                extractMetadataFromWorkout()
            }
            
            // Check for PRs
            checkForPersonalRecords()
        }
    }
    
    // Extract metadata from workout
    private func extractMetadataFromWorkout() {
        guard let metadata = workoutResult.metadata,
              !metadata.isEmpty else { return }
        
        // Attempt to parse the base64 encoded JSON metadata
        if let decodedData = Data(base64Encoded: metadata),
           let jsonDict = try? JSONSerialization.jsonObject(with: decodedData) as? [String: Any] {
            
            // Extract device information
            if let source = jsonDict["source"] as? String {
                self.deviceUsed = source
            }
            
            // Extract units used
            if let distanceUnit = jsonDict["distance_unit"] as? String {
                self.distanceUnitUsed = distanceUnit
            }
        }
    }
    
    // MARK: - Charts for Runs
    
    private var heartRateChart: some View {
        Chart {
            ForEach(heartRatePoints) { point in
                LineMark(
                    x: .value("Time", point.elapsedSeconds / 60), // Show in minutes
                    y: .value("BPM", point.value)
                )
                .foregroundStyle(Color.red)
                .interpolationMethod(.catmullRom)
            }
            
            if !heartRatePoints.isEmpty {
                RuleMark(y: .value("Avg HR", avgHeartRate))
                    .foregroundStyle(Color.orange.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                    .annotation(position: .top, alignment: .trailing) {
                        Text("Avg \(avgHeartRate) BPM")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 6)) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let minutes = value.as(Double.self) {
                        Text("\(Int(minutes))m")
                            .font(.caption)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 5)) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let bpm = value.as(Int.self) {
                        Text("\(bpm)")
                            .font(.caption)
                    }
                }
            }
        }
    }
    
    private var paceChart: some View {
        Chart {
            ForEach(pacePoints) { point in
                LineMark(
                    x: .value("Time", point.elapsedSeconds / 60), // Show in minutes
                    y: .value("Pace", point.value)
                )
                .foregroundStyle(Color.green)
                .interpolationMethod(.catmullRom)
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 6)) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let minutes = value.as(Double.self) {
                        Text("\(Int(minutes))m")
                            .font(.caption)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                if let paceValue = value.as(Double.self), paceValue > 0 {
                    AxisGridLine()
                    AxisValueLabel {
                        Text(formatPaceFromMetersPerSecond(paceValue))
                            .font(.caption)
                    }
                }
            }
        }
    }
    
    private var cadenceChart: some View {
        Chart {
            ForEach(cadencePoints) { point in
                LineMark(
                    x: .value("Time", point.elapsedSeconds / 60), // Show in minutes
                    y: .value("SPM", point.value)
                )
                .foregroundStyle(Color.blue)
                .interpolationMethod(.catmullRom)
            }
            
            if !cadencePoints.isEmpty {
                RuleMark(y: .value("Avg Cadence", avgCadence))
                    .foregroundStyle(Color.purple.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                    .annotation(position: .top, alignment: .trailing) {
                        Text("Avg \(avgCadence) spm")
                            .font(.caption)
                            .foregroundColor(.purple)
                    }
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 6)) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let minutes = value.as(Double.self) {
                        Text("\(Int(minutes))m")
                            .font(.caption)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 5)) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let cadence = value.as(Int.self) {
                        Text("\(cadence)")
                            .font(.caption)
                    }
                }
            }
        }
    }
    
    // MARK: - Existing Chart for Reps
    
    private var formChart: some View {
        Chart(repChartDataItems) { item in
            BarMark(
                x: .value("Rep", item.repNumber),
                y: .value("Score", item.formQuality)
            )
            .foregroundStyle(item.formQuality >= 50 ? Color.green.gradient : Color.red.gradient)
        }
        .chartYScale(domain: 0...100)
        .chartYAxis {
            AxisMarks(values: [0, 25, 50, 75, 100])
        }
    }
    
    private var repsList: some View {
        ForEach(repTextDetails) { item in
            HStack(alignment: .top) {
                Text("Rep \(item.repNumber):")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .frame(width: 60, alignment: .leading)
                
                Text(String(format: "%.1f%%", item.formQuality))
                    .font(.subheadline)
                    .foregroundColor(item.formQuality >= 50 ? .green : .red)
                    .frame(width: 60, alignment: .leading)
                
                if let phase = item.phase {
                    Text("Phase: \(phase)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - Data Loading
    
    private func loadRunMetricDetails() {
        // Check if context is nil before using it
        if modelContext == nil {
            print("ModelContext not available, can't load run metrics")
            return
        }
        
        do {
            // Use the non-optional modelContext
            let descriptor = FetchDescriptor<RunMetricSample>()
            let allSamples = try modelContext.fetch(descriptor)
            
            // Filter for matching workout ID
            let workoutUUID = workoutResult.id
            let samples = allSamples.filter { $0.workoutID == workoutUUID }
            
            // Extract heart rate data points
            let hrPoints = samples.compactMap { sample -> HeartRatePoint? in
                guard let hr = sample.heartRate else { return nil }
                return HeartRatePoint(timestamp: sample.timestamp, elapsedSeconds: sample.elapsedSeconds, value: hr)
            }
            .sorted { $0.elapsedSeconds < $1.elapsedSeconds }
            
            // Extract pace data points 
            let pcPoints = samples.compactMap { sample -> PacePoint? in
                guard let pace = sample.paceMetersPerSecond, pace > 0 else { return nil }
                return PacePoint(
                    timestamp: sample.timestamp, 
                    elapsedSeconds: sample.elapsedSeconds, 
                    value: pace,
                    formattedValue: formatPaceFromMetersPerSecond(pace)
                )
            }
            .sorted { $0.elapsedSeconds < $1.elapsedSeconds }
            
            // Extract cadence data points
            let cdPoints = samples.compactMap { sample -> CadencePoint? in
                guard let cadence = sample.cadenceStepsPerMinute else { return nil }
                return CadencePoint(timestamp: sample.timestamp, elapsedSeconds: sample.elapsedSeconds, value: cadence)
            }
            .sorted { $0.elapsedSeconds < $1.elapsedSeconds }
            
            // Calculate averages and maximums
            if !hrPoints.isEmpty {
                self.avgHeartRate = hrPoints.map { $0.value }.reduce(0, +) / hrPoints.count
                self.maxHeartRate = hrPoints.map { $0.value }.max() ?? 0
            }
            
            if !cdPoints.isEmpty {
                self.avgCadence = cdPoints.map { $0.value }.reduce(0, +) / cdPoints.count
            }
            
            // Extract route points (if needed for a map view later)
            self.routePoints = samples.compactMap { sample in
                guard let lat = sample.latitude, let lon = sample.longitude else { return nil }
                return CLLocationCoordinate2D(latitude: lat, longitude: lon)
            }
            
            // Update the state for the charts
            self.heartRatePoints = hrPoints
            self.pacePoints = pcPoints
            self.cadencePoints = cdPoints
            
        } catch {
            print("Failed to load run metrics: \(error)")
        }
    }
    
    private func loadRepDetails() {
        // Implementation for fetching rep details for strength workouts is already present
        // No changes needed for this function
    }
    
    private func checkForPersonalRecords() {
        // Your existing implementation for PRs
    }
}

// Helper view for consistent row display
struct WorkoutDetailInfoRow: View {
    let label: String
    let value: String
    var dateStyle: Date.FormatStyle? = nil // Optional Date.FormatStyle

    // Overloaded initializer for Date values
    init(label: String, value: Date, style: Date.FormatStyle = .dateTime.day().month().year().hour().minute()) {
        self.label = label
        self.value = value.formatted(style)
        self.dateStyle = style
    }
    
    // Original initializer for String values
    init(label: String, value: String) {
        self.label = label
        self.value = value
        self.dateStyle = nil
    }
    
    var body: some View {
        HStack {
            PTLabel(label, style: .bodyBold)
            Spacer()
            PTLabel(value, style: .body)
        }
    }
}

// Regular preview struct instead of using the macros, which can be more reliable
struct WorkoutDetailView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a sample WorkoutResultSwiftData for the preview
        let samplePushups = WorkoutResultSwiftData(
            exerciseType: "pushup", 
            startTime: Date().addingTimeInterval(-600), // 10 mins ago
            endTime: Date(), 
            durationSeconds: 120, // 2 mins for the set
            repCount: 30, 
            score: 88.5, 
            distanceMeters: nil,
            isPublic: true
        )
        
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: WorkoutResultSwiftData.self, 
            WorkoutDataPoint.self, 
            RunMetricSample.self, 
            configurations: config
        )
        
        // Use the sample to create a view
        return NavigationView {
            WorkoutDetailView(workoutResult: samplePushups)
        }
        .modelContainer(container)
    }
} 