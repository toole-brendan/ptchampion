# PT Champion → US Marine Corps PFT Update Plan

## Overview
This document outlines the comprehensive plan to update PT Champion's scoring rubric to align with the official US Marine Corps Physical Fitness Test (PFT) standards as defined in Marine Corps Order 6100.13A (Change 4, 2022).

## Current State Analysis

### PT Champion Current Exercises
Based on the codebase structure, PT Champion currently supports:
- **Pull-ups** (with pose detection and grading)
- **Push-ups** (with pose detection and grading) 
- **Sit-ups** (with pose detection and grading)
- **Running** (with time tracking)
- **Plank** (with time tracking)

### Current Scoring System
The app currently uses APFT (Army Physical Fitness Test) scoring standards, as evidenced by:
- `APFTScoring.ts` in web/src/grading/
- `APFTRepValidator.swift` in iOS grading system
- Army-based age/gender scoring matrices

## Target: US Marine Corps PFT Standards

### The 4 Marine Corps PFT Events

#### 1. Pull-ups (Primary Upper Body Exercise)
- **Format**: Dead-hang pull-ups, no time limit
- **Scoring**: 100 points maximum, 40 points minimum
- **Gender-specific standards**
- **Age-bracketed scoring** (8 age groups: 17-20, 21-25, 26-30, 31-35, 36-40, 41-45, 46-50, 51+)

#### 2. Push-ups (Alternative Upper Body Exercise)  
- **Format**: Standard push-ups, 2-minute time limit
- **Scoring**: 70 points maximum (not 100!), 40 points minimum
- **Important**: Cannot achieve maximum PFT score if choosing push-ups over pull-ups
- **Gender-specific standards**
- **Age-bracketed scoring**

#### 3. Plank Hold (Core Exercise)
- **Format**: Standard plank pose, timed hold
- **Scoring**: 100 points maximum, 70 points minimum  
- **Universal standards**: Same table for all Marines regardless of age/gender
- **Key times**: 3:45 = 100 points, 2:28 = 70 points (minimum)

#### 4. 3-Mile Run (Cardio Exercise)
- **Format**: Timed 3-mile run
- **Scoring**: 100 points maximum, 40 points minimum
- **Gender-specific standards**
- **Age-bracketed scoring**

## Detailed Scoring Tables

### Pull-ups Scoring Standards

#### Male Marines
| Age Group | Minimum (40 pts) | Maximum (100 pts) |
|-----------|------------------|-------------------|
| 17-20     | 4                | 20                |
| 21-25     | 5                | 23                |
| 26-30     | 5                | 23                |
| 31-35     | 5                | 23                |
| 36-40     | 5                | 21                |
| 41-45     | 5                | 20                |
| 46-50     | 5                | 19                |
| 51+       | 4                | 19                |

#### Female Marines  
| Age Group | Minimum (40 pts) | Maximum (100 pts) |
|-----------|------------------|-------------------|
| 17-20     | 1                | 7                 |
| 21-25     | 3                | 11                |
| 26-30     | 4                | 12                |
| 31-35     | 3                | 11                |
| 36-40     | 3                | 10                |
| 41-45     | 2                | 8                 |
| 46-50     | 2                | 6                 |
| 51+       | 2                | 4                 |

### Push-ups Scoring Standards

#### Male Marines
| Age Group | Minimum (40 pts) | Maximum (70 pts) |
|-----------|------------------|------------------|
| 17-20     | 42               | 82               |
| 21-25     | 40               | 87               |
| 26-30     | 39               | 84               |
| 31-35     | 36               | 80               |
| 36-40     | 34               | 76               |
| 41-45     | 30               | 72               |
| 46-50     | 25               | 68               |
| 51+       | 20               | 64               |

#### Female Marines
| Age Group | Minimum (40 pts) | Maximum (70 pts) |
|-----------|------------------|------------------|
| 17-20     | 19               | 42               |
| 21-25     | 18               | 48               |
| 26-30     | 18               | 50               |
| 31-35     | 16               | 46               |
| 36-40     | 14               | 43               |
| 41-45     | 12               | 41               |
| 46-50     | 11               | 40               |
| 51+       | 10               | 38               |

