# PT Champion: Sit-up to Plank Conversion Plan

## Overview

This document outlines the comprehensive plan to convert the existing "sit-up" exercise in PT Champion to a "plank" exercise while maintaining USMC/military fitness standards and leveraging MediaPipe pose detection for accurate form validation.

## Executive Summary

The plank exercise will replace sit-ups as a core strengthening assessment, transitioning from a **repetition-based** exercise to a **time-based endurance** exercise. This aligns with modern USMC Physical Fitness Test (PFT) standards where planks are now used instead of sit-ups.

## USMC Plank Standards (Official Research)

Based on official USMC guidance and MARSOC training standards:

### Official USMC Plank Form Requirements
The USMC now requires a static **plank** hold instead of crunches. Official guidance emphasizes:

1. **Starting Position**: Forearms flat on the ground, body straight from head to heels
2. **Body Alignment**: "Push-up style" straight body line with **no sagging or arching**
3. **Hip Position**: Hips must be **lifted** off the ground - back, buttocks and legs in one straight line
4. **Spine Position**: Neutral and flat - **no drooping at the hips and no rounding of the back**
5. **Elbow Placement**: Elbows under shoulders (about shoulder-width apart)
6. **Feet Position**: Roughly hip-width apart
7. **Head Position**: In line with the body (neutral neck)
8. **Support Points**: Only forearms and toes touching ground

> **Key USMC Form Cues:** Keep the **body straight** from head to heels, **hips up**, **legs straight**, and **elbows under shoulders**

### Form Failure Criteria
- Any break of straight-line form (hips sagging or rising, legs bending)
- Hands or feet leaving contact with ground
- **Minor trembling is allowed** as long as form is maintained
- Form failure **immediately ends the hold**

### Performance Standards
- **Initial Strength Test (IST)**: Minimum 40 seconds
- **PFT Standard**: Timed plank with longer requirements based on age/gender
- **Scoring**: Time-based performance measurement

## Technical Implementation Plan

### Phase 1: iOS Core Implementation (Primary Focus)

#### 1.1 Exercise Type System Updates

**File: `ios/ptchampion/Models/WorkoutModels.swift`**

Add plank as a new exercise type following the existing pattern:

```swift
enum ExerciseType: String, CaseIterable, Codable, Identifiable {
    case pushup = "pushup"
    case pullup = "pullup"
    case situp = "situp"      // Keep temporarily for migration
    case plank = "plank"      // NEW: Add plank
    case run = "run"
    case unknown = "unknown"
    
    var displayName: String {
        switch self {
        case .pushup: return "Push-ups"
        case .pullup: return "Pull-ups"
        case .situp: return "Sit-ups"    // Keep temporarily
        case .plank: return "Plank"       // NEW: Add after .situp case
        case .run: return "2-mile Run"
        case .unknown: return "Unknown Exercise"
        }
    }
    
    var exerciseId: Int {
        switch self {
        case .pushup: return 1
        case .pullup: return 2
        case .situp: return 3             // Keep temporarily
        case .plank: return 5             // NEW: Use ID 5 for plank
        case .run: return 4
        case .unknown: return 0
        }
    }
    
    var color: Color {
        switch self {
        case .pushup: return .blue
        case .pullup: return .green
        case .situp: return .orange       // Keep temporarily
        case .plank: return .purple       // NEW: Distinct color for plank
        case .run: return .red
        case .unknown: return .gray
        }
    }
    
    var icon: String {
        switch self {
        case .pushup: return "figure.strengthtraining.traditional"
        case .pullup: return "figure.climbing"
        case .situp: return "figure.core.training"
        case .plank: return "figure.core.training"  // Same icon as situp
        case .run: return "figure.run"
        case .unknown: return "questionmark.circle"
        }
    }
}
```

**Numeric Mapping Updates** (around line 383):
```swift
// In InsertUserExerciseRequest initializer
switch exerciseId {
case 1:
    self.exerciseType = "pushup"
case 2:
    self.exerciseType = "pullup"
case 3:
    self.exerciseType = "situp"
case 5:                           // NEW
    self.exerciseType = "plank"   // NEW: Map ID 5 to plank
case 4:
    self.exerciseType = "run"
default:
    self.exerciseType = "unknown"
}
```

**Legacy Mapping** (around line 483):
```swift
// In UserExerciseRecord computed property
var exerciseTypeKey: String {
    switch exerciseId {
    case 1: return "pushup"
    case 2: return "pullup"
    case 3: return "situp"
    case 5: return "plank"    // NEW: Add plank mapping
    case 4: return "run"
    default: return "unknown"
    }
}
```

