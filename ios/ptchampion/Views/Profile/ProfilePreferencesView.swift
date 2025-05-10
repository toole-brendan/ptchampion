import SwiftUI
import PTDesignSystem

struct ProfilePreferencesView: View {
    @AppStorage("selectedUnit") private var selectedUnit: UnitSetting = .metric
    @AppStorage("workoutRemindersEnabled") private var workoutRemindersEnabled: Bool = true
    @AppStorage("achievementNotificationsEnabled") private var achievementNotificationsEnabled: Bool = true

    let hapticGenerator: UIImpactFeedbackGenerator

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.medium) {
            Text("Preferences")
                .font(AppTheme.GeneratedTypography.bodySemibold(size: AppTheme.GeneratedTypography.body))
                .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityAddTraits(.isHeader)
            
            // Units Card using PTCard
            PTCard(style: .standard) { 
                VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.small) {
                    // Units Picker
                    HStack {
                        Label("Units", systemImage: "ruler")
                            .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                            .font(AppTheme.GeneratedTypography.body())
                        
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
                VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.small) { 
                    // Workout Reminders Toggle
                    HStack {
                        Label("Workout Reminders", systemImage: "bell.fill")
                            .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                            .font(AppTheme.GeneratedTypography.body())
                        
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
                            .font(AppTheme.GeneratedTypography.body())
                        
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
    }
}

struct ProfilePreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        ProfilePreferencesView(hapticGenerator: UIImpactFeedbackGenerator(style: .medium))
            .padding()
            .background(AppTheme.GeneratedColors.background)
            .previewLayout(.sizeThatFits)
    }
} 