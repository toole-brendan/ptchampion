import SwiftUI
import PTDesignSystem

// Add this to existing DeveloperMenu or create a new option
struct DesignSystemToggleOption: View {
    @State private var isWebDesignEnabled: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Design System")
                .heading4()
            
            Toggle("Web UI Design System", isOn: $isWebDesignEnabled)
                .onChange(of: isWebDesignEnabled) { newValue in
                    // Set feature flag
                    let featureFlag = FeatureFlag.designSystemV2
                    
                    // Store the flag value both in UserDefaults (for ThemeManager to read)
                    // and in FeatureFlagService
                    UserDefaults.standard.set(newValue, forKey: "useWebTheme")
                    
                    // Optionally capture in mock FeatureFlagService if available
                    if let mockFlags = FeatureFlagService.shared.flags as? NSMutableDictionary {
                        mockFlags[featureFlag.rawValue] = newValue
                    }
                    
                    // Force refresh views by posting notification
                    NotificationCenter.default.post(name: NSNotification.Name("RefreshAppearance"), object: nil)
                }
            
            Text("Restart screens to see changes")
                .caption()
                .foregroundColor(.secondary)
        }
        .padding()
        .onAppear {
            // Initialize toggle state from current setting
            isWebDesignEnabled = FeatureFlagService.shared.isEnabled(.designSystemV2)
        }
    }
} 