#### 1.2 WorkoutSessionViewModel Updates

**File: `ios/ptchampion/ViewModels/WorkoutSessionViewModel.swift`**

In the `createGrader(for:)` static function, replace sit-up with plank:

```swift
static func createGrader(for exerciseType: ExerciseType) -> any ExerciseGraderProtocol {
    switch exerciseType {
    case .pushup:
        return EnhancedPushupGrader()
    // case .situp:                         // COMMENTED OUT
    //     return EnhancedSitupGrader()    // COMMENTED OUT
    case .plank:                           // NEW
        return PlankGrader()               // NEW: Use PlankGrader
    case .pullup:
        return EnhancedPullupGrader()
    default:
        fatalError("Unsupported exercise type: \(exerciseType)")
    }
}
```

#### 1.3 UI Orientation Logic Updates

**File: `ios/ptchampion/Views/Workouts/WorkoutSessionView.swift`** (lines 42-48)

Update the `requiresLandscape` logic to group plank with pushup:

```swift
var requiresLandscape: Bool {
    switch exerciseType {
    case .pushup, .plank:              // CHANGED: Added .plank
        return true
    // case .situp:                     // REMOVED
    default:
        return false
    }
}
```

**File: `ios/ptchampion/Views/Workouts/EnhancedExerciseOverlay.swift`** (lines 19-25)

Same change for the overlay:

```swift
switch exerciseType {
case .pushup, .plank:                  // CHANGED: Added .plank
    return true
// case .situp:                         // REMOVED
default:
    return false
}
```

#### 1.4 Disable Existing Sit-up Grader

**File: `ios/ptchampion/Grading/EnhancedSitupGrader.swift`**

Comment out the main grading logic (lines 96-184) and replace with a stub:

```swift
func gradePose(body: DetectedBody) -> GradingResult {
    /* COMMENTED OUT - Sit-up replaced by plank
    // Clear previous problem joints
    _problemJoints = []
    
    // Process frame with APFT validator
    let result = apftValidator.processFrame(body: body, exerciseType: "situp")
    
    // ... (lines 96-184 of original implementation)
    */
    
    // Disabled sit-up logic
    return .invalidPose(reason: "Sit-up exercise replaced by plank.")
}
```

#### 1.5 New Plank Grader Implementation

**New File: `ios/ptchampion/Grading/PlankGrader.swift`**

Complete implementation based on the detailed specifications:

```swift
import Foundation
import Vision
import CoreGraphics
import Combine

final class PlankGrader: ObservableObject, ExerciseGraderProtocol {
    // MARK: - Protocol Properties
    private var _lastFormIssue: String? = nil
    private var _problemJoints: Set<VNHumanBodyPoseObservation.JointName> = []
    private var currentFeedback: String = "Get into plank position."
    
    // Public for UI highlighting
    var problemJoints: Set<VNHumanBodyPoseObservation.JointName> {
        return _problemJoints
    }
    var currentPhaseDescription: String { "Hold plank" }
    var repCount: Int { return 0 }  // Plank is time-based, not rep-based
    var formQualityAverage: Double { return 0.0 }
    var lastFormIssue: String? { return _lastFormIssue }
    
    func resetState() {
        _lastFormIssue = nil
        _problemJoints = []
        currentFeedback = "Get into plank position."
    }
    
    func gradePose(body: DetectedBody) -> GradingResult {
        _problemJoints = []
        
        // Check torso (shoulder-hip-knee) angle for body alignment
        if let leftAngle = body.calculateAngle(first: .leftShoulder, vertex: .leftHip, second: .leftKnee),
           let rightAngle = body.calculateAngle(first: .rightShoulder, vertex: .rightHip, second: .rightKnee) {
            let avgAngle = (leftAngle + rightAngle) / 2
            
            if avgAngle < 160 {
                // Body is not straight: hips sagging
                _problemJoints.insert(.leftHip)
                _problemJoints.insert(.rightHip)
                _lastFormIssue = "Keep your body straight"
                currentFeedback = "Hips are dropping – raise your core"
                return .incorrectForm(feedback: currentFeedback)
            }
        }
        
        // Check knees (hip-knee-ankle) angle for bent legs
        if let leftKneeAngle = body.calculateAngle(first: .leftHip, vertex: .leftKnee, second: .leftAnkle),
           let rightKneeAngle = body.calculateAngle(first: .rightHip, vertex: .rightKnee, second: .rightAnkle) {
            let avgKneeAngle = (leftKneeAngle + rightKneeAngle) / 2
            
            if avgKneeAngle < 160 {
                _problemJoints.insert(.leftKnee)
                _problemJoints.insert(.rightKnee)
                _lastFormIssue = "Straighten your legs"
                currentFeedback = "Keep legs straight"
                return .incorrectForm(feedback: currentFeedback)
            }
        }
        
        // Check elbow alignment under shoulders
        if let ls = body.point(.leftShoulder), let le = body.point(.leftElbow),
           let rs = body.point(.rightShoulder), let re = body.point(.rightElbow) {
            let leftOffset = abs(ls.location.x - le.location.x)
            let rightOffset = abs(rs.location.x - re.location.x)
            
            if leftOffset > 0.1 || rightOffset > 0.1 {
                _problemJoints.insert(.leftElbow)
                _problemJoints.insert(.rightElbow)
                _problemJoints.insert(.leftShoulder)
                _problemJoints.insert(.rightShoulder)
                _lastFormIssue = "Keep your elbows under shoulders"
                currentFeedback = "Elbows under shoulders"
                return .incorrectForm(feedback: currentFeedback)
            }
        }
        
        // No issues detected - good plank form
        currentFeedback = "Good form - keep holding!"
        return .inProgress(phase: currentPhaseDescription)
    }
    
    func calculateFinalScore() -> Double? {
        return nil  // No scoring for plank (handled externally via time)
    }
}
```

