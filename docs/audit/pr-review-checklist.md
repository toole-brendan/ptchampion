# PT Champion Pull Request Review Checklist

This checklist is to be used when reviewing PRs to ensure code quality and prevent reintroduction of legacy patterns.

## General Checks

- [ ] Code follows consistent naming conventions
- [ ] Component organization follows project structure
- [ ] Imports are properly organized
- [ ] Comments are clear and necessary
- [ ] Unit tests are included where appropriate
- [ ] Performance considerations have been made

## Legacy Code Prevention

### No Backup Import References

- [ ] No imports from `src/backup/` folder
- [ ] No manual MediaPipe initialization in pages/components
- [ ] No usage of deprecated `usePoseDetector` hook
- [ ] No duplicate constants that should be in the grader/analyzer files

### Proper Architecture Implementation

- [ ] Exercise tracking uses ViewModel pattern
- [ ] Form analysis uses appropriate Analyzer/Grader class
- [ ] Shared math utilities used instead of local implementations
- [ ] Exercise-specific constants defined in the appropriate Analyzer/Grader file
- [ ] All `TODO(legacy-cleanup)` comments have been addressed

## Feature Requirements

- [ ] Feature works as intended
- [ ] Mobile and desktop UI is properly responsive
- [ ] Feature works in offline mode where appropriate
- [ ] Error handling is properly implemented
- [ ] Feature includes appropriate loading states

## Security & Performance

- [ ] No sensitive data exposed or logged to console
- [ ] Avoid unnecessary re-renders (memoization where appropriate)
- [ ] Large assets optimized for web
- [ ] API calls are properly authenticated

## Final Verification

- [ ] All existing tests pass (`npm run test`)
- [ ] Build succeeds without errors (`npm run build`)
- [ ] No console warnings or errors during normal operation
- [ ] Manual testing of the feature completed 