# Client-Side Grading API Documentation

## Overview

As of the local grading implementation (Phase 5), PT Champion has moved all exercise grading logic to the client side. The backend now accepts pre-calculated grades from clients, which are computed using computer vision and device sensors on the user's device.

## Key Changes

### Before (Server-Side Grading)
- Clients sent raw exercise data (reps/duration)
- Server calculated APFT scores based on reps/duration
- No form quality tracking

### After (Client-Side Grading)
- Clients calculate APFT scores locally using MediaPipe pose detection
- Clients send pre-calculated grades along with exercise data
- Form quality scores are tracked and stored separately

## Workout Submission API

### POST /api/v1/workouts

Submit a completed workout with client-calculated grades.

#### Request Body

```json
{
  "exercise_id": 1,
  "exercise_type": "pushup",
  "repetitions": 42,
  "duration_seconds": null,
  "grade": 85,
  "form_score": 92,
  "is_public": true,
  "completed_at": "2025-06-24T15:30:00Z"
}
```

#### Field Descriptions

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `exercise_id` | integer | Yes | ID of the exercise type (1=pushup, 2=situp, 3=pullup, 4=run) |
| `exercise_type` | string | Yes | Type of exercise: "pushup", "situp", "pullup", or "run" |
| `repetitions` | integer | Conditional | Number of reps completed (required for pushup, situp, pullup) |
| `duration_seconds` | integer | Conditional | Duration in seconds (required for run) |
| `grade` | integer | Yes | APFT score (0-100) calculated by client |
| `form_score` | integer | No | Form quality score (0-100) from pose analysis |
| `is_public` | boolean | No | Whether workout appears on leaderboard (default: false) |
| `completed_at` | string | Yes | ISO 8601 timestamp when workout was completed |

#### Validation Rules

1. **Grade Range**: Must be between 0 and 100
2. **Form Score Range**: If provided, must be between 0 and 100
3. **Exercise Requirements**:
   - Rep-based exercises (pushup, situp, pullup) must include `repetitions`
   - Time-based exercise (run) must include `duration_seconds`
4. **Exercise Type**: Must match the exercise_id's type in the database

#### Response

```json
{
  "id": 12345,
  "user_id": 100,
  "exercise_id": 1,
  "exercise_name": "Push-ups",
  "exercise_type": "pushup",
  "reps": 42,
  "duration_seconds": null,
  "form_score": 92,
  "grade": 85,
  "is_public": true,
  "completed_at": "2025-06-24T15:30:00Z",
  "created_at": "2025-06-24T15:31:00Z"
}
```

## Grade Calculation

Grades are calculated on the client using the following approach:

### 1. Pose Detection
- MediaPipe extracts 33 pose landmarks from camera frames
- Landmarks are processed in real-time on device

### 2. Exercise Analysis
- Each exercise has specific form requirements
- Analyzers calculate joint angles and positions
- State machines track movement phases

### 3. Rep Validation
- Only reps with proper form are counted
- Each exercise has specific validation criteria
- Form faults are detected and tracked

### 4. APFT Scoring
- Final rep count is converted to APFT score (0-100)
- Scoring tables match official Army standards
- Age and gender adjustments are applied client-side

### 5. Form Scoring
- Average form quality throughout workout
- Based on deviations from ideal form
- Stored separately from APFT grade

## Example Implementations

### JavaScript/TypeScript (Web)
```typescript
import { workoutSyncService } from './services/WorkoutSyncService';
import { convertToWorkoutRequest } from './services/workoutHelpers';

// After completing a pushup workout
const workoutRequest = {
  exercise_type: 'pushup',
  repetitions: 42,
  grade: 85,  // Calculated by PushupGrader
  form_score: 92,  // Average form quality
  completed_at: new Date().toISOString(),
  is_public: true
};

await workoutSyncService.submitWorkout(workoutRequest);
```

### Swift (iOS)
```swift
let workout = WorkoutRequest(
    exerciseType: "pushup",
    repetitions: 42,
    grade: 85,
    formScore: 92,
    completedAt: Date(),
    isPublic: true
)

APIClient.shared.submitWorkout(workout) { result in
    // Handle response
}
```

## Offline Support

The web client includes automatic offline support:

1. **Offline Detection**: Workouts are automatically queued when offline
2. **Local Storage**: Uses IndexedDB to store pending workouts
3. **Auto-Sync**: Syncs when connection is restored
4. **Retry Logic**: Exponential backoff for failed submissions
5. **Duplicate Prevention**: Checks for duplicates before syncing

## Migration Notes

For clients upgrading from server-side grading:

1. **Add Grading Logic**: Implement local APFT scoring tables
2. **Include Grade Field**: Add `grade` to workout submissions
3. **Remove Server Calculation**: Don't expect grade in response
4. **Add Form Tracking**: Optionally track form quality
5. **Handle Offline**: Implement queuing for offline support

## Security Considerations

1. **Grade Validation**: Server validates grades are 0-100
2. **No Override**: Server doesn't recalculate grades
3. **Trust Model**: System trusts client calculations
4. **Audit Trail**: All submissions are logged with metadata

## Benefits

1. **Performance**: Real-time feedback without network latency
2. **Privacy**: Video data never leaves device
3. **Offline**: Works without internet connection
4. **Scalability**: Reduces server computational load
5. **Accuracy**: Direct access to sensor data

---

*Last updated: 2025-06-24*
*Part of PT Champion Local Grading Implementation*