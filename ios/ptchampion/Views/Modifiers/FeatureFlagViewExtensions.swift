import SwiftUI
// Import FeatureFlagService to access FeatureFlag enum and service
import Foundation

/// Convenience extensions for applying feature flags to SwiftUI views
extension View {
    /// Conditionally render content based on a feature flag
    func featureFlag(_ flag: FeatureFlag, defaultValue: Bool = false) -> some View {
        let service = FeatureFlagService.shared
        return self.opacity(service.isEnabled(flag, defaultValue: defaultValue) ? 1 : 0)
            .frame(height: service.isEnabled(flag, defaultValue: defaultValue) ? nil : 0)
            .disabled(!service.isEnabled(flag, defaultValue: defaultValue))
    }

    /// Apply a view modifier conditionally based on a feature flag
    /// - Parameters:
    ///   - flag: The feature flag to check
    ///   - modifier: The view modifier to apply if the flag is enabled
    /// - Returns: Modified view if flag is enabled, otherwise the original view
    func ifFeatureEnabled<T: View>(_ flag: FeatureFlag, modifier: @escaping (Self) -> T) -> some View {
        Group {
            if FeatureFlagService.shared.isEnabled(flag) {
                modifier(self)
            } else {
                self
            }
        }
    }
} 