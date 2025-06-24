# Local Grading Implementation Plan for Web Module

## Progress Update (2025-06-24)
**Phase 1 & 2 Complete!** ✅ 

### Phase 1 - Exercise Graders ✅
- ✅ BaseGrader infrastructure with state management, form scoring, and calibration
- ✅ PushupGrader with adaptive arm extension calibration and state machine
- ✅ SitupGrader with elbow-to-knee validation and shoulder blade grounding
- ✅ PullupGrader with dead hang detection and anti-kipping validation
- ✅ RunningGrader with GPS tracking and pace monitoring

### Phase 2 - UI Integration ✅
- ✅ Updated all ViewModels to use new graders
- ✅ Created unified WorkoutSession component
- ✅ Added problem joint highlighting in pose visualization
- ✅ Real-time form feedback and scoring

Next: Phase 3 - Offline Support & Data Sync

## Overview
This document outlines the implementation plan for moving exercise grading logic to the client-side in the web module, aligning with the iOS app's architecture. All form analysis, rep counting, and scoring will happen locally on the user's device, with only final results sent to the backend.

## Goals
1. **Performance**: Provide real-time feedback without network latency
2. **Privacy**: Keep video/pose data on-device
3. **Consistency**: Match iOS grading logic and scores
4. **Scalability**: Reduce server load by processing on edge devices
5. **Offline Support**: Allow workouts without internet connection

## Architecture Overview

```
Client-Side (Browser)                    Server-Side (Backend)
┌─────────────────────┐                 ┌──────────────────┐
│  Camera/MediaPipe   │                 │                  │
│         ↓           │                 │   Store Results  │
│   Pose Detection    │                 │   Only:          │
│         ↓           │                 │   - repetitions  │
│   Form Analyzer     │                 │   - grade        │
│         ↓           │                 │   - form_score   │
│   Exercise Grader   │                 │   - completed_at │
│         ↓           │                 │                  │
│   Rep Counting &    │     Final       │                  │
│   Score Calculation │ ───Results───→  │   Database       │
│         ↓           │                 │                  │
│   Real-time UI      │                 │                  │
└─────────────────────┘                 └──────────────────┘
```

## Valid Rep Determination Logic

### Push-ups Valid Rep Criteria

A valid push-up rep requires completing all phases with proper form:

```typescript
// Push-up State Machine
enum PushupPhase {
  UP = 'up',           // Starting position - arms extended
  DESCENDING = 'descending',  // Going down
  ASCENDING = 'ascending'     // Coming back up
}

// Valid Rep Requirements:
1. UP Phase (Starting Position):
   - Arms extended: elbow angle > 150° (adjustable via calibration)
   - Body straight: alignment angle < 25° from vertical
   - Ready to descend

2. DESCENDING Phase:
   - Upper arms reach parallel to ground: elbow angle ≤ 100°
   - Body remains straight throughout
   - Sufficient descent: vertical movement > 1.5% of frame height
   - No sagging or piking

3. ASCENDING Phase:
   - Return to full arm extension: elbow angle > 150°
   - Body alignment maintained
   - Return to starting height (within 2% tolerance)
   - Complete the full range of motion

// Sample Implementation
class PushupGrader {
  private validateRep(analysis: PushupFormAnalysis): boolean {
    // Must complete full cycle: UP → DESCENDING → ASCENDING → UP
    const completedFullCycle = this.hasCompletedFullCycle();
    
    // No critical form faults during rep
    const noFormFaults = !analysis.isBodySagging && 
                        !analysis.isBodyPiking && 
                        !analysis.isWorming &&
                        !analysis.handsLiftedOff && 
                        !analysis.feetLiftedOff &&
                        !analysis.kneesTouchingGround && 
                        !analysis.bodyTouchingGround &&
                        !analysis.isPaused;
    
    // Reached proper depth (elbow angle ≤ 90° at bottom)
    const reachedProperDepth = analysis.minElbowAngleDuringRep <= 90;
    
    return completedFullCycle && noFormFaults && reachedProperDepth;
  }
}
```

### Pull-ups Valid Rep Criteria

A valid pull-up rep requires dead hang start and chin over bar:

