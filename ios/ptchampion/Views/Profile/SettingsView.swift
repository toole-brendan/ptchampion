import SwiftUI
import Foundation
import CoreLocation
import PTDesignSystem

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    @State private var hapticGenerator = UIImpactFeedbackGenerator(style: .medium)
    
    // App theme settings
    enum AppThemeOption: String, CaseIterable, Identifiable {
        case system = "System"
        case light = "Light"
        case dark = "Dark"
        
        var id: String { self.rawValue }
    }
    
    @AppStorage("selectedAppearance") private var selectedAppearance: AppThemeOption = .system
    
    // Units settings
    enum UnitSetting: String, CaseIterable, Identifiable {
        case metric = "Metric (kg, km)"
        case imperial = "Imperial (lbs, miles)"
        var id: String { self.rawValue }
    }
    @AppStorage("selectedUnit") private var selectedUnit: UnitSetting = .metric
    
    // Notifications
    @AppStorage("workoutRemindersEnabled") private var workoutRemindersEnabled: Bool = true
    @AppStorage("achievementNotificationsEnabled") private var achievementNotificationsEnabled: Bool = true
    
    // Device management
    @State private var showDeviceScanner = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.GeneratedSpacing.medium) {
                    // Appearance Group
                    settingsGroup(title: "Appearance") {
                        SettingsRow(icon: "paintbrush.fill", label: "Theme") {
                            Picker("", selection: $selectedAppearance) {
                                ForEach(AppThemeOption.allCases) { option in
                                    Text(option.rawValue).tag(option)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .frame(width: 120)
                            .onChange(of: selectedAppearance) { _ in
                                hapticGenerator.impactOccurred(intensity: 0.3)
                                applyTheme()
                            }
                        }
                        
                        Text("Dark mode support is in progress.")
                            .font(AppTheme.GeneratedTypography.body(size: AppTheme.GeneratedTypography.small))
                            .foregroundColor(AppTheme.GeneratedColors.textTertiary)
                            .italic()
                            .padding(.leading, 34) // Align with text after icon
                    }
                    
                    // Units Group
                    settingsGroup(title: "Units") {
                        SettingsRow(icon: "ruler", label: "Units") {
                            Picker("", selection: $selectedUnit) {
                                ForEach(UnitSetting.allCases) { unit in
                                    Text(unit.rawValue).tag(unit)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .frame(width: 200)
                            .onChange(of: selectedUnit) { _ in
                                hapticGenerator.impactOccurred(intensity: 0.3)
                            }
                        }
                    }
                    
                    // Notifications Group
                    settingsGroup(title: "Notifications") {
                        SettingsRow(icon: "bell.fill", label: "Workout Reminders") {
                            Toggle("", isOn: $workoutRemindersEnabled)
                                .tint(AppTheme.GeneratedColors.brassGold)
                                .onChange(of: workoutRemindersEnabled) { _ in
                                    hapticGenerator.impactOccurred(intensity: 0.4)
                                }
                        }
                        
                        Divider()
                        
                        SettingsRow(icon: "trophy.fill", label: "Achievement Notifications") {
                            Toggle("", isOn: $achievementNotificationsEnabled)
                                .tint(AppTheme.GeneratedColors.brassGold)
                                .onChange(of: achievementNotificationsEnabled) { _ in
                                    hapticGenerator.impactOccurred(intensity: 0.4)
                                }
                        }
                    }
                    
                    // Device Management Group
                    settingsGroup(title: "Device Management") {
                        Button {
                            hapticGenerator.impactOccurred(intensity: 0.5)
                            showDeviceScanner = true
                        } label: {
                            SettingsRow(icon: "antenna.radiowaves.left.and.right", label: "Manage Bluetooth Devices") {
                                Image(systemName: "chevron.right")
                                    .font(.footnote)
                                    .foregroundColor(AppTheme.GeneratedColors.textTertiary)
                            }
                        }
                        .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                    }
                    
                    // App Version
                    HStack {
                        Spacer()
                        Text("PT Champion v\(appVersion())")
                            .font(AppTheme.GeneratedTypography.body(size: AppTheme.GeneratedTypography.small))
                            .foregroundColor(AppTheme.GeneratedColors.textTertiary)
                            .padding(.top, AppTheme.GeneratedSpacing.large)
                        Spacer()
                    }
                }
                .padding(AppTheme.GeneratedSpacing.contentPadding)
            }
            .background(AppTheme.GeneratedColors.background.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        hapticGenerator.impactOccurred(intensity: 0.3)
                        dismiss()
                    } label: {
                        Text("Done")
                            .fontWeight(.semibold)
                            .foregroundColor(AppTheme.GeneratedColors.accent)
                    }
                }
            }
            .sheet(isPresented: $showDeviceScanner) {
                NavigationStack {
                    DeviceScanningView()
                        .navigationTitle("Bluetooth Devices")
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") {
                                    showDeviceScanner = false
                                }
                            }
                        }
                }
            }
            .onAppear {
                hapticGenerator.prepare()
            }
        }
    }
    
    // MARK: - Helper Views
    
    @ViewBuilder
    private func settingsGroup<Content: View>(title: String, @ViewBuilder content: @escaping () -> Content) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.medium) {
            // Group title
            Text(title)
                .font(AppTheme.GeneratedTypography.bodySemibold())
                .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                .padding(.leading, 4)
            
            // Content card
            VStack(alignment: .leading, spacing: 0) {
                content()
            }
            .padding(AppTheme.GeneratedSpacing.medium)
            .background(AppTheme.GeneratedColors.cardBackground)
            .cornerRadius(AppTheme.GeneratedRadius.card)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }
    
    // MARK: - Helper Methods
    
    private func appVersion() -> String {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "N/A"
    }
    
    private func applyTheme() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        windowScene.windows.forEach { window in
            switch selectedAppearance {
            case .light:
                window.overrideUserInterfaceStyle = .light
            case .dark:
                window.overrideUserInterfaceStyle = .dark
            case .system:
                window.overrideUserInterfaceStyle = .unspecified
            }
        }
    }
}

// MARK: - Settings Row Component

struct SettingsRow<Content: View>: View {
    let icon: String
    let label: String
    let control: Content
    
    init(icon: String, label: String, @ViewBuilder control: () -> Content) {
        self.icon = icon
        self.label = label
        self.control = control()
    }
    
    var body: some View {
        HStack {
            // Icon
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundColor(AppTheme.GeneratedColors.primary)
            
            // Label
            Text(label)
                .font(AppTheme.GeneratedTypography.body())
                .foregroundColor(AppTheme.GeneratedColors.textPrimary)
            
            Spacer()
            
            // Control (toggle, picker, etc.)
            control
        }
        .frame(minHeight: 44) // Ensure minimum hit target size for accessibility
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(AuthViewModel())
    }
} 