import SwiftUI
import AVFoundation
import Vision
import UIKit
import Combine
import MediaPipeTasksVision

struct CameraView: UIViewControllerRepresentable {
    @ObservedObject var exerciseViewModel: ExerciseViewModel
    var exerciseType: ExerciseType
    
    class Coordinator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
        var parent: CameraView
        private var lastPoseDetectionTime = Date()
        
        init(parent: CameraView) {
            self.parent = parent
        }
        
        func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            // Throttle pose detection to 15 fps to save processing power
            let currentTime = Date()
            if currentTime.timeIntervalSince(lastPoseDetectionTime) < 1.0/15.0 {
                return
            }
            
            lastPoseDetectionTime = currentTime
            
            // Detect pose
            guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
            
            // Convert CMSampleBuffer to UIImage for display with overlay
            let ciImage = CIImage(cvPixelBuffer: imageBuffer)
            let context = CIContext()
            guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }
            let uiImage = UIImage(cgImage: cgImage)
            
            parent.exerciseViewModel.detectPoseInFrame(sampleBuffer: sampleBuffer, orientation: .right, exerciseType: parent.exerciseType, originalImage: uiImage)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }
    
    func makeUIViewController(context: Context) -> CameraViewController {
        let viewController = CameraViewController()
        viewController.delegate = context.coordinator
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
        // Update if needed
    }
}

class CameraViewController: UIViewController {
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private let videoDataOutputQueue = DispatchQueue(label: "VideoDataOutput", qos: .userInitiated)
    
    var delegate: AVCaptureVideoDataOutputSampleBufferDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startCamera()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopCamera()
    }
    
    private func setupCamera() {
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = .high
        
        // Configure camera input
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            print("Failed to get camera device")
            return
        }
        
        do {
            let cameraInput = try AVCaptureDeviceInput(device: camera)
            if captureSession.canAddInput(cameraInput) {
                captureSession.addInput(cameraInput)
            } else {
                print("Could not add camera input to session")
                return
            }
        } catch {
            print("Error setting up camera input: \(error.localizedDescription)")
            return
        }
        
        // Configure preview layer
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.connection?.videoOrientation = .portrait
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
        
        // Configure video output
        videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        
        if captureSession.canAddOutput(videoDataOutput) {
            captureSession.addOutput(videoDataOutput)
            
            // Connect video output to delegate for processing
            videoDataOutput.setSampleBufferDelegate(delegate, queue: videoDataOutputQueue)
            
            // Set the connection properties
            if let connection = videoDataOutput.connection(with: .video) {
                connection.videoOrientation = .portrait
                connection.isVideoMirrored = true // Mirror front camera
            }
        }
        
        self.captureSession = captureSession
        self.previewLayer = previewLayer
    }
    
    private func startCamera() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.startRunning()
        }
    }
    
    private func stopCamera() {
        captureSession?.stopRunning()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }
}

// Represents the overall state of the workout session
enum SessionState {
    case idle
    case running
    case paused
    case stopped
    case saving // Added state for saving process
}

class ExerciseViewModel: ObservableObject {
    @Published var isExerciseActive = false
    @Published var overlayImage: UIImage?
    @Published var exerciseState: ExerciseState = ExerciseState()
    @Published var countdown: Int = 3
    @Published var isSaving = false
    @Published var saveError: String? = nil
    @Published var savedExerciseResult: UserExercise? = nil
    @Published var isCameraAvailable: Bool = false
    @Published var errorMessage: String? = nil
    @Published var repCount: Int = 0
    @Published var feedback: [String] = []
    @Published var formScore: Double = 100.0
    @Published var currentExerciseState: ExerciseState = .idle // State from the analyzer
    @Published var sessionState: SessionState = .idle // Overall session control state
    @Published var saveSuccess: Bool = false
    
    private let workoutRepository: WorkoutRepositoryProtocol
    private let poseDetectionService = PoseDetectionService()
    private var countdownTimer: Timer?
    private var exerciseAnalyzer: ExerciseAnalyzer?
    private let exerciseType: ExerciseType
    private var workoutStartTime: Date?
    private var mediaPipeService = MediaPipePoseDetectionService()
    
