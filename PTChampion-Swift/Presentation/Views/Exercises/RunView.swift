import SwiftUI
import Combine

struct RunView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel = RunViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            if viewModel.isLoading {
                ProgressView("Loading exercise...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground).edgesIgnoringSafeArea(.all))
            } else if let exercise = viewModel.exercise {
                RunExerciseView(exercise: exercise, viewModel: viewModel)
                    .environmentObject(authManager)
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)
                    
                    Text("Exercise not found")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Unable to load running exercise data.")
                        .foregroundColor(.secondary)
                    
                    Button("Go Back") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .ptStyle(.primary)
                    .padding(.top, 20)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground).edgesIgnoringSafeArea(.all))
            }
        }
        .navigationBarBackButtonHidden(viewModel.isRunning)
        .navigationBarItems(
            leading: Button(action: {
                if viewModel.isRunning {
                    viewModel.showCancelConfirmation = true
                } else {
                    presentationMode.wrappedValue.dismiss()
                }
            }) {
                if viewModel.isRunning {
                    Text("Cancel Run")
                        .foregroundColor(.red)
                } else {
                    HStack {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                        Text("Back")
                    }
                }
            }
        )
        .onAppear {
            viewModel.loadExercise()
            viewModel.startBluetoothScan()
        }
        .onDisappear {
            if !viewModel.hasCompletedRun {
                viewModel.cancelRun()
            }
        }
        .alert(isPresented: $viewModel.showCancelConfirmation) {
            Alert(
                title: Text("Cancel Run"),
                message: Text("Are you sure you want to cancel your run? Your progress will be lost."),
                primaryButton: .destructive(Text("Cancel Run")) {
                    viewModel.cancelRun()
                    presentationMode.wrappedValue.dismiss()
                },
                secondaryButton: .cancel()
            )
        }
    }
}