### Plank Hold Scoring Standards (Universal)
| Time (mm:ss) | Points |
|--------------|---------|
| 3:45         | 100     |
| 3:30         | 94      |
| 3:00         | 84      |
| 2:28         | 70      |

*Note: Full interpolation table needed for implementation*

### 3-Mile Run Scoring Standards

#### Male Marines
| Age Group | Minimum (40 pts) | Maximum (100 pts) |
|-----------|------------------|-------------------|
| 17-20     | 27:40            | 18:00             |
| 21-25     | 27:40            | 18:00             |
| 26-30     | 28:00            | 18:00             |
| 31-35     | 28:20            | 18:00             |
| 36-40     | 28:40            | 18:00             |
| 41-45     | 29:20            | 18:30             |
| 46-50     | 30:00            | 19:00             |
| 51+       | 33:00            | 19:30             |

#### Female Marines
| Age Group | Minimum (40 pts) | Maximum (100 pts) |
|-----------|------------------|-------------------|
| 17-20     | 30:50            | 21:00             |
| 21-25     | 30:50            | 21:00             |
| 26-30     | 31:10            | 21:00             |
| 31-35     | 31:30            | 21:00             |
| 36-40     | 31:50            | 21:00             |
| 41-45     | 32:30            | 21:30             |
| 46-50     | 33:30            | 22:00             |
| 51+       | 36:00            | 22:30             |

## Implementation Plan

### Phase 1: Backend Scoring System Update

#### 1.1 Create Marine Corps Scoring Module
**Files to Create/Update:**
- `shared/schema.ts` - Add Marine Corps PFT scoring types
- `internal/grading/usmc_scoring.go` - New Marine Corps scoring engine
- `sql/migrations/` - Database schema for Marine Corps standards

**Key Components:**
```typescript
interface USMCPFTStandards {
  pullups: AgeGenderMatrix;
  pushups: AgeGenderMatrix; 
  plank: UniversalTimeMatrix;
  run3Mile: AgeGenderMatrix;
}

interface AgeGenderMatrix {
  male: Record<AgeGroup, ScoreRange>;
  female: Record<AgeGroup, ScoreRange>;
}

type AgeGroup = '17-20' | '21-25' | '26-30' | '31-35' | '36-40' | '41-45' | '46-50' | '51+';
```

#### 1.2 Update Grading Engines
**Files to Update:**
- Replace `internal/grading/apft_*.go` with `internal/grading/usmc_*.go`
- Update scoring calculation logic for Marine Corps standards
- Implement special push-up scoring (max 70 points, not 100)

#### 1.3 Database Schema Updates
- Add `scoring_system` field to user profiles (ARMY/USMC)
- Create Marine Corps scoring lookup tables
- Migration scripts to convert existing Army scores

### Phase 2: Mobile App Updates (iOS)

#### 2.1 Scoring System Integration
**Files to Update:**
- `ios/ptchampion/Models/WorkoutModels.swift` - Add USMC scoring enums
- `ios/ptchampion/Grading/ScoreRubrics.swift` - Replace with Marine Corps rubrics
- Remove `APFTRepValidator.swift` files, create `USMCRepValidator.swift`

#### 2.2 UI Updates
**Files to Update:**
- `ios/ptchampion/Views/Scoring/` - Update all rubric views for Marine Corps standards
- `ios/ptchampion/Views/Dashboard/DashboardView.swift` - Update scoring displays
- `ios/ptchampion/Views/Workouts/WorkoutCompleteView.swift` - Show Marine Corps scores

#### 2.3 Exercise Flow Updates
- Update exercise selection to show Marine Corps PFT exercises
- Modify plank timer for Marine Corps standards (3:45 max vs current)
- Update 3-mile run tracking (vs current 2-mile)

### Phase 3: Web App Updates

#### 3.1 Scoring System Integration  
**Files to Update:**
- `web/src/grading/APFTScoring.ts` → `web/src/grading/USMCScoring.ts`
- `web/src/grading/ExerciseGrader.ts` - Update for Marine Corps standards
- `web/src/lib/types.ts` - Add Marine Corps scoring types

