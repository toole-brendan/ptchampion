import SwiftUI
import DesignTokens

// MARK: - Global design-system color helpers
public typealias DSColor = DesignTokens.ThemeColor
public typealias SColor = SwiftUI.Color

// Ensure these are available at module level for all views
// This prevents the need for duplicate definitions while maintaining backward compatibility 