struct RunExerciseView: View {
    let exercise: Exercise
    @ObservedObject var viewModel: RunViewModel
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text(exercise.name)
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(exercise.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.systemBackground))
            
            // Main content depends on the current state
            if !viewModel.isRunning && !viewModel.isCompleted {
                prepareForRunView
            } else if viewModel.isRunning && !viewModel.isCompleted {
                activeRunView
            } else if viewModel.isCompleted {
                runCompletionView
            }
        }
        .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
        .alert("Error Saving Run", isPresented: .constant(viewModel.saveError != nil), actions: {
            Button("OK") { viewModel.saveError = nil }
        }, message: {
            Text(viewModel.saveError ?? "An unknown error occurred.")
        })
    }
    
    // View shown before starting the run
    private var prepareForRunView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Instructions
                VStack(alignment: .leading, spacing: 16) {
                    Text("Prepare for your 2-Mile Run")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        instructionRow(number: "1", text: "Connect a heart rate monitor or running device for more accurate tracking.")
                        
                        instructionRow(number: "2", text: "Find a flat, measured 2-mile course or use a treadmill.")
                        
                        instructionRow(number: "3", text: "Warm up properly with light jogging and stretching.")
                        
                        instructionRow(number: "4", text: "Start the timer when you're ready to begin.")
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                
                // Connected devices section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Connected Devices")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    if viewModel.connectedDevices.isEmpty {
                        HStack {
                            Image(systemName: "exclamationmark.circle")
                                .foregroundColor(.orange)
                            
                            Text("No devices connected")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                    } else {
                        ForEach(viewModel.connectedDevices, id: \.id) { device in
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                
                                VStack(alignment: .leading) {
                                    Text(device.name)
                                        .font(.headline)
                                    
                                    if device.metrics.heartRate != nil {
                                        Text("Heart Rate Monitor")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    } else if device.metrics.speed != nil {
                                        Text("Running Sensor")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    viewModel.disconnectDevice(device)
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(8)
                        }
                    }
                    
                    Button(action: {
                        viewModel.showDeviceSelectionView.toggle()
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Connect Device")
                        }
                    }
                    .ptStyle(.outline)
                    .padding(.top, 8)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                
                // Start button
                Button(action: {
                    viewModel.startRun()
                }) {
                    Text("Start 2-Mile Run")
                        .font(.headline)
                }
                .ptStyle(.primary)
                .padding(.vertical, 12)
            }
            .padding()
        }
        .sheet(isPresented: $viewModel.showDeviceSelectionView) {
            DeviceSelectionView(viewModel: viewModel)
        }
    }
    
    // View shown during an active run
    private var activeRunView: some View {
        VStack(spacing: 16) {
            // Timer & distance display
            VStack {
                HStack(spacing: 50) {
                    // Time elapsed
                    VStack {
                        Text("TIME")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        
                        Text(viewModel.formattedTime)
                            .font(.system(size: 44, weight: .bold, design: .monospaced))
                            .foregroundColor(.primary)
                    }
                    
                    // Distance covered
                    VStack {
                        Text("DISTANCE")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        
                        Text(viewModel.formattedDistance)
                            .font(.system(size: 44, weight: .bold, design: .monospaced))
                            .foregroundColor(.primary)
                    }
                }
                .padding(.vertical, 30)
                .padding(.horizontal)
                .frame(maxWidth: .infinity)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
            }
            .padding()
            
            // Performance metrics
            VStack(spacing: 16) {
                Text("Performance Metrics")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack(spacing: 20) {
                    // Heart rate
                    metricCard(
                        title: "HEART RATE",
                        value: viewModel.formattedHeartRate,
                        icon: "heart.fill",
                        color: .red
                    )
                    
                    // Current pace
                    metricCard(
                        title: "CURRENT PACE",
                        value: viewModel.formattedPace,
                        icon: "speedometer",
                        color: .blue
                    )
                }
                
                HStack(spacing: 20) {
                    // Estimated finish
                    metricCard(
                        title: "ESTIMATED FINISH",
                        value: viewModel.formattedEstimatedFinish,
                        icon: "flag.fill",
                        color: .green
                    )
                    
                    // Calories
                    metricCard(
                        title: "CALORIES",
                        value: viewModel.formattedCalories,
                        icon: "flame.fill",
                        color: .orange
                    )
                }
            }
            .padding()
            
            // Control buttons
            HStack(spacing: 20) {
                // Pause/Resume button
                Button(action: {
                    viewModel.togglePauseRun()
                }) {
                    HStack {
                        Image(systemName: viewModel.isPaused ? "play.fill" : "pause.fill")
                        Text(viewModel.isPaused ? "Resume" : "Pause")
                    }
                }
                .ptStyle(viewModel.isPaused ? .primary : .secondary)
                
                // Complete button
                Button(action: {
                    viewModel.completeRun()
                }) {
                    HStack {
                        Image(systemName: "flag.checkered")
                        Text("Complete")
                    }
                }
                .ptStyle(.success)
            }
            .padding()
            
            Spacer()
        }
    }
    
    // View shown after completing the run
    private var runCompletionView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Performance summary
                VStack(spacing: 16) {
                    Text("Run Completed!")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    HStack(spacing: 40) {
                        VStack {
                            Text("Time")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text(viewModel.formattedTime)
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        
                        VStack {
                            Text("Distance")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text(viewModel.formattedDistance)
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        
                        VStack {
                            Text("Score")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text("\(viewModel.formattedGrade)/100")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(scoreColor(viewModel.formattedGrade))
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                
                // Detailed stats
                VStack(alignment: .leading, spacing: 16) {
                    Text("Run Statistics")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 16) {
                            statRow(title: "Average Pace", value: viewModel.formattedPace)
                            statRow(title: "Average HR", value: viewModel.formattedHeartRate)
                            statRow(title: "Calories", value: viewModel.formattedCalories)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        VStack(alignment: .leading, spacing: 16) {
                            statRow(title: "Grade", value: viewModel.formattedGrade)
                            statRow(title: "Time of Day", value: viewModel.formattedTimeOfDay)
                            statRow(title: "Weather", value: "Indoor Run")
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                
                // Save button
                Button(action: {
                    if let userId = authManager.currentUser?.id, let exerciseId = viewModel.exercise?.id {
                        viewModel.saveRunResults(userId: userId, exerciseId: exerciseId) { success in
                            if success {
                                presentationMode.wrappedValue.dismiss()
                            }
                        }
                    }
                }) {
                    Text("Save Results")
                        .font(.headline)
                }
                .ptStyle(.primary, isLoading: viewModel.isSaving)
                .padding(.vertical, 12)
                
                // Discard button
                Button(action: {
                    viewModel.showDiscardConfirmation = true
                }) {
                    Text("Discard Results")
                        .font(.subheadline)
                }
                .ptStyle(.outline)
                .padding(.bottom, 12)
            }
            .padding()
            .alert(isPresented: $viewModel.showDiscardConfirmation) {
                Alert(
                    title: Text("Discard Results"),
                    message: Text("Are you sure you want to discard your run results? This cannot be undone."),
                    primaryButton: .destructive(Text("Discard")) {
                        presentationMode.wrappedValue.dismiss()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
    
    // Helper views
    private func instructionRow(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Text(number)
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(Circle().fill(Color.blue))
            
            Text(text)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
    }
    
    private func metricCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(.primary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .frame(maxWidth: .infinity)
    }
    
    private func statRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
    
    private func scoreColor(_ score: String) -> Color {
        switch score {
        case "Excellent":
            return .green
        case "Good":
            return .blue
        case "Satisfactory":
            return .orange
        case "Marginal":
            return .yellow
        default:
            return .red
        }
    }
}

// Device selection view presented as a sheet
struct DeviceSelectionView: View {
    @ObservedObject var viewModel: RunViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isScanning {
                    VStack {
                        ProgressView()
                            .padding()
                        
                        Text("Scanning for devices...")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.discoveredDevices.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "wifi.exclamationmark")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                            .padding()
                        
                        Text("No devices found")
                            .font(.headline)
                        
                        Text("Make sure your Bluetooth devices are turned on and in pairing mode.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding()
                        
                        Button(action: {
                            viewModel.startBluetoothScan()
                        }) {
                            Text("Scan Again")
                        }
                        .ptStyle(.primary)
                        .padding(.top)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(viewModel.discoveredDevices, id: \.id) { device in
                            Button(action: {
                                viewModel.connectToDevice(device)
                            }) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(device.name)
                                            .font(.headline)
                                        
                                        Text("Signal: \(device.signalStrength)%")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    if device.isConnecting {
                                        ProgressView()
                                    } else if device.isConnected {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                    } else {
                                        Image(systemName: "plus.circle")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                            .disabled(device.isConnecting)
                        }
                    }
                }
            }
            .navigationTitle("Select Device")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button(action: {
                    viewModel.startBluetoothScan()
                }) {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(viewModel.isScanning)
            )
        }
    }
}

// View Model for the Run screen
class RunViewModel: ObservableObject {
    @Published var exercise: Exercise?
    @Published var isLoading = true
    @Published var errorMessage: String?
    
    // Bluetooth related
    @Published var discoveredDevices: [BluetoothDevice] = []
    @Published var connectedDevices: [BluetoothDevice] = []
    @Published var isScanning = false
    @Published var showDeviceSelectionView = false
    
    // Run state
    @Published var isRunning = false
    @Published var isPaused = false
    @Published var isCompleted = false
    @Published var hasCompletedRun = false
    @Published var isSaving = false
    @Published var showCancelConfirmation = false
    @Published var showDiscardConfirmation = false
    
    // Run metrics
    @Published var timeElapsed: TimeInterval = 0
    @Published var distanceInMeters: Double = 0
    @Published var heartRate: Int = 0
    @Published var currentPace: Double = 0 // min/km
    @Published var calories: Int = 0
    @Published var savedExerciseResult: UserExercise? = nil // To store result from API
    
    // Formatted values for display
    var formattedTime: String {
        let minutes = Int(timeElapsed) / 60
        let seconds = Int(timeElapsed) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var formattedDistance: String {
        if distanceInMeters < 1000 {
            return "\(Int(distanceInMeters))m"
        } else {
            let km = distanceInMeters / 1000.0
            return String(format: "%.2fkm", km)
        }
    }
    
    var formattedHeartRate: String {
        return heartRate > 0 ? "\(heartRate) BPM" : "--"
    }
    
    var formattedPace: String {
        if currentPace > 0 {
            let minutes = Int(currentPace)
            let seconds = Int((currentPace - Double(minutes)) * 60)
            return String(format: "%d:%02d /km", minutes, seconds)
        } else {
            return "--:--"
        }
    }
    
    var formattedCalories: String {
        return "\(calories) kcal"
    }
    
    var formattedEstimatedFinish: String {
        guard currentPace > 0 else { return "--:--" }
        
        // 2 miles = 3.22 km
        let totalTimeInMinutes = 3.22 * currentPace
        let remainingDistance = 3220 - distanceInMeters
        let remainingTimeInMinutes = (remainingDistance / 1000.0) * currentPace
        
        let minutes = Int(remainingTimeInMinutes)
        let seconds = Int((remainingTimeInMinutes - Double(minutes)) * 60)
        
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var formattedGrade: String {
        // Removed: Use savedExerciseResult.grade
        // return "\(calculatedGrade)/100 \(gradeToRating(calculatedGrade))"
        return "" // Placeholder, actual implementation needed
    }
    
    var formattedTimeOfDay: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: Date())
    }
    
    // Services
    private let bluetoothManager = BluetoothManager()
    private var timer: Timer?
    private var startTime: Date?
    private var pausedDuration: TimeInterval = 0
    
    // Subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupBluetoothObservers()
    }
    
    // MARK: - Exercise Loading
    
    func loadExercise() {
        isLoading = true
        
        APIClient.shared.getExercises()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            }, receiveValue: { [weak self] exercises in
                if let runExercise = exercises.first(where: { $0.type == .run }) {
                    self?.exercise = runExercise
                }
                self?.isLoading = false
            })
            .store(in: &cancellables)
    }
    
    // MARK: - Bluetooth Management
    
    private func setupBluetoothObservers() {
        bluetoothManager.$discoveredDevices
            .receive(on: DispatchQueue.main)
            .sink { [weak self] devices in
                self?.discoveredDevices = devices
            }
            .store(in: &cancellables)
        
        bluetoothManager.$connectedDevices
            .receive(on: DispatchQueue.main)
            .sink { [weak self] devices in
                self?.connectedDevices = devices
                self?.updateMetricsFromDevices()
            }
            .store(in: &cancellables)
        
        bluetoothManager.$isScanning
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isScanning in
                self?.isScanning = isScanning
            }
            .store(in: &cancellables)
        
        bluetoothManager.$metrics
            .receive(on: DispatchQueue.main)
            .sink { [weak self] metrics in
                self?.updateMetricsFromBluetoothManager(metrics)
            }
            .store(in: &cancellables)
    }
    
    func startBluetoothScan() {
        bluetoothManager.startScanning()
    }
    
    func connectToDevice(_ device: BluetoothDevice) {
        bluetoothManager.connect(to: device)
    }
    
    func disconnectDevice(_ device: BluetoothDevice) {
        bluetoothManager.disconnect(from: device)
    }
    
    private func updateMetricsFromDevices() {
        // This method aggregates data from multiple connected devices
        for device in connectedDevices {
            if let hr = device.metrics.heartRate, hr > 0 {
                heartRate = hr
            }
            
            if let distance = device.metrics.distance, distance > 0 {
                // Only update if device distance is greater than current
                distanceInMeters = max(distanceInMeters, distance)
            }
            
            if let speed = device.metrics.speed, speed > 0 {
                // Convert m/s to min/km
                currentPace = speed > 0 ? (1000 / 60) / speed : 0
            }
        }
        
        // Estimate calories based on time, heart rate, and effort
        if timeElapsed > 0 && heartRate > 0 {
            // Simple calories estimation
            // Typically 1 kcal per kg body weight per km for running
            // Assuming average person (70kg) burns about 70 kcal per km
            let distanceInKm = distanceInMeters / 1000
            calories = Int(distanceInKm * 70)
        }
    }
    
    private func updateMetricsFromBluetoothManager(_ metrics: BluetoothMetrics) {
        if let hr = metrics.heartRate, hr > 0 {
            heartRate = hr
        }
        
        if let distance = metrics.distance, distance > 0 {
            distanceInMeters = distance
        }
        
        if let speed = metrics.speed, speed > 0 {
            // Convert m/s to min/km
            currentPace = speed > 0 ? (1000 / 60) / speed : 0
        }
        
        if let time = metrics.timeElapsed, time > 0 {
            // Only use this if we're not tracking time ourselves
            if !isRunning {
                timeElapsed = time
            }
        }
    }
    
    // MARK: - Run Control
    
    func startRun() {
        isRunning = true
        isPaused = false
        startTime = Date()
        
        // Start tracking time
        startTimer()
        
        // Start tracking from Bluetooth devices
        bluetoothManager.startExerciseTracking()
    }
    
    func togglePauseRun() {
        isPaused.toggle()
        
        if isPaused {
            // Pause timer and tracking
            timer?.invalidate()
            bluetoothManager.pauseExerciseTracking()
        } else {
            // Resume timer and tracking
            startTimer()
            bluetoothManager.resumeExerciseTracking()
        }
    }
    
    func completeRun() {
        isRunning = false
        isCompleted = true
        hasCompletedRun = true
        
        // Stop timer and tracking
        timer?.invalidate()
        bluetoothManager.stopExerciseTracking()
        
        // Removed local grade calculation
        // if timeElapsed > 0 {
        //     calculatedGrade = ExerciseGrader.calculateRunGrade(timeInSeconds: Int(timeElapsed))
        // }
    }
    
    func cancelRun() {
        isRunning = false
        isPaused = false
        isCompleted = false
        hasCompletedRun = false
        
        // Stop timer and tracking
        timer?.invalidate()
        bluetoothManager.stopExerciseTracking()
        
        // Reset metrics
        timeElapsed = 0
        distanceInMeters = 0
        startTime = nil
        pausedDuration = 0
        
        // Clear previous errors
        saveError = nil
        savedExerciseResult = nil
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, !self.isPaused else { return }
            
            self.timeElapsed += 1
            
            // If there's no distance data from devices, simulate distance based on pace
            if self.distanceInMeters == 0 && self.timeElapsed > 0 {
                // Assume a moderate pace of 6 min/km (10 km/h or 2.78 m/s)
                let estimatedDistancePerSecond = 2.78
                self.distanceInMeters += estimatedDistancePerSecond
            }
            
            // Simulate heart rate if none from devices
            if self.heartRate == 0 {
                // Assume moderate running HR of 140-160 bpm
                self.heartRate = 140 + Int.random(in: 0...20)
            }
            
            // Update current pace if there's no bluetooth data
            if self.currentPace == 0 && self.distanceInMeters > 0 && self.timeElapsed > 0 {
                // Calculate pace from time and distance
                let timeInMinutes = self.timeElapsed / 60
                let distanceInKm = self.distanceInMeters / 1000
                if distanceInKm > 0 {
                    self.currentPace = timeInMinutes / distanceInKm
                }
            }
            
            // Update calories
            if self.timeElapsed > 0 {
                // Simplified calorie calculation
                // Assume 10 kcal per minute for a moderate run
                self.calories = Int(self.timeElapsed / 60 * 10)
            }
        }
    }
    
    // MARK: - Results Management
    
    func saveRunResults(userId: Int, exerciseId: Int, completion: @escaping (Bool) -> Void) {
        guard !isSaving else { return } // Prevent double saves
        isSaving = true
        saveError = nil // Clear previous errors
        savedExerciseResult = nil // Clear previous result
        
        // Assume 2 miles is complete even if distance tracking shows less
        // This is because the API expects a completed exercise
        let exerciseData = CreateUserExerciseRequest(
            exerciseId: exerciseId,
            repetitions: nil,
            formScore: nil,
            timeInSeconds: Int(timeElapsed),
            completed: true,
            metadata: [
                "distance": "\(distanceInMeters)",
                "heartRate": "\(heartRate)",
                "pace": "\(currentPace)",
                "calories": "\(calories)"
            ]
        )
        
        APIClient.shared.createUserExercise(userExercise: exerciseData)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completionResult in
                self?.isSaving = false
                
                if case .failure(let error) = completionResult {
                    print("Error saving run: \(error.localizedDescription)")
                    self?.saveError = error.localizedDescription // Set error for alert
                    completion(false)
                }
            }, receiveValue: { savedExercise in
                self?.savedExerciseResult = savedExercise // Store the full result
                completion(true)
            })
            .store(in: &cancellables)
    }
    
    // MARK: - Helpers
    
    // Removed gradeToRating, can be added back if needed using savedExerciseResult.grade
}

// Preview
struct RunView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            RunView()
                .environmentObject(AuthManager())
        }
    }
}