    init(exerciseType: ExerciseType, workoutRepository: WorkoutRepositoryProtocol = WorkoutRepository()) {
        self.exerciseType = exerciseType
        self.workoutRepository = workoutRepository
        setupCamera()
        setupAnalyzer(for: exerciseType)
    }
    
    private func setupCamera() {
        CameraManager.shared.checkCameraAuthorizationStatus { [weak self] authorized in
            DispatchQueue.main.async {
                self?.isCameraAvailable = authorized
                if !authorized {
                    self?.errorMessage = "Camera access denied. Please enable it in Settings."
                }
            }
        }
    }
    
    private func setupAnalyzer(for type: ExerciseType) {
        switch type {
        case .pushup:
            exerciseAnalyzer = PushupAnalyzer()
        case .situp:
            exerciseAnalyzer = SitupAnalyzer()
        case .pullup:
            exerciseAnalyzer = PullupAnalyzer()
        case .run:
            exerciseAnalyzer = nil // Running doesn't use pose analysis
        }
        resetAnalysisState()
    }
    
    private func resetAnalysisState() {
        repCount = 0
        feedback = []
        formScore = 100.0
        currentExerciseState = .idle
        exerciseAnalyzer?.reset()
    }
    
    func startSession() {
        guard exerciseAnalyzer != nil else {
            errorMessage = "No analyzer configured for this exercise."
            return
        }
        if sessionState == .idle || sessionState == .stopped || sessionState == .paused {
            print("Starting Session for \(exerciseType)")
            resetAnalysisState()
            exerciseAnalyzer?.start()
            workoutStartTime = Date()
            sessionState = .running
            isExerciseActive = true
            saveSuccess = false
            saveError = nil
        }
    }
    
    func pauseSession() {
        if sessionState == .running {
            print("Pausing Session")
            sessionState = .paused
            isExerciseActive = false
        }
    }
    
    func resumeSession() {
        if sessionState == .paused {
            print("Resuming Session")
            sessionState = .running
            isExerciseActive = true
        }
    }
    
    func stopSession() {
        if sessionState == .running || sessionState == .paused {
            print("Stopping Session")
            sessionState = .stopped
            isExerciseActive = false
            exerciseAnalyzer?.stop()
            saveWorkoutSession()
        }
    }
    
    private func saveWorkoutSession() {
        guard let startTime = workoutStartTime, exerciseType != .run else {
            print("Cannot save workout: Invalid start time or exercise type.")
            return
        }
        
        let duration = Date().timeIntervalSince(startTime)
        let finalRepCount = self.repCount
        let finalFormScore = self.formScore
        
        print("Attempting to save workout: \(exerciseType), Reps: \(finalRepCount), Duration: \(duration), Score: \(finalFormScore)")
        
        guard let exerciseId = exerciseType.id else {
            errorMessage = "Could not find backend ID for exercise type."
            saveError = "Internal error: Missing exercise ID."
            return
        }
        
        let request = SaveWorkoutRequest(
            exerciseId: exerciseId,
            startTime: startTime,
            endTime: Date(),
            reps: finalRepCount,
            durationSeconds: Int(duration),
            formScore: finalFormScore,
            grade: "PENDING" // Or calculate grade if needed
        )
        
        DispatchQueue.main.async {
            self.isSaving = true
            self.saveSuccess = false
            self.saveError = nil
        }
        
        Task {
            do {
                let savedWorkout = try await workoutRepository.saveWorkout(request: request)
                print("Workout saved successfully: \(savedWorkout)")
                DispatchQueue.main.async {
                    self.isSaving = false
                    self.saveSuccess = true
                }
            } catch {
                print("Error saving workout: \(error)")
                DispatchQueue.main.async {
                    self.isSaving = false
                    self.saveError = "Failed to save workout: \(error.localizedDescription)"
                    self.saveSuccess = false
                }
            }
        }
    }
    
