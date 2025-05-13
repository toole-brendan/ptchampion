import SwiftUI
import PTDesignSystem

struct ProfilePreferencesView: View {
    @AppStorage("selectedUnit") private var selectedUnit: UnitSetting = .metric
    @AppStorage("workoutRemindersEnabled") private var workoutRemindersEnabled: Bool = true
    @AppStorage("achievementNotificationsEnabled") private var achievementNotificationsEnabled: Bool = true

    let hapticGenerator: UIImpactFeedbackGenerator

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Text("Preferences")
                .font(.body.weight(.semibold))
                .foregroundColor(ThemeColor.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityAddTraits([.isHeader])
            
            // Units Card
            VStack(alignment: .leading, spacing: Spacing.small) {
                // Units Picker
                HStack {
                    Label("Units", systemImage: "ruler")
                        .foregroundColor(ThemeColor.textPrimary)
                        .font(.body)
                    
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
            .padding(Spacing.contentPadding)
            .background(ThemeColor.cardBackground)
            .cornerRadius(CornerRadius.card)
            .shadow(color: ThemeColor.black.opacity(0.05), radius: 4, x: 0, y: 2)
            
            // Notifications Card
            VStack(alignment: .leading, spacing: Spacing.small) { 
                // Workout Reminders Toggle
                HStack {
                    Label("Workout Reminders", systemImage: "bell.fill")
                        .foregroundColor(ThemeColor.textPrimary)
                        .font(.body)
                    
                    Spacer()
                    
                    Toggle("", isOn: $workoutRemindersEnabled)
                        .tint(ThemeColor.brassGold)
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
                        .foregroundColor(ThemeColor.textPrimary)
                        .font(.body)
                    
                    Spacer()
                    
                    Toggle("", isOn: $achievementNotificationsEnabled)
                        .tint(ThemeColor.brassGold)
                        .onChange(of: achievementNotificationsEnabled) { _, _ in 
                            hapticGenerator.impactOccurred(intensity: 0.4)
                        }
                }
                .frame(height: 44)
            }
            .padding(Spacing.contentPadding)
            .background(ThemeColor.cardBackground)
            .cornerRadius(CornerRadius.card)
            .shadow(color: ThemeColor.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }
}

struct ProfilePreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        ProfilePreferencesView(hapticGenerator: UIImpactFeedbackGenerator(style: .medium))
            .padding()
            .background(ThemeColor.background)
            .previewLayout(.sizeThatFits)
    }
} 