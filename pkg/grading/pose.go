package grading

import (
	"math"
)

// Joint represents a 2D position with confidence value.
type Joint struct {
	X          float64
	Y          float64
	Confidence float64
}

// Pose represents a detected human pose with joint locations.
type Pose struct {
	Joints map[string]Joint
}

// GradingResult represents the outcome of grading a single exercise pose.
type GradingResult struct {
	IsValid    bool    // Whether this pose is valid for the exercise
	RepCounted bool    // Whether a repetition was counted with this pose
	FormScore  float64 // Quality score for form (0-1.0)
	Feedback   string  // Feedback message (if any)
	State      string  // Current state in the exercise (e.g., "up", "down")
}

// ExerciseState contains state tracking information for exercise repetition counting.
type ExerciseState struct {
	RepCount          int
	CurrentPhase      string
	PreviousPhase     string
	MinElbowAngle     float64 // For push-ups, pull-ups
	MinHipAngle       float64 // For sit-ups
	WentLowEnough     bool
	FormIssues        []string
	PositivePhaseTime float64 // For timing concentric phase (push/pull up)
	NegativePhaseTime float64 // For timing eccentric phase (lowering)
}

// NewPose creates a new pose with initialized joint map.
func NewPose() *Pose {
	return &Pose{
		Joints: make(map[string]Joint),
	}
}

// NewExerciseState creates a new exercise state with default values.
func NewExerciseState() *ExerciseState {
	return &ExerciseState{
		RepCount:      0,
		CurrentPhase:  "start",
		PreviousPhase: "start",
		MinElbowAngle: 180.0,
		MinHipAngle:   180.0,
		WentLowEnough: false,
		FormIssues:    make([]string, 0),
	}
}

// CalculateAngle computes the angle in degrees between three joints.
func CalculateAngle(point1, center, point2 Joint) float64 {
	// Calculate vectors from center point
	v1x := point1.X - center.X
	v1y := point1.Y - center.Y
	v2x := point2.X - center.X
	v2y := point2.Y - center.Y

	// Calculate dot product
	dotProduct := v1x*v2x + v1y*v2y

	// Calculate magnitudes
	mag1 := math.Sqrt(v1x*v1x + v1y*v1y)
	mag2 := math.Sqrt(v2x*v2x + v2y*v2y)

	// Calculate angle in radians and convert to degrees
	if mag1 == 0 || mag2 == 0 {
		return 0
	}

	cosAngle := dotProduct / (mag1 * mag2)
	// Clamp cosAngle to [-1, 1] to handle potential floating-point errors
	cosAngle = math.Max(-1, math.Min(1, cosAngle))

	angleRad := math.Acos(cosAngle)
	angleDeg := angleRad * 180 / math.Pi

	return angleDeg
}

// Distance calculates the Euclidean distance between two joints.
func Distance(joint1, joint2 Joint) float64 {
	dx := joint2.X - joint1.X
	dy := joint2.Y - joint1.Y
	return math.Sqrt(dx*dx + dy*dy)
}

// VerifyJointConfidence checks if all required joints have sufficient confidence.
func VerifyJointConfidence(pose *Pose, requiredJoints []string, minConfidence float64) (bool, []string) {
	missingJoints := make([]string, 0)

	for _, jointName := range requiredJoints {
		joint, exists := pose.Joints[jointName]
		if !exists || joint.Confidence < minConfidence {
			missingJoints = append(missingJoints, jointName)
		}
	}

	return len(missingJoints) == 0, missingJoints
}

// Helper function to interpolate Y value on a line at a given X
func InterpolateY(x1, y1, x2, y2, x float64) float64 {
	// Avoid division by zero
	if x2 == x1 {
		return y1
	}

	slope := (y2 - y1) / (x2 - x1)
	return y1 + slope*(x-x1)
}

// NormalizeCoordinates scales the pose coordinates to a normalized space
func NormalizeCoordinates(pose *Pose) *Pose {
	// Find bounding box
	minX, minY := math.MaxFloat64, math.MaxFloat64
	maxX, maxY := -math.MaxFloat64, -math.MaxFloat64

	for _, joint := range pose.Joints {
		minX = math.Min(minX, joint.X)
		minY = math.Min(minY, joint.Y)
		maxX = math.Max(maxX, joint.X)
		maxY = math.Max(maxY, joint.Y)
	}

	width := maxX - minX
	height := maxY - minY

	// Prevent division by zero
	if width < 0.001 {
		width = 1.0
	}
	if height < 0.001 {
		height = 1.0
	}

	// Create normalized pose
	normalizedPose := NewPose()

	for name, joint := range pose.Joints {
		normalizedPose.Joints[name] = Joint{
			X:          (joint.X - minX) / width,
			Y:          (joint.Y - minY) / height,
			Confidence: joint.Confidence,
		}
	}

	return normalizedPose
}