Key requirements:
- Implement `ExerciseGraderProtocol` (follows existing pattern)
- Track time-based performance instead of repetitions  
- Validate plank form using MediaPipe landmarks and USMC standards
- Provide real-time feedback for form corrections
- Continuous monitoring (no rep counting)

**Core MediaPipe Validations (Using BlazePose Model):**

Implementation uses MediaPipeTasksVision pod with `DetectedBody` structure and `DetectedPoint` landmarks:

1. **Hip Angle Validation**: 
   - Calculate **shoulder-hip-knee** angle using `calculateAngle(first:vertex:second:)`
   - Target: ~180° (straight body line)
   - Tolerance: ±10-15° acceptable range
   - Below 170°: "Hips are dropping - raise your core"

2. **Knee Angle Validation**:
   - Calculate **hip-knee-ankle** angle 
   - Target: ~180° (straight legs)
   - Below 170°: "Keep legs straight"

3. **Body Line Assessment**:
   - Compare left vs right hip angles for symmetry
   - Check shoulder-hip height alignment
   - Large differences indicate tilting/rotation

4. **Elbow Position Check**:
   - Verify elbows positioned under shoulders (vertical alignment)
   - "Elbows under shoulders" feedback if misaligned

5. **Continuous Form Monitoring**:
   - Per-frame evaluation (no rep counting)
   - Minor trembling allowed if form maintained
   - Immediate feedback on form breaks

**Required Landmarks with Confidence:**
- Shoulders: `leftShoulder`, `rightShoulder`
- Hips: `leftHip`, `rightHip` 
- Knees: `leftKnee`, `rightKnee`
- Ankles: `leftAnkle`, `rightAnkle`
- Elbows: `leftElbow`, `rightElbow`
- Head/Nose: `nose` (for head position)

#### 1.3 APFT Validator Updates

**File: `ios/ptchampion/Grading/APFTRepValidator.swift`**

Add new plank validation logic based on USMC standards:
```swift
enum PlankPhase: String {
    case setup = "setup"
    case holding = "holding"    // Main phase - continuous hold
    case failed = "failed"     // Form break detected
    case complete = "complete"  // User-ended hold
}

// USMC-compliant plank standards
static let plankHipAngleMin: Float = 170.0           // Min shoulder-hip-knee angle
static let plankKneeAngleMin: Float = 170.0          // Min hip-knee-ankle angle (straight legs)
static let plankAngleTolerance: Float = 10.0         // ±10-15° tolerance around 180°
static let plankBodySymmetryTolerance: Float = 15.0  // Max left/right angle difference
static let plankElbowAlignmentTolerance: Float = 0.1 // Elbow-shoulder vertical alignment
static let plankStabilityFrames: Int = 3             // Frames to confirm form break
static let plankRequiredConfidence: Float = 0.6      // Higher confidence for plank landmarks
```

#### 1.4 Scoring System Updates

**File: `ios/ptchampion/Grading/ScoreRubrics.swift`**

Replace sit-up rep-based scoring with time-based plank scoring:
```swift
case .plank:
    // Time-based scoring (seconds to score mapping)
    // Based on USMC PFT standards
    return calculatePlankScore(timeInSeconds: performanceValue)
```

### Phase 2: Form Validation Logic

#### 2.1 Core Validation Functions (USMC-Compliant Implementation)