```typescript
// Pull-up State Machine
enum PullupPhase {
  DOWN = 'down',       // Dead hang position
  PULLING = 'pulling', // Pulling up
  LOWERING = 'lowering' // Returning to dead hang
}

// Valid Rep Requirements:
1. DOWN Phase (Dead Hang):
   - Arms fully extended: elbow angle > 160°
   - Chin clearly below bar: chin position > bar + 5cm
   - Body stable (no excessive swinging)

2. PULLING Phase:
   - Chin passes over bar: chin position < bar - 2cm
   - Arms significantly bent: elbow angle < 120°
   - No kipping (knee angle change < 20°)
   - No excessive swing (horizontal drift < 10cm)

3. LOWERING Phase:
   - Controlled descent back to dead hang
   - Must reach full arm extension again
   - Complete the movement without dropping

// Sample Implementation
class PullupGrader {
  private validateRep(analysis: PullupFormAnalysis): boolean {
    // Must complete full cycle: DOWN → PULLING → LOWERING → DOWN
    const completedFullCycle = this.hasCompletedFullCycle();
    
    // Critical requirements
    const startedFromDeadHang = this.startedWithArmsExtended;
    const chinClearedBar = analysis.chinClearsBar;
    const returnedToDeadHang = analysis.isElbowLocked;
    
    // No form violations
    const noKipping = !analysis.isKipping;
    const noSwinging = !analysis.isSwinging;
    const notPaused = !analysis.isPaused;
    
    return completedFullCycle && 
           startedFromDeadHang && 
           chinClearedBar && 
           returnedToDeadHang &&
           noKipping && 
           noSwinging && 
           notPaused;
  }
}
```

### Sit-ups Valid Rep Criteria

A valid sit-up rep requires proper form throughout the movement:

```typescript
// Sit-up State Machine
enum SitupPhase {
  DOWN = 'down',       // Shoulders on ground
  RISING = 'rising',   // Sitting up
  LOWERING = 'lowering' // Returning down
}

// Valid Rep Requirements:
1. DOWN Phase (Starting Position):
   - Shoulder blades touch ground: shoulder Y ≈ initial calibration
   - Knees at 90° angle: knee angle 80°-100°
   - Hands behind head (interlocked fingers)
   - Feet remain on ground

2. RISING Phase:
   - Torso reaches vertical: trunk angle > 75° from horizontal
   - Elbows touch/pass knees (or get within proximity)
   - Hips remain on ground (no lifting)
   - Hands stay behind head

3. LOWERING Phase:
   - Controlled descent back down
   - Shoulder blades must touch ground again
   - Maintain knee angle throughout

// Sample Implementation
class SitupGrader {
  private validateRep(analysis: SitupFormAnalysis): boolean {
    // Must complete full cycle: DOWN → RISING → LOWERING → DOWN
    const completedFullCycle = this.hasCompletedFullCycle();
    
    // Position requirements
    const shoulderBladesTouchedGround = this.touchedGroundAtBottom;
    const reachedVerticalPosition = this.reachedVerticalAtTop;
    
    // Form requirements throughout rep
    const handsStayedBehindHead = analysis.isHandPositionCorrect;
    const kneeAngleMaintained = analysis.isKneeAngleCorrect;
    const hipsStayedDown = analysis.isHipStable;
    const notPaused = !analysis.isPaused;
    
    // For strict military standard, add elbow-to-knee requirement
    const elbowsReachedKnees = analysis.trunkAngle >= 70; // Approximation
    
    return completedFullCycle && 
           shoulderBladesTouchedGround && 
           reachedVerticalPosition &&
           handsStayedBehindHead && 
           kneeAngleMaintained && 
           hipsStayedDown && 
           notPaused &&
           elbowsReachedKnees;
  }
}
```

### Key Implementation Principles

1. **State Machine Approach**: Each exercise uses a state machine to track progression through the movement phases
2. **Full Range of Motion**: Reps only count if they complete the full movement cycle
3. **Form Integrity**: Any critical form fault invalidates the rep
4. **Calibration**: Initial frames calibrate to user's body proportions
5. **Tolerance Thresholds**: Small tolerances account for natural movement variation and pose detection noise

### Adaptive Thresholds (from iOS)

