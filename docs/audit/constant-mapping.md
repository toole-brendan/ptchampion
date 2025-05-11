# Constant Mapping Checklist

This file tracks constant values that are duplicated across the codebase and should be centralized in their respective analyzer/grader files.

## Push-ups

| Page Constant | Value | Grader/Analyzer Constant | Status |
|--------------|-------|--------------------------|--------|
| `PUSHUP_THRESHOLD_ANGLE_DOWN` | 90 | To be migrated to `PushupAnalyzer.ts` | ⚠️ Pending |
| `PUSHUP_THRESHOLD_ANGLE_UP` | 160 | To be migrated to `PushupAnalyzer.ts` | ⚠️ Pending |
| `BACK_STRAIGHT_THRESHOLD_ANGLE` | 165 | To be migrated to `PushupAnalyzer.ts` | ⚠️ Pending |
| `PUSHUP_THRESHOLD_VISIBILITY` | 0.6 | To be migrated to `PushupAnalyzer.ts` | ⚠️ Pending |

## Sit-ups

| Page Constant | Value | Grader/Analyzer Constant | Status |
|--------------|-------|--------------------------|--------|
| `SITUP_THRESHOLD_ANGLE_DOWN` | 160 | To be migrated to `SitupAnalyzer.ts` | ⚠️ Pending |
| `SITUP_THRESHOLD_ANGLE_UP` | 80 | To be migrated to `SitupAnalyzer.ts` | ⚠️ Pending |

## Pull-ups

| Page Constant | Value | Grader/Analyzer Constant | Status |
|--------------|-------|--------------------------|--------|
| TBD | | | |

## Running

| Page Constant | Value | Grader/Analyzer Constant | Status |
|--------------|-------|--------------------------|--------|
| TBD | | | |

## Notes

- Constants should be exported from the analyzer/grader files so they can be imported in UI components if needed
- Ideally, UI components should not need to use these constants directly, but rather obtain them through the analyzer/grader API
- If UI needs access to these values (for display purposes), consider creating dedicated getter methods 