Based on official USMC standards and detailed MediaPipe pose estimation:

**Hip Angle Validation (Primary Check):**
```swift
func validateHipAlignment(body: DetectedBody) -> (isValid: Bool, feedback: String, problemJoints: Set<VNHumanBodyPoseObservation.JointName>) {
    // Calculate shoulder-hip-knee angle for both sides using existing helper
    let leftHipAngle = calculateAngle(first: leftShoulder.location, vertex: leftHip.location, second: leftKnee.location)
    let rightHipAngle = calculateAngle(first: rightShoulder.location, vertex: rightHip.location, second: rightKnee.location)
    
    // Check if both angles are within acceptable range (170-190°)
    if leftHipAngle < plankHipAngleMin || rightHipAngle < plankHipAngleMin {
        return (false, "Hips are dropping – raise your core", [.leftHip, .rightHip])
    }
    
    // Check for excessive piking (angles too large) 
    if leftHipAngle > 190.0 || rightHipAngle > 190.0 {
        return (false, "Lower your hips – avoid piking", [.leftHip, .rightHip])
    }
    
    return (true, "Good form", [])
}

func validateLegStraightness(body: DetectedBody) -> (isValid: Bool, feedback: String, problemJoints: Set<VNHumanBodyPoseObservation.JointName>) {
    // Calculate hip-knee-ankle angle for both legs
    let leftKneeAngle = calculateAngle(first: leftHip.location, vertex: leftKnee.location, second: leftAnkle.location)
    let rightKneeAngle = calculateAngle(first: rightHip.location, vertex: rightKnee.location, second: rightAnkle.location)
    
    if leftKneeAngle < plankKneeAngleMin || rightKneeAngle < plankKneeAngleMin {
        return (false, "Keep legs straight", [.leftKnee, .rightKnee])
    }
    
    return (true, "", [])
}

func validateBodySymmetry(body: DetectedBody) -> (isValid: Bool, feedback: String, problemJoints: Set<VNHumanBodyPoseObservation.JointName>) {
    // Compare left vs right hip angles for body symmetry
    let leftHipAngle = calculateAngle(first: leftShoulder.location, vertex: leftHip.location, second: leftKnee.location)
    let rightHipAngle = calculateAngle(first: rightShoulder.location, vertex: rightHip.location, second: rightKnee.location)
    
    if abs(leftHipAngle - rightHipAngle) > plankBodySymmetryTolerance {
        return (false, "Keep shoulders level", [.leftShoulder, .rightShoulder, .leftHip, .rightHip])
    }
    
    return (true, "", [])
}

func validateElbowPlacement(body: DetectedBody) -> (isValid: Bool, feedback: String, problemJoints: Set<VNHumanBodyPoseObservation.JointName>) {
    // Check vertical alignment: elbows under shoulders
    guard let leftElbow = body.point(.leftElbow),
          let rightElbow = body.point(.rightElbow),
          let leftShoulder = body.point(.leftShoulder),
          let rightShoulder = body.point(.rightShoulder) else {
        return (false, "Cannot detect elbow position", [])
    }
    
    let leftOffset = abs(leftElbow.location.x - leftShoulder.location.x)
    let rightOffset = abs(rightElbow.location.x - rightShoulder.location.x)
    
    if leftOffset > plankElbowAlignmentTolerance || rightOffset > plankElbowAlignmentTolerance {
        return (false, "Elbows under shoulders", [.leftElbow, .rightElbow, .leftShoulder, .rightShoulder])
    }
    
    return (true, "", [])
}
```

**Main Grader Integration:**
```swift
func gradePose(body: DetectedBody) -> GradingResult {
    // 1. Verify required joints have sufficient confidence
    let requiredJoints: [VNHumanBodyPoseObservation.JointName] = [
        .leftShoulder, .rightShoulder, .leftHip, .rightHip,
        .leftKnee, .rightKnee, .leftAnkle, .rightAnkle,
        .leftElbow, .rightElbow
    ]
    
    for joint in requiredJoints {
        guard let point = body.point(joint), point.confidence >= plankRequiredConfidence else {
            return .invalidPose(reason: "Cannot clearly see required body parts")
        }
    }
    
    // 2. Run all form validations
    let hipValidation = validateHipAlignment(body: body)
    let legValidation = validateLegStraightness(body: body)
    let symmetryValidation = validateBodySymmetry(body: body)
    let elbowValidation = validateElbowPlacement(body: body)
    
    // 3. Combine problem joints and feedback
    var allProblems: Set<VNHumanBodyPoseObservation.JointName> = []
    var feedbackMessages: [String] = []
    
    if !hipValidation.isValid {
        allProblems.formUnion(hipValidation.problemJoints)
        feedbackMessages.append(hipValidation.feedback)
    }
    if !legValidation.isValid {
        allProblems.formUnion(legValidation.problemJoints)
        feedbackMessages.append(legValidation.feedback)
    }
    // ... continue for other validations
    
    // 4. Return appropriate result
    if feedbackMessages.isEmpty {
        return .inProgress(phase: "Holding") // Good form - continue plank
    } else {
        _problemJoints = allProblems
        return .incorrectForm(feedback: feedbackMessages.first ?? "Adjust form")
    }
}
```

