# Grading Module

This directory contains exercise evaluation logic that is separated from UI components, similar to the iOS app's Grading module. Each exercise has its own grader implementation that encapsulates form evaluation, state management, and rep counting.

## Structure

- **ExerciseGrader.ts**: Defines the base interface and abstract class for all graders
- **PushupGrader.ts**: Implements push-up specific form evaluation and rep counting
- **PullupGrader.ts**: Implements pull-up specific form evaluation and rep counting
- **SitupGrader.ts**: Implements sit-up specific form evaluation and rep counting
- **RunningGrader.ts**: Implements running exercise evaluation (distance/time based)
- **index.ts**: Exports all graders and provides a factory function

## Usage

### Basic Usage with Factory Function

```typescript
import { createGrader, ExerciseType } from '@/grading';
import { NormalizedLandmark } from '@mediapipe/tasks-vision';

// Create a grader for the desired exercise
const pushupGrader = createGrader(ExerciseType.PUSHUP);

// In your pose detection loop, process each frame
function onPoseResults(landmarks: NormalizedLandmark[]) {
  // Process the landmarks and get updates
  const result = pushupGrader.processPose(landmarks);
  
  // Update UI based on result
  if (result.repIncrement > 0) {
    // Increment rep count in UI
    setRepCount(prevCount => prevCount + result.repIncrement);
  }
  
  // Display form feedback if provided
  if (result.formFault) {
    showFormFeedback(result.formFault);
  }
  
  // Update form score if available
  if (result.formScore !== undefined) {
    updateFormScore(result.formScore);
  }
}

// Reset when starting a new session
function resetExercise() {
  pushupGrader.reset();
  setRepCount(0);
  // Reset other UI state
}
```

### Using the Grader Manager

```typescript
import { ExerciseGraderManager, ExerciseType } from '@/grading';

// Create a manager that holds all exercise graders
const graderManager = new ExerciseGraderManager();

// Get the appropriate grader based on selected exercise
function selectExercise(exerciseType: ExerciseType) {
  const grader = graderManager.getGrader(exerciseType);
  
  // Configure exercise-specific UI and tracking
  // ...
  
  return grader;
}
```

### Running Exercise (Special Case)

```typescript
import { RunningGrader, RunningData } from '@/grading';

const runningGrader = new RunningGrader();

// Update with GPS and timing data
function updateRunningMetrics(distance: number, duration: number, coordinates: any[]) {
  const data: RunningData = {
    distance, // in meters
    duration, // in seconds
    coordinates
  };
  
  const result = runningGrader.updateRunningData(data);
  
  // Update UI
  updatePaceDisplay(runningGrader.getPace());
  updateDistanceDisplay(runningGrader.getDistance());
  // ...
}

// When run is complete
function finishRun() {
  const finalResult = runningGrader.completeRun();
  displayFinalScore(runningGrader.getScore());
  // Save results, etc.
}
```

## Design

This module follows these principles:

1. **Separation of Concerns**: Grading logic is separated from UI and camera handling
2. **Encapsulation**: Each grader encapsulates all logic specific to an exercise
3. **Consistency**: All graders follow the same interface for uniform integration
4. **Testability**: Logic can be tested independently of UI components
5. **Parity with iOS**: Structure mirrors the iOS app's Grading module

Each grader maintains its own internal state (current position in the exercise repetition) and evaluation criteria (angle thresholds, form requirements) specific to that exercise. 