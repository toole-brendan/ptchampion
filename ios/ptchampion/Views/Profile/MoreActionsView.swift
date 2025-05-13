import SwiftUI
import PTDesignSystem

struct MoreActionsView: View {
    @EnvironmentObject var fitnessDeviceManagerViewModel: FitnessDeviceManagerViewModel
    @State private var hapticGenerator = UIImpactFeedbackGenerator(style: .medium)
    @State private var showingPrivacyPolicy = false
    @State private var showingConnectedDevices = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            // Section Header
            Text("More")
                .heading3()
                .foregroundColor(ThemeColor.textPrimary)
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
                            .foregroundColor(ThemeColor.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(ThemeColor.textTertiary)
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
                        Label("Fitness Devices", systemImage: "antenna.radiowaves.left.and.right")
                            .foregroundColor(ThemeColor.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(ThemeColor.textTertiary)
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
                FitnessDeviceManagerView()
                    .environmentObject(fitnessDeviceManagerViewModel)
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
        .padding(Spacing.contentPadding)
        .background(ThemeColor.cardBackground)
        .cornerRadius(CornerRadius.card)
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
            .environmentObject(FitnessDeviceManagerViewModel())
            .padding()
            .background(ThemeColor.background)
            .previewLayout(.sizeThatFits)
    }
} 