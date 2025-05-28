import SwiftUI
import PTDesignSystem
import SwiftData

/// Unified workout view that handles all exercises with automatic position detection
struct UnifiedWorkoutView: View {
    let exerciseType: ExerciseType
    @StateObject private var viewModel: WorkoutSessionViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    @State private var showExitConfirmation = false
    
    init(exerciseType: ExerciseType) {
        self.exerciseType = exerciseType
        self._viewModel = StateObject(wrappedValue: WorkoutSessionViewModel(exerciseType: exerciseType))
    }
    
    var body: some View {
        ZStack {
            // Camera view background
            CameraPreviewView(session: viewModel.cameraService.session, cameraService: viewModel.cameraService)
                .edgesIgnoringSafeArea(.all)
            
            // Pose detection overlay
            if let body = viewModel.detectedBody {
                PoseOverlayView(detectedBody: body, badJointNames: viewModel.problemJoints)
                    .edgesIgnoringSafeArea(.all)
            }
            
            // Exercise-specific overlay based on workout state
            exerciseOverlay
            
            // Top bar with exercise info and controls
            VStack {
                HStack {
                    Button(action: {
                        showExitConfirmation = true
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .background(Circle().fill(Color.black.opacity(0.5)))
                    }
                    
                    Spacer()
                    
                    // Exercise indicator
                    HStack {
                        Image(systemName: exerciseType.icon)
                            .foregroundColor(.white)
                        Text(exerciseType.displayName)
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 15)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(exerciseType.color.opacity(0.8)))
                    
                    Spacer()
                    
                    // Rep counter (only show during active workout)
                    if viewModel.workoutState == .counting {
                        RepCounterView(count: viewModel.repCount)
                    }
                }
                .padding()
                
                Spacer()
            }
        }
        .onAppear {
            setupViewModel()
        }
        .onDisappear {
            viewModel.cleanup()
        }
        .alert("Exit Workout?", isPresented: $showExitConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Exit", role: .destructive) {
                dismiss()
            }
        } message: {
            Text("Are you sure you want to exit? Your progress will be saved.")
        }
        .fullScreenCover(isPresented: $viewModel.showWorkoutCompleteView) {
            if let result = viewModel.completedWorkoutResult {
                WorkoutCompleteView(
                    result: result.toWorkoutResult(),
                    exerciseGrader: AnyExerciseGraderBox(WorkoutSessionViewModel.createGrader(for: exerciseType))
                )
                .onDisappear {
                    dismiss()
                }
            }
        }
    }
    
    private func setupViewModel() {
        viewModel.modelContext = modelContext
        viewModel.checkCameraPermission()
    }
    
    @ViewBuilder
    var exerciseOverlay: some View {
        switch viewModel.workoutState {
        case .ready:
            InitializingView(exerciseType: exerciseType) {
                viewModel.startPositionDetection()
            }
            
        case .waitingForPosition:
            PositionDetectionOverlay(
                exerciseType: exerciseType,
                instruction: viewModel.currentInstruction.isEmpty ? viewModel.feedbackMessage : viewModel.currentInstruction,
                confidence: viewModel.positioningConfidence,
                missingRequirements: viewModel.missingRequirements
            )
            
        case .positionDetected:
            PositionConfirmedView(exerciseType: exerciseType)
            
        case .countdown:
            CountdownView(
                value: viewModel.countdownValue ?? 3,
                exerciseType: exerciseType
            )
            
        case .counting:
            ActiveWorkoutOverlay(
                exerciseType: exerciseType,
                repCount: viewModel.repCount,
                formScore: Double(viewModel.exerciseGrader.formQualityAverage),
                feedback: viewModel.feedbackMessage
            )
            
        case .finished:
            // Workout completion is handled by fullScreenCover
            EmptyView()
            
        case .requestingPermission:
            CameraPermissionRequestView(
                onRequestPermission: {
                    viewModel.requestCameraPermission()
                },
                onCancel: {
                    dismiss()
                }
            )
            
        case .permissionDenied, .error:
            ErrorOverlayView(
                message: viewModel.errorMessage ?? "Camera access is required for workouts",
                onDismiss: {
                    dismiss()
                }
            )
            
        default:
            EmptyView()
        }
    }
}

// MARK: - Supporting Views

struct InitializingView: View {
    let exerciseType: ExerciseType
    let onStart: () -> Void
    @State private var pulseAnimation = false
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Exercise illustration
            ExerciseIllustration(exerciseType: exerciseType)
                .frame(width: 200, height: 200)
            
            VStack(spacing: 20) {
                Text("Ready for \(exerciseType.displayName)?")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Press GO and get into starting position")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            // GO button
            Button(action: onStart) {
                ZStack {
                    Circle()
                        .fill(exerciseType.color)
                        .frame(width: 150, height: 150)
                        .scaleEffect(pulseAnimation ? 1.05 : 1.0)
                    
                    VStack(spacing: 4) {
                        Text("GO")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.white)
                        
                        Image(systemName: "play.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                }
                .shadow(radius: 10)
            }
            .buttonStyle(PlainButtonStyle())
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    pulseAnimation = true
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.6))
    }
}

struct PositionDetectionOverlay: View {
    let exerciseType: ExerciseType
    let instruction: String
    let confidence: Double
    let missingRequirements: [String]
    
    var body: some View {
        VStack {
            // Exercise-specific visual guide
            ExercisePositionGuide(exerciseType: exerciseType)
                .padding(.top, 60)
            
            Spacer()
            
            // Feedback section
            VStack(spacing: 20) {
                // Main instruction with icon
                HStack {
                    Image(systemName: confidence > 0.7 ? "checkmark.circle.fill" : "arrow.triangle.2.circlepath")
                        .font(.title2)
                        .foregroundColor(confidence > 0.7 ? .green : .yellow)
                    
                    Text(instruction.isEmpty ? "Get into starting position" : instruction)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 25)
                .padding(.vertical, 15)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.black.opacity(0.8))
                )
                
                // Position quality indicator
                PositionQualityIndicator(
                    confidence: confidence,
                    exerciseColor: exerciseType.color
                )
                .frame(width: 250, height: 10)
                
                // Specific requirements
                if !missingRequirements.isEmpty {
                    VStack(spacing: 10) {
                        ForEach(missingRequirements, id: \.self) { requirement in
                            RequirementRow(text: requirement)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                // Exercise-specific tips
                ExercisePositionTips(exerciseType: exerciseType)
                    .padding(.horizontal, 30)
            }
            .padding(.bottom, 50)
        }
    }
}

struct ActiveWorkoutOverlay: View {
    let exerciseType: ExerciseType
    let repCount: Int
    let formScore: Double
    let feedback: String
    
    var body: some View {
        VStack {
            // Form score at top
            FormScoreView(score: formScore, color: exerciseType.color)
                .padding(.top, 100)
            
            Spacer()
            
            // Rep counter and feedback
            VStack(spacing: 20) {
                // Large rep display
                VStack(spacing: 10) {
                    Text("\(repCount)")
                        .font(.system(size: 80, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("REPS")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.horizontal, 50)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(exerciseType.color.opacity(0.8))
                )
                
                // Real-time feedback
                if !feedback.isEmpty && feedback != "Workout active" {
                    Text(feedback)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.7))
                        )
                }
            }
            .padding(.bottom, 100)
        }
    }
}

struct ErrorOverlayView: View {
    let message: String
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            Text("Error")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(message)
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button("Dismiss", action: onDismiss)
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 200, height: 50)
                .background(Color.red)
                .cornerRadius(25)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.8))
    }
}

#Preview {
    UnifiedWorkoutView(exerciseType: .pushup)
} 