#### 2.2 Real-time Feedback System (USMC-Aligned)

Based on official USMC plank guidance and form requirements:

**Primary Form Feedback Messages:**
- **Hip Dropping**: "Hips are dropping – raise your core"
- **Hip Piking**: "Lower your hips – avoid piking" 
- **Bent Legs**: "Keep legs straight"
- **Elbow Misalignment**: "Elbows under shoulders"
- **Body Asymmetry**: "Keep shoulders level"
- **Form Maintained**: "Good form" / "Excellent hold - keep going!"

**Setup/Instruction Messages:**
- "Get into plank position (forearms on ground)"
- "Body straight from head to heels"
- "Hips up, legs straight"
- "Minor trembling is okay - maintain form"

**Continuous Monitoring Logic:**
```swift
// Per-frame evaluation (no rep counting - continuous hold)
// Minor trembling allowed if form maintained
// Immediate feedback on form breaks
// Form failure immediately ends the hold (USMC standard)

if allFormChecksPass {
    return .inProgress(phase: "Holding")
} else if hasFormIssues {
    return .incorrectForm(feedback: primaryIssue)
} else if formFailureDetected {
    return .failed(reason: "Form break - exercise ended")
}
```

**Problem Joint Highlighting:**
- Hip issues: Highlight `.leftHip`, `.rightHip`
- Leg issues: Highlight `.leftKnee`, `.rightKnee`
- Elbow issues: Highlight `.leftElbow`, `.rightElbow`, `.leftShoulder`, `.rightShoulder`
- Symmetry issues: Highlight shoulders and hips

### Phase 3: Database & Backend Updates

#### 3.1 Database Schema Changes

**File: `shared/schema.ts`**
```typescript
export const SEED_EXERCISES = [
  {
    name: "Push-ups",
    description: "Upper body exercise performed in a prone position, raising and lowering the body using the arms",
    type: "pushup",
  },
  {
    name: "Pull-ups", 
    description: "Upper body exercise where you hang from a bar and pull your body up until your chin is above the bar",
    type: "pullup",
  },
  {
    name: "Plank",  // CHANGED
    description: "Core stability exercise performed by maintaining a rigid body position supported by forearms and toes",
    type: "plank",  // CHANGED
  },
  {
    name: "2-mile Run",
    description: "Cardio exercise measuring endurance over a 2-mile distance", 
    type: "run",
  },
];
```

#### 3.2 API Updates

**Files to Update:**
- `openapi.yaml`: Update exercise type enums
- `scripts/generate-openapi.ts`: Update exercise type validations
- Backend grading constants: Update exercise type mappings

**Migration Strategy:**
1. Add "plank" as new exercise type
2. Keep "situp" temporarily for backward compatibility
3. Migrate existing sit-up records (or keep as historical data)
4. Update UI to show "plank" instead of "sit-up"

### Phase 4: Web Implementation

#### 4.1 Web Exercise Types

**File: `web/src/grading/ExerciseType.ts`**
```typescript
export enum ExerciseType {
  PUSHUP = 'PUSHUP',
  PULLUP = 'PULLUP', 
  PLANK = 'PLANK',    // CHANGED: SITUP -> PLANK
  RUNNING = 'RUNNING'
}
```

#### 4.2 New Plank Analyzer

**New File: `web/src/grading/PlankAnalyzer.ts`**

Similar to `SitupAnalyzer.ts` but focused on:
- Time-based performance tracking
- Form validation using MediaPipe landmarks
- Real-time feedback for form corrections
- Stability analysis over time

