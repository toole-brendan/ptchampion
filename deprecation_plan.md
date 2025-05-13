# AppTheme Deprecation Plan - Progress Update

## Current Status ✓

All direct references to the legacy styling system have been replaced with the modern styling system:

- ✓ `AppTheme.GeneratedColors.*` → `Color.*`  
- ✓ `AppTheme.GeneratedRadius.*` → `CornerRadius.*`  
- ✓ `AppTheme.GeneratedTypography.*` → `Typography.*`  
- ✓ `AppTheme.GeneratedSpacing.*` → `Spacing.*`
- ✓ `AppTheme.GeneratedShadows.*` → `Shadow.*`

Components in PTDesignSystem also updated:
- ✓ `PTTextField`
- ✓ `PTButton`
- ✓ `PTCard` 

## Remaining Tasks

1. **Verify Application Behavior**:
   - Run the application and verify that all styling is correctly applied
   - Test in both light and dark mode
   - Run snapshot tests to ensure visual consistency

2. **Add Container Modifiers**: 
   - Verify that all screen-level views have a `.container()` modifier applied

3. **Clean up Backup Directories**:
   - Remove the `Views_backup_*` directories to prevent confusion with legacy code

4. **Test Appearance Settings**: 
   - Verify that theme switching in `SettingsView.swift` still functions correctly

## Deprecation Timeline

1. **Now**: Marked AppTheme files as deprecated
   - Added `// DEPRECATED: This will be removed in the next major version.` to relevant files:
     - `PTDesignSystem/Sources/DesignTokens/AppTheme.swift`
     - `PTDesignSystem/Sources/DesignTokens/AppTheme+Legacy.swift`

2. **Next Sprint**: Remove legacy AppTheme from new code
   - When new components are created, ensure they exclusively use the modern styling system
   - Add linter warnings for new usage of AppTheme (if appropriate tooling exists)

3. **Future Release**: Remove AppTheme completely
   - Delete the AppTheme files:
     - `PTDesignSystem/Sources/DesignTokens/AppTheme.swift`
     - `PTDesignSystem/Sources/DesignTokens/AppTheme+Legacy.swift`
     - `Generated/AppTheme+Generated.swift`
   - Remove the AppTheme product from Package.swift
   - Run tests and fix any remaining issues

## Checklist Before Final Removal

- [x] All views in `Views` directory are free of AppTheme references
- [x] All PT components in `PTDesignSystem` use modern styling system
- [ ] All views tested in both light and dark mode
- [ ] All accessibility features verified to work correctly
- [ ] Snapshot tests pass with new styling
- [ ] App builds and runs with no warnings related to styling
- [ ] Release notes updated to document the styling system change 