    func detectPoseInFrame(sampleBuffer: CMSampleBuffer, orientation: CGImagePropertyOrientation, exerciseType: ExerciseType, originalImage: UIImage) {
        guard isExerciseActive else { return }
        
        poseDetectionService.detectPoseInFrame(sampleBuffer: sampleBuffer, orientation: orientation) { [weak self] pose in
            guard let self = self, let pose = pose else { return }
            
            // Detect exercise based on type
            DispatchQueue.main.async {
                switch exerciseType {
                case .pushup:
                    self.exerciseState = self.poseDetectionService.detectPushup(pose: pose)
                case .situp:
                    self.exerciseState = self.poseDetectionService.detectSitup(pose: pose)
                case .pullup:
                    self.exerciseState = self.poseDetectionService.detectPullup(pose: pose)
                case .run:
                    // Run is tracked via Bluetooth, not pose
                    break
                }
                
                // Draw pose overlay on the image
                self.overlayImage = self.poseDetectionService.drawPoseOverlay(on: originalImage, pose: pose)
            }
        }
    }
    
    func handleFrame(sampleBuffer: CMSampleBuffer, orientation: CGImagePropertyOrientation, originalImage: UIImage) {
        detectPoseInFrame(sampleBuffer: sampleBuffer, orientation: orientation, exerciseType: self.exerciseType, originalImage: originalImage)
    }
}

// Exercise View Container that manages state and UI
struct ExerciseViewContainer: View {
    // Initialize the ViewModel specific to the exercise passed in
    @StateObject private var viewModel: ExerciseViewModel
    @EnvironmentObject var authManager: AuthManager
    let exercise: Exercise
    
    // State for showing completion/error messages
    @State private var showingResultAlert = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""

    init(exercise: Exercise) {
        self.exercise = exercise
        // Initialize the ViewModel, passing the exercise type.
        // It will use the default WorkoutRepository() unless injected elsewhere.
        _viewModel = StateObject(wrappedValue: ExerciseViewModel(exerciseType: exercise.type))
    }
    
    var body: some View {
        ZStack {
            // Camera view with overlay (Image is already handled by ViewModel)
            if let overlay = viewModel.overlayImage {
                Image(uiImage: overlay)
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)
            } else {
                // Show CameraView or a placeholder if overlay isn't ready
                CameraView(exerciseViewModel: viewModel, exerciseType: exercise.type)
                    .edgesIgnoringSafeArea(.all)
            }

            // Dim overlay when paused or saving
            if viewModel.sessionState == .paused || viewModel.sessionState == .saving {
                Color.black.opacity(0.5).edgesIgnoringSafeArea(.all)
            }
            
            VStack {
                // Top Info Bar (Exercise Name/Description)
                exerciseInfoView
                
                Spacer()
                
                // Analysis Results Overlay (Reps, Score, Feedback)
                analysisOverlayView
                
                // Saving Indicator / Error Message
                saveStatusView
                
                // Control Buttons
                controlButtonsView
            }
            .padding()
        }
        .navigationTitle(exercise.name) // Use exercise name for title
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $showingResultAlert) {
            Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .onChange(of: viewModel.saveSuccess) { success in
            if success {
                alertTitle = "Workout Saved"
                alertMessage = "Your \(exercise.name) session (\(viewModel.repCount) reps, Score: \(String(format: "%.0f", viewModel.formScore))) was saved successfully."
                showingResultAlert = true
                // Optionally navigate back after showing success
            }
        }
        .onChange(of: viewModel.saveError) { error in
            if let errorMsg = error {
                alertTitle = "Save Failed"
                alertMessage = errorMsg
                showingResultAlert = true
            }
        }
        // Add error handling for general errors
         .onChange(of: viewModel.errorMessage) { error in
             if let errorMsg = error {
                 alertTitle = "Error"
                 alertMessage = errorMsg
                 showingResultAlert = true
             }
         }
    }

    // MARK: - Subviews
    
    private var exerciseInfoView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(exercise.name)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            Text(exercise.description)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.black.opacity(0.6))
        .cornerRadius(10)
    }

    private var analysisOverlayView: some View {
        VStack(spacing: 15) {
            // Show analysis only when running or paused
            if viewModel.sessionState == .running || viewModel.sessionState == .paused {
                HStack(spacing: 30) {
                    // Rep Count
                    VStack {
                        Text("Reps")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        Text("\(viewModel.repCount)")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.white)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                    }
                    
                    // Form Score
                    VStack {
                        Text("Form")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        Text(String(format: "%.0f", viewModel.formScore))
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(formScoreColor(viewModel.formScore))
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                    }
                }
                .padding(.vertical)
                .padding(.horizontal, 25)
                .background(Color.black.opacity(0.7))
                .cornerRadius(15)

                // Feedback Text (Show latest feedback)
                if let latestFeedback = viewModel.feedback.last {
                     Text(latestFeedback)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(10)
                        .background(feedbackColor(for: viewModel.currentExerciseState).opacity(0.8))
                        .cornerRadius(8)
                        .multilineTextAlignment(.center)
                        .transition(.opacity.animation(.easeInOut))
                 }
            }
            
            // Show paused indicator
            if viewModel.sessionState == .paused {
                 Text("Paused")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.yellow)
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)
            }
        }
        .padding(.bottom, 10)
    }
    
    private var saveStatusView: some View {
        Group {
            if viewModel.isSaving {
                ProgressView("Saving...")
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            // Save errors are handled by the .onChange alert
        }
    }
    
    private var controlButtonsView: some View {
         HStack(spacing: 20) {
            // Show Start Button when Idle or Stopped
            if viewModel.sessionState == .idle || viewModel.sessionState == .stopped {
                Button { viewModel.startSession() } label: {
                    Label("Start", systemImage: "play.fill")
                }
                .buttonStyle(PTButtonStyle(style: .primary, size: .large))
                .disabled(viewModel.isSaving)
            }
            
            // Show Pause/Resume/Stop when Running or Paused
            if viewModel.sessionState == .running || viewModel.sessionState == .paused {
                // Pause / Resume Button
                Button { 
                    if viewModel.sessionState == .running { viewModel.pauseSession() }
                    else { viewModel.resumeSession() }
                } label: {
                    Label(viewModel.sessionState == .running ? "Pause" : "Resume", 
                          systemImage: viewModel.sessionState == .running ? "pause.fill" : "play.fill")
                }
                .buttonStyle(PTButtonStyle(style: .warning, size: .large))
                .disabled(viewModel.isSaving)
                
                // Stop Button (Completes and Saves)
                Button { viewModel.stopSession() } label: {
                    Label("Stop", systemImage: "stop.fill")
                }
                .buttonStyle(PTButtonStyle(style: .danger, size: .large))
                .disabled(viewModel.isSaving)
            }
         }
         .frame(height: 50) // Give buttons consistent height
    }

    // MARK: - Helper Functions

    private func formScoreColor(_ score: Double) -> Color {
        switch score {
        case 90...100: return .green
        case 75..<90: return .yellow
        case 60..<75: return .orange
        default: return .red
        }
    }
    
    private func feedbackColor(for state: ExerciseState) -> Color {
        switch state {
        case .invalid: return .red
        case .down, .up, .starting: return .blue // Neutral/instructional
        default: return .gray // Idle/finished
        }
    }
}