**Key Interfaces:**
```typescript
export interface PlankAnalyzerConfig {
  // Angle thresholds
  minBodyAlignment: number;      // Minimum angle for straight body
  maxBodyAlignment: number;      // Maximum angle for straight body
  hipSagThreshold: number;       // Maximum hip sag tolerance
  hipPikeThreshold: number;      // Maximum hip pike tolerance
  
  // Stability thresholds
  stabilityThreshold: number;    // Movement tolerance
  formFailureTime: number;       // Time before form failure ends exercise
}

export interface PlankFormAnalysis {
  // Body alignment
  bodyAlignment: number;         // Shoulder-hip-ankle angle
  hipSag: number;               // Hip sag measurement
  hipPike: number;              // Hip pike measurement
  
  // Positions
  isValidForm: boolean;         // Overall form validity
  isStable: boolean;           // Body stability
  
  // Form issues
  isBodyAligned: boolean;      // Straight body line
  isHipPositionCorrect: boolean; // Proper hip position
  isElbowPositionCorrect: boolean; // Elbows under shoulders
  
  // Performance tracking
  holdTime: number;            // Current hold time
  isActive: boolean;           // Currently holding plank
  formFailureCount: number;    // Number of form failures
  
  // Timestamps
  timestamp: number;
  lastValidFormTimestamp: number;
}
```

### Phase 5: UI/UX Updates

#### 5.1 iOS UI Changes

**Files to Update:**
- `WorkoutSelectionView.swift`: Update exercise selection UI
- `WorkoutSessionView.swift`: Change timer display for time-based exercise
- `WorkoutHistoryView.swift`: Display time instead of reps
- Exercise instruction overlays: New plank-specific guidance

**New UI Elements:**
- Timer display (instead of rep counter)
- Form quality indicator
- Real-time body alignment visualization
- Hold time progress bar

#### 5.2 Web UI Changes

**Files to Update:**
- Exercise tracker pages: Replace sit-up tracker with plank tracker
- History displays: Show time-based metrics
- Leaderboards: Time-based rankings instead of rep-based

### Phase 6: Validation & Testing

#### 6.1 Form Validation Testing

**Test Scenarios:**
1. **Perfect Form**: Straight body line, proper hold
2. **Hip Sagging**: Hips drop below neutral line
3. **Hip Piking**: Hips rise above neutral line
4. **Elbow Misalignment**: Elbows not under shoulders
5. **Excessive Movement**: Body shaking/instability
6. **Head Position**: Looking up/down instead of neutral

#### 6.2 Edge Case Handling

**Scenarios to Test:**
- User collapses mid-plank
- User adjusts position during hold
- Camera angle changes during exercise
- Partial body visibility
- Different body types/proportions

### Phase 7: Deployment Strategy

#### 7.1 Rollout Plan

1. **Beta Testing**: Internal testing with plank implementation
2. **Gradual Rollout**: Feature flag to enable plank vs sit-up
3. **Migration**: Transition existing users from sit-up to plank
4. **Data Migration**: Handle existing sit-up records appropriately

#### 7.2 Backward Compatibility

**Considerations:**
- Keep existing sit-up data for historical purposes
- Provide migration messaging to users
- Update scoring comparisons appropriately
- Maintain API compatibility during transition

## Key Implementation Files

### New Files to Create:
1. `ios/ptchampion/Grading/EnhancedPlankGrader.swift`
2. `web/src/grading/PlankAnalyzer.ts`
3. `web/src/pages/exercises/PlankTracker.tsx` 
4. Migration scripts for database updates

### Files to Modify:
1. `ios/ptchampion/Models/WorkoutModels.swift` - Exercise type enum
2. `ios/ptchampion/Grading/APFTRepValidator.swift` - Add plank validation
3. `ios/ptchampion/Grading/ScoreRubrics.swift` - Time-based scoring
4. `shared/schema.ts` - Database schema updates
5. `web/src/grading/ExerciseType.ts` - Web exercise types
6. Various UI files for plank-specific interfaces

## Success Metrics

1. **Form Accuracy**: >95% accurate form detection compared to human assessment
2. **User Experience**: Smooth transition from sit-up to plank interface
3. **Performance**: Real-time form validation at 30fps
4. **Reliability**: Consistent timing and form validation across devices
5. **USMC Compliance**: Form requirements match official USMC standards

## Timeline Estimate

- **Week 1-2**: iOS core implementation (grader, validator, models)
- **Week 3**: Scoring system and database updates  
- **Week 4**: Web implementation (analyzer, UI)
- **Week 5**: UI/UX updates across platforms
- **Week 6**: Testing and validation
- **Week 7**: Deployment and migration

## Risk Mitigation

1. **Form Detection Accuracy**: Extensive testing with diverse body types
2. **Performance Impact**: Optimize MediaPipe processing for real-time use
3. **User Adoption**: Clear migration messaging and training materials
4. **Data Integrity**: Careful handling of historical sit-up data

## Hiding Sit-ups vs Deletion Strategy

