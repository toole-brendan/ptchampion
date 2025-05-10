import SwiftUI
import PTDesignSystem

// AppearanceSetting and UnitSetting enums are expected to be accessible 
// (e.g., defined in ProfileView.swift at top level or a shared location)

struct ProfileSettingsSectionView: View {
    // @AppStorage("selectedAppearance") private var selectedAppearance: AppearanceSetting = .system // REMOVED
    @AppStorage("selectedUnit") private var selectedUnit: UnitSetting = .metric
    @AppStorage("workoutRemindersEnabled") private var workoutRemindersEnabled: Bool = true
    @AppStorage("achievementNotificationsEnabled") private var achievementNotificationsEnabled: Bool = true

    let hapticGenerator: UIImpactFeedbackGenerator

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.medium) {
            Text("Settings")
                .font(.title3.weight(.semibold))
                .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityAddTraits(.isHeader)
            
            // Appearance & Units Card using PTCard
            PTCard(style: .standard) { 
                VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.small) {
                    // Appearance Picker REMOVED
                    // Dark mode notice REMOVED
                    // Divider (if it was only for appearance) REMOVED or kept if Units is still in this card
                    
                    // Units Picker
                    HStack {
                        Label("Units", systemImage: "ruler")
                            .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                        
                        Spacer()
                        
                        Picker("", selection: $selectedUnit) {
                            ForEach(UnitSetting.allCases) { unit in
                                Text(unit.rawValue).tag(unit)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(width: 200)
                    }
                    .frame(height: 44)
                }
            }
            
            // Notifications Card using PTCard
            PTCard(style: .standard) { 
                VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.small) { // Group content for this card
                    // Workout Reminders Toggle
                    HStack {
                        Label("Workout Reminders", systemImage: "bell.fill")
                            .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                        
                        Spacer()
                        
                        Toggle("", isOn: $workoutRemindersEnabled)
                            .tint(AppTheme.GeneratedColors.brassGold)
                            .onChange(of: workoutRemindersEnabled) { _, _ in 
                                hapticGenerator.impactOccurred(intensity: 0.4)
                            }
                    }
                    .frame(height: 44)
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    // New Achievements Toggle
                    HStack {
                        Label("New Achievements", systemImage: "trophy.fill")
                            .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                        
                        Spacer()
                        
                        Toggle("", isOn: $achievementNotificationsEnabled)
                            .tint(AppTheme.GeneratedColors.brassGold)
                            .onChange(of: achievementNotificationsEnabled) { _, _ in 
                                hapticGenerator.impactOccurred(intensity: 0.4)
                            }
                    }
                    .frame(height: 44)
                }
            }
        }
        // .onAppear { ... } // REMOVED (was for applyAppearance)
        // .onChange(of: selectedAppearance) { ... } // REMOVED (was for applyAppearance)
    }

    // private func applyAppearance(_ appearance: AppearanceSetting) { ... } // REMOVED
}

struct ProfileSettingsSectionView_Previews: PreviewProvider {
    static var previews: some View {
        // Need to ensure AppearanceSetting and UnitSetting are available for preview
        // If they are in ProfileView.swift, this preview might need them to be public
        // or this preview needs to be in the same file for them to be accessible.
        // For simplicity, assuming they are accessible.
        ProfileSettingsSectionView(hapticGenerator: UIImpactFeedbackGenerator(style: .medium))
            .padding()
            .background(Color.gray.opacity(0.1))
            .previewLayout(.sizeThatFits)
    }
}
