import SwiftUI
import PTDesignSystem

struct MoreActionsView: View {
    @State private var hapticGenerator = UIImpactFeedbackGenerator(style: .medium)
    @State private var showingPrivacyPolicy = false
    @State private var showingConnectedDevices = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.medium) {
            // Section Header
            Text("More")
                .font(.title3.weight(.semibold))
                .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityAddTraits(.isHeader)
            
            // More Card
            settingsCard {
                // Privacy Policy
                Button {
                    hapticGenerator.impactOccurred(intensity: 0.5)
                    showingPrivacyPolicy = true
                } label: {
                    HStack {
                        Label("Privacy Policy", systemImage: "doc.text.fill")
                            .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.footnote)
                            .foregroundColor(AppTheme.GeneratedColors.textTertiary)
                    }
                    .contentShape(Rectangle())
                }
                .frame(height: 44)
                
                Divider()
                    .padding(.vertical, 8)
                
                // Connected Devices
                Button {
                    hapticGenerator.impactOccurred(intensity: 0.5)
                    showingConnectedDevices = true
                } label: {
                    HStack {
                        Label("Connected Devices", systemImage: "antenna.radiowaves.left.and.right")
                            .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.footnote)
                            .foregroundColor(AppTheme.GeneratedColors.textTertiary)
                    }
                    .contentShape(Rectangle())
                }
                .frame(height: 44)
            }
        }
        .sheet(isPresented: $showingPrivacyPolicy) {
            NavigationView {
                Text("Privacy Policy View (TODO)")
                    .navigationTitle("Privacy Policy")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") { 
                                showingPrivacyPolicy = false 
                            }
                        }
                    }
            }
        }
        .sheet(isPresented: $showingConnectedDevices) {
            NavigationView {
                Text("Connected Devices View (TODO)")
                    .navigationTitle("Connected Devices")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") { 
                                showingConnectedDevices = false 
                            }
                        }
                    }
            }
        }
        .onAppear {
            hapticGenerator.prepare()
        }
    }
    
    // Card Container for Settings
    @ViewBuilder
    private func settingsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
        }
        .padding(AppTheme.GeneratedSpacing.contentPadding)
        .background(AppTheme.GeneratedColors.cardBackground)
        .cornerRadius(AppTheme.GeneratedRadius.card)
        .shadow(
            color: Color.black.opacity(0.1),
            radius: 4,
            x: 0,
            y: 2
        )
    }
}

struct MoreActionsView_Previews: PreviewProvider {
    static var previews: some View {
        MoreActionsView()
            .padding()
            .background(AppTheme.GeneratedColors.background)
            .previewLayout(.sizeThatFits)
    }
} 