### Benefits of This Approach:
1. **Code Preservation**: All sit-up logic remains for reference/rollback
2. **Database Integrity**: Historical sit-up records stay intact
3. **Easy Reversal**: Can re-enable sit-ups by updating `visibleCases`
4. **Clean Migration**: Users see only plank, but data isn't lost

### Handling Existing Data:
- **Historical Records**: Filter sit-ups in UI queries, not database
- **User Stats**: Calculate separately for visible exercises only
- **Leaderboards**: Exclude sit-up entries from display
- **Progress Tracking**: Show only plank progress going forward

## Implementation Notes (From Research)

### Official USMC References
- **Static plank hold** replaces crunches in current USMC PFT
- **"Push-up style" body line** is the official description
- **Form failure immediately ends the hold** (no recovery allowed)
- **Minor trembling allowed** as long as form is maintained

### MediaPipe Technical Approach
- Use **BlazePose model** via MediaPipeTasksVision pod
- **DetectedBody/DetectedPoint** structure with existing angle calculation helpers
- **Continuous per-frame evaluation** (no rep counting)
- **±10-15° tolerance** around 180° for angle measurements
- **Higher confidence thresholds** (0.6+) for plank landmarks due to static nature

### Key Angle Calculations
1. **Hip Angle**: shoulder-hip-knee (~180° for straight body)
   - Implementation uses 160° threshold for practical detection
   - Average left/right angles for stability
2. **Knee Angle**: hip-knee-ankle (~180° for straight legs)
   - Implementation uses 160° threshold
   - Detects bent legs during plank hold
3. **Body Symmetry**: Compare left vs right hip angles
4. **Elbow Alignment**: X-coordinate alignment check
   - 0.1 normalized unit tolerance
   - Ensures elbows positioned under shoulders

### Integration with Existing Code
- Follows **same pattern as EnhancedPushupGrader/EnhancedSitupGrader**
- Uses existing **calculateAngle() helper functions**
- Implements **ExerciseGraderProtocol** with time-based adaptations
- Maintains **problemJoints highlighting** for UI feedback
- Compatible with existing **DetectedBody pose model**

## Conclusion

This plan provides a comprehensive roadmap for converting PT Champion's sit-up exercise to a plank exercise while maintaining high standards for form validation and user experience. The implementation is based on **official USMC plank standards** and leverages the existing MediaPipe infrastructure in PT Champion. The focus on detailed angle calculations and continuous form monitoring ensures accurate, real-time feedback that aligns with military fitness requirements.

## Implementation Checklist (iOS Priority)

Based on the detailed file-by-file analysis, here's the exact implementation order:

### Step 1: Add Plank Exercise Type (Keep Sit-ups Hidden)
**File**: `ios/ptchampion/Models/WorkoutModels.swift`
- [ ] Add `.plank` case to `ExerciseType` enum (keep `.situp` in code)
- [ ] Add plank to all switch statements
- [ ] Add static computed property to filter visible exercises:
```swift
static var visibleCases: [ExerciseType] {
    return [.pushup, .pullup, .plank, .run]  // Excludes .situp
}
```
- [ ] Update numeric mapping (case 5: "plank")
- [ ] Keep sit-up mappings but don't expose in UI

### Step 2: Create PlankGrader
**New File**: `ios/ptchampion/Grading/PlankGrader.swift`
- [ ] Create file with implementation from section 1.5
- [ ] Import required frameworks (Foundation, Vision, CoreGraphics, Combine)
- [ ] Implement `ExerciseGraderProtocol`
- [ ] Add angle validation logic (160° threshold)
- [ ] Add problem joint highlighting

### Step 3: Update WorkoutSessionViewModel
**File**: `ios/ptchampion/ViewModels/WorkoutSessionViewModel.swift`
- [ ] Comment out `.situp` case in `createGrader(for:)`
- [ ] Add `.plank` case returning `PlankGrader()`

### Step 4: Update UI Orientation Logic
**File**: `ios/ptchampion/Views/Workouts/WorkoutSessionView.swift` (lines 42-48)
- [ ] Add `.plank` to pushup group in `requiresLandscape`
- [ ] Remove/comment `.situp` case

**File**: `ios/ptchampion/Views/Workouts/EnhancedExerciseOverlay.swift` (lines 19-25)
- [ ] Same changes as above for overlay orientation

### Step 5: Disable Sit-up Grader
**File**: `ios/ptchampion/Grading/EnhancedSitupGrader.swift`
- [ ] Comment out `gradePose` implementation (lines 96-184)
- [ ] Replace with stub returning `.invalidPose(reason: "Sit-up exercise replaced by plank.")`