```typescript
// Example from iOS: Adaptive calibration for user comfort
class AdaptiveThresholds {
  private pushupArmExtension = 160; // Starting threshold
  private calibrationFrames = 0;
  
  updateCalibration(currentArmAngle: number): void {
    if (this.calibrationFrames < 30 && 
        currentArmAngle > 140 && 
        currentArmAngle < 170) {
      // Gradually adjust to user's natural extension
      const weight = 0.1;
      this.pushupArmExtension = 
        this.pushupArmExtension * (1 - weight) + 
        currentArmAngle * weight;
      this.calibrationFrames++;
    }
  }
}
```

## Implementation Tasks

### Phase 1: Create Exercise Graders (Week 1) ✅

#### 1.1 Create Base Grader Infrastructure ✅
- [x] Create `/web/src/grading/graders/` directory
- [x] Implement `BaseGrader.ts` abstract class with common functionality
- [x] Define grader state management interface
- [x] Add grader factory pattern for exercise type selection

#### 1.2 Implement PushupGrader ✅
- [x] Create `PushupGrader.ts` that uses existing `PushupAnalyzer`
- [x] Implement rep counting logic with state machine
- [x] Add form quality tracking throughout rep
- [x] Calculate average form score per workout
- [ ] Add unit tests for rep counting edge cases

#### 1.3 Implement SitupGrader ✅
- [x] Create `SitupGrader.ts` using `SitupAnalyzer`
- [x] Define sit-up completion criteria (elbow to knee)
- [x] Implement proper form validation
- [x] Track form faults (hands apart, hip lifting, etc.)
- [ ] Add unit tests

#### 1.4 Implement PullupGrader ✅
- [x] Create `PullupGrader.ts` using `PullupAnalyzer`
- [x] Implement dead hang detection
- [x] Add chin-over-bar validation
- [x] Track swinging/kipping violations
- [ ] Add unit tests

#### 1.5 Implement RunningGrader ✅
- [x] Create `RunningGrader.ts` for GPS-based tracking
- [x] Implement distance/time calculation
- [x] Add pace tracking
- [x] Calculate scores based on 2-mile time
- [ ] Add unit tests

### Phase 2: Update UI Components (Week 2) ✅

#### 2.1 Refactor Exercise Trackers ✅
- [x] Update `PushupTracker.tsx` to use `PushupGrader`
- [x] Update `SitupTracker.tsx` to use `SitupGrader`
- [x] Update `PullupTracker.tsx` to use `PullupGrader`
- [x] Update `RunningTracker.tsx` to use `RunningGrader`

#### 2.2 Create Unified Workout Component ✅
- [x] Create `WorkoutSession.tsx` component
- [x] Add exercise type selection
- [x] Implement grader initialization
- [x] Add real-time feedback display
- [x] Show rep count, form score, and current feedback

#### 2.3 Add Visual Feedback ✅
- [x] Highlight problem joints in pose overlay

### Phase 3: Offline Support & Data Sync (Week 3)

#### 3.1 Implement Offline Queue
- [ ] Create `OfflineQueue.ts` service
- [ ] Use IndexedDB for local storage
- [ ] Queue workout results when offline
- [ ] Implement sync mechanism on reconnection
- [ ] Add conflict resolution for duplicate submissions

#### 3.2 Update API Integration
- [ ] Modify workout submission to use queue
- [ ] Add retry logic with exponential backoff
- [ ] Handle partial sync failures
- [ ] Add sync status indicator in UI

#### 3.3 Add Progressive Web App Features
- [ ] Create service worker for offline caching
- [ ] Cache grading logic and UI assets
- [ ] Enable background sync
- [ ] Add offline mode indicator

### Phase 4: Testing & Validation (Week 4)

#### 4.1 Unit Testing
- [ ] Test each grader with various pose sequences
- [ ] Verify rep counting accuracy
- [ ] Test form fault detection
- [ ] Validate score calculations match APFT tables

#### 4.2 Integration Testing
- [ ] Test full workout flow offline/online
- [ ] Verify data sync after reconnection
- [ ] Test across different devices/browsers
- [ ] Validate MediaPipe performance

#### 4.3 Cross-Platform Validation
- [ ] Compare scores with iOS app
- [ ] Ensure consistent rep counting
- [ ] Validate form detection thresholds
- [ ] Test with users of different body types

### Phase 5: Backend Updates (Week 5)

#### 5.1 Simplify Backend Logic
- [ ] Remove grading logic from backend
- [ ] Update API to accept pre-calculated grades
- [ ] Add validation for grade ranges (0-100)
- [ ] Remove unnecessary grading endpoints