#### 3.2 Component Updates
**Files to Update:**
- `web/src/pages/rubrics/` - All rubric pages need Marine Corps data
- `web/src/components/WorkoutChart.tsx` - Update scoring visualization
- `web/src/pages/Dashboard.tsx` - Display Marine Corps scores
- `web/src/pages/exercises/` - Update all exercise trackers

#### 3.3 UI/UX Updates
- Update exercise selection interface
- Modify scoring displays and charts
- Update progress tracking for Marine Corps standards

### Phase 4: Testing & Validation

#### 4.1 Unit Tests
- Create comprehensive test suites for Marine Corps scoring
- Test age/gender matrix calculations
- Validate score interpolation accuracy
- Test push-up max score limitation (70 points)

#### 4.2 Integration Tests  
- End-to-end workout scoring validation
- Cross-platform scoring consistency (iOS/Web)
- Database migration testing

#### 4.3 User Acceptance Testing
- Marine Corps veterans validation
- Scoring accuracy verification against official tables
- Performance testing with new scoring calculations

## Technical Considerations

### 1. Backward Compatibility
- Maintain Army scoring for existing users who prefer APFT
- Add user preference setting for scoring system
- Preserve historical workout data with original scoring system

### 2. Data Migration
- Convert existing Army scores to Marine Corps equivalents where possible
- Flag converted scores vs. native Marine Corps scores
- Preserve raw performance data for re-scoring

### 3. Performance Optimization
- Pre-calculate scoring matrices for faster lookups
- Cache scoring calculations
- Optimize database queries for age/gender filtering

### 4. Internationalization
- Prepare for future international PT test standards
- Modular scoring system architecture
- Configurable scoring systems per user preference

## Implementation Timeline

### Week 1-2: Research & Planning
- ✅ Complete Marine Corps standards research
- ✅ Create implementation plan
- Define detailed technical specifications
- Set up development environment

### Week 3-4: Backend Implementation
- Create Marine Corps scoring engine
- Database schema updates and migrations
- Backend API updates
- Unit test development

### Week 5-6: iOS App Updates
- Update scoring models and validators
- UI component updates
- Exercise flow modifications
- iOS testing

### Week 7-8: Web App Updates  
- Frontend scoring system updates
- Component and page updates
- Web app testing
- Cross-platform integration testing

### Week 9-10: Testing & Polish
- Comprehensive testing
- Bug fixes and optimizations
- User acceptance testing
- Documentation updates

### Week 11-12: Deployment & Monitoring
- Production deployment
- User migration support
- Performance monitoring
- Feedback collection and iteration

## Success Metrics

### Accuracy Metrics
- 100% accuracy against official Marine Corps scoring tables
- Zero scoring discrepancies between iOS and web platforms
- Successful migration of existing user data

### User Experience Metrics
- Maintain current app performance benchmarks
- User satisfaction scores ≥ 4.5/5.0
- Reduced support tickets related to scoring questions

### Technical Metrics
- All unit tests passing (target: >95% coverage)
- Integration tests passing (target: 100%)
- Production stability maintained

## Risk Mitigation

### Technical Risks
- **Complex scoring logic**: Implement comprehensive test suites
- **Performance impact**: Optimize scoring calculations and caching
- **Data migration issues**: Thorough testing and rollback procedures

### User Experience Risks  
- **Change resistance**: Provide clear communication and Army scoring option
- **Confusion**: In-app education and help documentation
- **Historical data loss**: Preserve all original data and scoring

### Business Risks
- **Development timeline**: Agile development with regular checkpoints
- **Quality assurance**: Extensive testing phases and staged rollouts
- **User retention**: Gradual rollout with feedback incorporation

## Resources & References

### Official Sources
- Marine Corps Order 6100.13A (Change 4, 2022)
- Official USMC PFT scoring tables
- Marines.com physical requirements documentation

### Implementation References
- Current PT Champion codebase analysis
- APFT to Marine Corps PFT conversion matrices
- Military fitness testing best practices

---

**Document Status**: Draft v1.0  
**Last Updated**: January 2025  
**Next Review**: After Phase 1 completion 