// Preview Provider Update
struct CameraView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a dummy exercise for the preview
        let previewExercise = Exercise(
            id: 1,
            name: "Push-ups",
            description: "Test description for push-ups.",
            type: .pushup,
            imageUrl: nil
        )

        // Create the container view with the exercise
        // The ViewModel inside will use the default repository
        let container = ExerciseViewContainer(exercise: previewExercise)
        
        // Simulate a state for the preview (e.g., running)
        container.viewModel.sessionState = .running
        container.viewModel.repCount = 5
        container.viewModel.formScore = 88.0
        container.viewModel.feedback = ["Keep body straight!"]
        container.viewModel.currentExerciseState = .down

        return container
            .environmentObject(AuthManager()) // Provide dummy auth manager
    }
}

// Helper for Button Styling (Assuming PTButtonStyle exists)
struct PTButtonStyle: ButtonStyle {
    enum Style { case primary, secondary, danger, warning, success }
    enum Size { case normal, large }
    
    let style: Style
    let size: Size
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(size == .large ? .headline : .body)
            .padding(size == .large ? 15 : 10)
            .frame(minWidth: size == .large ? 120 : 80)
            .background(backgroundColor(configuration.isPressed))
            .foregroundColor(.white)
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
    
    private func backgroundColor(_ isPressed: Bool) -> Color {
        let baseColor: Color
        switch style {
        case .primary: baseColor = .blue
        case .secondary: baseColor = .gray
        case .danger: baseColor = .red
        case .warning: baseColor = .orange
        case .success: baseColor = .green
        }
        return baseColor.opacity(isPressed ? 0.8 : 1.0)
    }
}