#### 5.2 Update Database Schema
- [ ] Ensure schema supports client-calculated grades
- [ ] Add indexes for performance
- [ ] Update migration scripts if needed
- [ ] Document schema changes

#### 5.3 API Documentation
- [ ] Update OpenAPI spec
- [ ] Document new workout submission format
- [ ] Add examples for each exercise type
- [ ] Update API client libraries

### Phase 6: Performance Optimization (Week 6)

#### 6.1 Optimize Grader Performance
- [ ] Profile grader CPU usage
- [ ] Optimize angle calculations
- [ ] Reduce memory allocations
- [ ] Add frame skipping for low-end devices

#### 6.2 Bundle Size Optimization
- [ ] Code split graders by exercise type
- [ ] Lazy load MediaPipe models
- [ ] Tree shake unused code
- [ ] Minimize grading logic bundle

#### 6.3 Battery Usage
- [ ] Add power-saving mode option
- [ ] Reduce camera resolution on battery
- [ ] Throttle processing on low battery
- [ ] Add battery level warnings

## Technical Specifications

### Grader Interface
```typescript
interface ExerciseGrader {
  // Process a single pose frame
  processPose(landmarks: NormalizedLandmark[]): GradingResult;
  
  // Get current state
  getRepCount(): number;
  getFormScore(): number;
  getAPFTScore(): number;
  
  // Reset for new workout
  reset(): void;
}

interface GradingResult {
  state: ExerciseState;
  repIncrement: number;
  formScore?: number;
  formFault?: string;
  hasFormFault: boolean;
}
```

### Workout Submission Format
```typescript
interface WorkoutSubmission {
  exercise_type: 'pushup' | 'situp' | 'pullup' | 'run';
  repetitions?: number;      // For rep-based exercises
  duration_seconds?: number;  // For time-based exercises
  grade: number;             // APFT score (0-100)
  form_score?: number;       // Average form quality (0-100)
  completed_at: string;      // ISO timestamp
  is_public: boolean;        // For leaderboard
}
```

### Offline Queue Schema
```typescript
interface QueuedWorkout {
  id: string;               // UUID
  workout: WorkoutSubmission;
  timestamp: number;        // Unix timestamp
  retryCount: number;
  lastError?: string;
}
```

## Success Metrics

1. **Performance**
   - Real-time feedback latency < 100ms
   - Smooth 30fps pose tracking
   - Bundle size < 500KB for grading logic

2. **Accuracy**
   - 95%+ rep counting accuracy vs manual count
   - Form detection matches military standards
   - Scores match iOS app within 2%

3. **User Experience**
   - Works offline without degradation
   - Clear, actionable form feedback
   - Consistent experience across devices

4. **Technical**
   - 100% client-side processing
   - Zero grading logic on backend
   - Automatic sync when online

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Browser performance varies | Poor UX on low-end devices | Add quality settings, frame skipping |
| MediaPipe accuracy issues | Incorrect rep counting | Tune thresholds, add manual override |
| Large bundle size | Slow initial load | Code splitting, lazy loading |
| Offline sync conflicts | Lost workout data | Conflict resolution, local backup |
| Different results than iOS | User confusion | Extensive cross-platform testing |

## Timeline

- **Week 1**: Core grader implementation
- **Week 2**: UI integration
- **Week 3**: Offline support
- **Week 4**: Testing & validation
- **Week 5**: Backend updates
- **Week 6**: Performance optimization

Total estimated time: 6 weeks for full implementation

## Dependencies

- MediaPipe Pose Detection (already integrated)
- IndexedDB for offline storage
- Service Worker API for background sync
- Web Workers for computation offloading (optional)

## Open Questions

1. Should we support manual rep count override?
2. How to handle partial reps at workout end?
3. Should form threshold be configurable?
4. How long to retain offline queue data?
5. Should we add exercise tutorials/demos?

## Next Steps

1. Review and approve this plan
2. Create feature branch: `feature/local-grading`
3. Set up tracking issues for each phase
4. Begin Phase 1 implementation
5. Weekly progress reviews

---

*Document created: 2024-01-24*  
*Last updated: 2024-01-24*  
*Status: DRAFT - Pending Review*