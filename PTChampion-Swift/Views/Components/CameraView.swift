import SwiftUI
import AVFoundation
import Vision
import UIKit
import Combine

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

// View Model for Camera and Exercise Processing
class ExerciseViewModel: ObservableObject {
    @Published var isExerciseActive = false
    @Published var overlayImage: UIImage?
    @Published var exerciseState: ExerciseState = ExerciseState()
    @Published var countdown: Int = 3
    @Published var isSaving = false
    @Published var saveError: String? = nil
    @Published var savedExerciseResult: UserExercise? = nil
    
    private let poseDetectionService = PoseDetectionService()
    private var countdownTimer: Timer?
    
    func startExerciseCountdown() {
        countdown = 3
        isExerciseActive = false
        
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            
            if self.countdown > 1 {
                self.countdown -= 1
            } else {
                timer.invalidate()
                self.countdown = 0
                self.isExerciseActive = true
                self.poseDetectionService.resetExerciseStates()
            }
        }
    }
    
    func stopExercise() {
        isExerciseActive = false
        countdownTimer?.invalidate()
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
    
    func saveExerciseResult(userId: Int, exerciseId: Int, completion: @escaping (Bool) -> Void) {
        guard !isSaving else {
            completion(false)
            return
        }
        
        isSaving = true
        saveError = nil
        savedExerciseResult = nil
        
        // Create the exercise result
        let request = CreateUserExerciseRequest(
            exerciseId: exerciseId,
            repetitions: exerciseState.repetitionCount > 0 ? exerciseState.repetitionCount : nil,
            formScore: exerciseState.formScore > 0 ? exerciseState.formScore : nil,
            timeInSeconds: nil, // For run exercise we would add this
            completed: true,
            metadata: ["feedback": exerciseState.feedback]
        )
        
        // Save via API
        APIClient.shared.createUserExercise(userExercise: request)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completionResult in
                self?.isSaving = false
                if case .failure(let error) = completionResult {
                    print("Error saving exercise: \(error.localizedDescription)")
                    self?.saveError = error.localizedDescription
                    completion(false)
                }
            }, receiveValue: { savedExercise in
                self.savedExerciseResult = savedExercise
                completion(true)
            })
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
}

// Exercise View Container that manages state and UI
struct ExerciseViewContainer: View {
    @StateObject var viewModel = ExerciseViewModel()
    @EnvironmentObject var authManager: AuthManager
    let exercise: Exercise
    
    @State private var showingCompletionAlert = false
    @State private var savedExercise: UserExercise?
    
    var body: some View {
        ZStack {
            // Camera view
            CameraView(exerciseViewModel: viewModel, exerciseType: exercise.type)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                // Top overlay with exercise info
                VStack(alignment: .leading, spacing: 8) {
                    Text(exercise.name)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(exercise.description)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.black.opacity(0.6))
                
                Spacer()
                
                // Bottom overlay with rep count, feedback
                VStack(spacing: 15) {
                    if viewModel.countdown > 0 {
                        Text("Starting in \(viewModel.countdown)...")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    } else if viewModel.isExerciseActive {
                        // Rep counter
                        HStack(spacing: 20) {
                            VStack(alignment: .center) {
                                Text("Reps")
                                    .font(.headline)
                                    .foregroundColor(.white.opacity(0.8))
                                
                                Text("\(viewModel.exerciseState.repetitionCount)")
                                    .font(.system(size: 56, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            
                            VStack(alignment: .center) {
                                Text("Form")
                                    .font(.headline)
                                    .foregroundColor(.white.opacity(0.8))
                                
                                Text("\(viewModel.exerciseState.formScore)")
                                    .font(.system(size: 56, weight: .bold))
                                    .foregroundColor(formScoreColor(viewModel.exerciseState.formScore))
                            }
                        }
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(12)
                        
                        // Feedback
                        Text(viewModel.exerciseState.feedback)
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue.opacity(0.8))
                            .cornerRadius(8)
                    }
                }
                .padding(.bottom, 30)
                
                // Control buttons
                HStack(spacing: 25) {
                    if !viewModel.isExerciseActive && viewModel.countdown == 0 {
                        // Start button
                        Button(action: {
                            viewModel.startExerciseCountdown()
                        }) {
                            Text("Start")
                                .font(.headline)
                                .padding(.horizontal, 30)
                        }
                        .ptStyle(.primary)
                        
                    } else if viewModel.isExerciseActive {
                        // Complete button
                        Button(action: {
                            viewModel.stopExercise()
                            
                            if let userId = authManager.currentUser?.id {
                                viewModel.saveExerciseResult(userId: userId, exerciseId: exercise.id) { success in
                                    if success {
                                        savedExercise = viewModel.savedExerciseResult
                                        showingCompletionAlert = true
                                    }
                                }
                            }
                        }) {
                            Text("Complete")
                                .font(.headline)
                                .padding(.horizontal, 30)
                        }
                        .ptStyle(.success)
                        
                        // Cancel button
                        Button(action: {
                            viewModel.stopExercise()
                        }) {
                            Text("Cancel")
                                .font(.headline)
                                .padding(.horizontal, 20)
                        }
                        .ptStyle(.danger)
                    }
                }
                .padding(.bottom, 20)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $showingCompletionAlert) {
            Alert(
                title: Text("Exercise Completed"),
                message: Text("You completed \(viewModel.exerciseState.repetitionCount) repetitions with a form score of \(viewModel.exerciseState.formScore)."),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func formScoreColor(_ score: Int) -> Color {
        switch score {
        case 90...100:
            return .green
        case 75..<90:
            return .blue
        case 60..<75:
            return .orange
        case 40..<60:
            return .yellow
        default:
            return .red
        }
    }
}

// Preview
struct CameraView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = ExerciseViewModel()
        
        // Simulate active exercise with some results
        viewModel.isExerciseActive = true
        viewModel.exerciseState = ExerciseState(
            repetitionCount: 12,
            isUp: false,
            isDown: true,
            formScore: 85,
            feedback: "Good form! Push up."
        )
        
        return ExerciseViewContainer(
            exercise: Exercise(
                id: 1,
                name: "Push-ups",
                description: "Upper body exercise to build chest, shoulder, and arm strength.",
                type: .pushup,
                imageUrl: nil
            )
        )
        .environmentObject(AuthManager())
    }
}