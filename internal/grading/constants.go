package grading

// Constants for Exercise Types
const (
	ExerciseTypePushup = "pushup"
	ExerciseTypeSitup  = "situp"
	ExerciseTypePullup = "pullup"
	ExerciseTypeRun    = "run"
)

// Error Types
type GradingError string

func (e GradingError) Error() string {
	return string(e)
}

const (
	ErrUnknownExerciseType GradingError = "unknown exercise type"
	ErrInvalidInput        GradingError = "invalid input value"
	ErrMissingJoint        GradingError = "required joint is missing or has low confidence"
	ErrInvalidPose         GradingError = "invalid pose for exercise"
	ErrPoorForm            GradingError = "poor exercise form detected"
)

// Push-up Form Thresholds
const (
	PushupElbowAngleDownMax      float64 = 90.0  // Max elbow angle considered 'down'
	PushupElbowAngleUpMin        float64 = 160.0 // Min elbow angle considered 'up'
	PushupHipSagThreshold        float64 = 0.10  // Max deviation for hip sagging
	PushupHipPikeThreshold       float64 = 0.12  // Max deviation for hip piking/raising
	PushupShoulderAlignmentXDiff float64 = 0.10  // Max normalized X diff between shoulders
	PushupRequiredConfidence     float64 = 0.5   // Min confidence for key joints
)

// Sit-up Form Thresholds
const (
	SitupHipAngleDownMax      float64 = 90.0  // Max hip angle at bottom position
	SitupHipAngleUpMin        float64 = 150.0 // Min hip angle at top position
	SitupRequiredConfidence   float64 = 0.5   // Min confidence for key joints
	SitupTorsoRotationMaxDiff float64 = 0.15  // Max allowed torso rotation
)

// Pull-up Form Thresholds
const (
	PullupChinOverBarThreshold float64 = 0.05  // Chin must be this much over the bar
	PullupArmExtensionMax      float64 = 140.0 // Max elbow angle at bottom position
	PullupRequiredConfidence   float64 = 0.5   // Min confidence for key joints
)

// Run tracking thresholds
const (
	RunningMinSpeedMPS       float64 = 1.8   // Minimum speed in meters per second to be considered running
	RunningMaxStrideTimeSec  float64 = 1.2   // Maximum time for a stride in seconds
	RunningMinStrideLengthM  float64 = 0.5   // Minimum stride length in meters
	RunningVerticalOscMaxM   float64 = 0.15  // Maximum vertical oscillation in meters
	RunningCadenceMinSPM     float64 = 150.0 // Minimum cadence in steps per minute
	RunningGroundContactMaxS float64 = 0.3   // Maximum ground contact time in seconds
)
