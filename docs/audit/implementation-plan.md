# Legacy Code Cleanup Implementation Plan

This document outlines a step-by-step implementation plan to address the findings from the legacy code audit.

## Phase 1: Fix Naming Inconsistencies (Week 1)

### Task 1.1: Standardize Analyzer/Grader Naming Convention

- [ ] Decide on a naming convention: Either all "Analyzer" or all "Grader"
- [ ] Update `grading/index.ts` to match the chosen convention
- [ ] Ensure corresponding imports throughout the codebase are updated

### Task 1.2: Implement Missing ViewModel Classes

- [ ] Create `SitupTrackerViewModel.ts` following the pattern of `PushupTrackerViewModel.ts`
- [ ] Create `PullupTrackerViewModel.ts` following the same pattern
- [ ] Create `RunningTrackerViewModel.ts` following the same pattern
- [ ] Update all imports and references accordingly

## Phase 2: Centralize Constants & Code (Week 2)

### Task 2.1: Migrate Constants to Analyzer/Grader Files

- [ ] Move push-up constants from `PushupTracker.tsx` to `PushupAnalyzer.ts`
- [ ] Move sit-up constants from `SitupTracker.tsx` to `SitupAnalyzer.ts`
- [ ] Move pull-up constants from `PullupTracker.tsx` to `PullupAnalyzer.ts`
- [ ] Export constants from analyzer files and reference them in tracker components

### Task 2.2: Eliminate Duplicate Utility Functions

- [ ] Remove `calculateAngle` from all tracker components
- [ ] Use the centralized version from `mathUtils.ts`
- [ ] Verify that all mathematical operations are consistent

## Phase 3: Refactor Exercise Trackers (Week 3)

### Task 3.1: Refactor PushupTracker.tsx

- [ ] Remove manual MediaPipe initialization
- [ ] Replace with ViewModel integration
- [ ] Remove manual pushup processing logic
- [ ] Use analyzer methods via ViewModel
- [ ] Maintain UI logic and presentation

### Task 3.2: Refactor SitupTracker.tsx

- [ ] Follow the same process as for PushupTracker.tsx
- [ ] Integrate with the new SitupTrackerViewModel

### Task 3.3: Refactor PullupTracker.tsx

- [ ] Follow the same process as for PushupTracker.tsx
- [ ] Integrate with the new PullupTrackerViewModel

### Task 3.4: Refactor RunningTracker.tsx

- [ ] Follow the same process as for PushupTracker.tsx
- [ ] Integrate with the new RunningTrackerViewModel

## Phase 4: Testing and Cleanup (Week 4)

### Task 4.1: Comprehensive Testing

- [ ] Test all exercise types in the web app
- [ ] Verify rep counting works correctly
- [ ] Verify form analysis feedback is accurate
- [ ] Ensure data submission and storage functions correctly

### Task 4.2: Remove Backup Directory

- [ ] After all functionality is verified, remove the backup directory
- [ ] Run build and tests to ensure nothing breaks

### Task 4.3: Update Documentation

- [ ] Create/update architectural documentation
- [ ] Document component relationships
- [ ] Update README with new architecture details

## Phase 5: Prevent Regression (Ongoing)

### Task 5.1: Implement CI Checks

- [ ] Add ESLint rule to prevent imports from unauthorized patterns
- [ ] Add test coverage requirements for critical components
- [ ] Configure automated testing in CI pipeline

### Task 5.2: Code Review Guidelines

- [ ] Update pull request template to include architecture compliance checks
- [ ] Create a checklist for reviewers to ensure architectural consistency

## Estimated Timeline

| Phase | Duration | Dependencies |
|-------|----------|--------------|
| Phase 1 | 1 week | None |
| Phase 2 | 1 week | Phase 1 |
| Phase 3 | 1-2 weeks | Phase 2 |
| Phase 4 | 1 week | Phase 3 |
| Phase 5 | Ongoing | Phase 4 |

## Success Criteria

- All tracker components use their respective ViewModels
- No direct MediaPipe usage in tracker components
- No duplicate constants or utility functions
- Backup directory removed
- All tests passing
- CI checks implemented 