### Step 6: Update Xcode Project
- [ ] Add `PlankGrader.swift` to Xcode project
- [ ] Ensure file is included in the target
- [ ] Build and test compilation

### Step 7: Hide Sit-ups from UI (Without Deleting Code)

**Update Exercise Selection Views:**

**File**: `ios/ptchampion/Views/Workouts/ExerciseSelectionView.swift`
```swift
// Use visibleCases instead of allCases
ForEach(ExerciseType.visibleCases, id: \.self) { exercise in
    // Exercise selection UI
}
```

**File**: `ios/ptchampion/Views/Dashboard/DashboardView.swift`
```swift
// Filter out sit-ups from quick links or recent workouts
let exercises = ExerciseType.visibleCases
```

**File**: `ios/ptchampion/Views/History/WorkoutHistoryView.swift`
```swift
// Add computed property to filter history
var filteredWorkouts: [WorkoutResult] {
    workouts.filter { $0.exerciseType != .situp }
}
```

**File**: `ios/ptchampion/Views/Leaderboards/LeaderboardView.swift`
```swift
// Update exercise type picker
Picker("Exercise", selection: $selectedExerciseType) {
    ForEach(ExerciseType.visibleCases, id: \.self) { exercise in
        Text(exercise.displayName).tag(exercise)
    }
}
```

**Additional UI Updates:**
- [ ] Update any `ForEach(ExerciseType.allCases)` to use `ExerciseType.visibleCases`
- [ ] Filter existing workout history to exclude sit-ups
- [ ] Update exercise type pickers/selectors
- [ ] Keep sit-up grader files intact but unused
- [ ] Maintain sit-up data in database for historical records

### Comprehensive Sit-up Hiding Locations

**Keep `.situp` case handling in these files (for backwards compatibility):**
- `Models/WorkoutModels.swift` - Keep all switch cases
- `Grading/EnhancedSitupGrader.swift` - Keep entire file
- `Grading/CalibratedAPFTValidator.swift` - Keep sit-up validation
- `Grading/ScoreRubrics.swift` - Keep sit-up scoring
- All service files (CalibrationStrategy, EnvironmentAnalyzer, etc.)

**Update to exclude/hide sit-ups in these UI files:**
```swift
// Views/Dashboard/DashboardView.swift (line 124)
// Add filter to hide sit-up stats

// Views/Workouts/WorkoutSessionView.swift (line 44)
case .pushup, .plank:  // Remove .situp from landscape orientation

// Views/Workouts/EnhancedExerciseOverlay.swift (line 21) 
case .pushup, .plank:  // Remove .situp from landscape check

// ViewModels/WorkoutSessionViewModel.swift (line 1174)
case .situp:
    fatalError("Sit-ups are deprecated, use plank")  // Or redirect

// ViewModels/APFTWorkoutViewModel.swift
// Update exercise availability checks to exclude sit-ups
```

**Exercise Selection Filtering:**
```swift
// Add to ExerciseType extension
static var deprecatedExercises: Set<ExerciseType> {
    return [.situp]
}

// Use in UI components
let availableExercises = ExerciseType.allCases.filter { 
    !ExerciseType.deprecatedExercises.contains($0) 
}
```

### Step 8: Testing
- [ ] Verify sit-ups don't appear in exercise selection
- [ ] Confirm plank appears and works correctly
- [ ] Check that historical sit-up data is hidden but preserved
- [ ] Test all UI components for sit-up filtering
- [ ] Verify plank orientation and grading works

**Next Steps**: Start with Step 1 (updating WorkoutModels.swift with visibleCases) and proceed sequentially through the checklist.

## Summary: Hide Sit-ups, Implement Plank

### The Approach:
1. **Add Plank** as a new exercise type alongside existing exercises
2. **Hide Sit-ups** from all UI components using `visibleCases` filtering
3. **Keep all sit-up code** intact for backwards compatibility
4. **Redirect sit-up attempts** to plank in the workout flow

### Key Benefits:
- ✅ **No data loss**: Historical sit-up records remain in database
- ✅ **Easy rollback**: Can re-enable sit-ups by updating filter
- ✅ **Clean UI**: Users only see plank option
- ✅ **Code preservation**: All logic remains for reference

### Quick Implementation:
```swift
// In ExerciseType extension
static var visibleCases: [ExerciseType] {
    [.pushup, .pullup, .plank, .run]  // Excludes .situp
}

// In UI components
ForEach(ExerciseType.visibleCases) { exercise in
    // Only shows non-deprecated exercises
}
```

This approach ensures a smooth transition while maintaining flexibility for future changes. 