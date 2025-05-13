import SwiftUI
import PTDesignSystem

struct AccountActionsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var hapticGenerator = UIImpactFeedbackGenerator(style: .medium)
    @State private var showingChangePassword = false
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            // Section Header
            Text("Account")
                .heading3()
                .foregroundColor(ThemeColor.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityAddTraits(.isHeader)
            
            // Account Card
            settingsCard {
                // Change Password
                Button {
                    hapticGenerator.impactOccurred(intensity: 0.5)
                    showingChangePassword = true
                } label: {
                    HStack {
                        Label("Change Password", systemImage: "lock.fill")
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
                
                // Logout Button
                Button {
                    hapticGenerator.impactOccurred(intensity: 0.6)
                    authViewModel.logout()
                } label: {
                    HStack {
                        Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(ThemeColor.error)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .frame(height: 44)
                
                Divider()
                    .padding(.vertical, 8)
                
                // Delete Account
                Button {
                    hapticGenerator.impactOccurred(intensity: 0.7)
                    showingDeleteConfirmation = true
                } label: {
                    HStack {
                        Label("Delete Account", systemImage: "trash.fill")
                            .foregroundColor(ThemeColor.error)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .frame(height: 44)
            }
        }
        .sheet(isPresented: $showingChangePassword) {
            NavigationView {
                Text("Change Password View (TODO)")
                    .navigationTitle("Change Password")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Cancel") { 
                                showingChangePassword = false 
                            }
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Save") { 
                                showingChangePassword = false 
                            }
                        }
                    }
            }
        }
        .alert("Confirm Delete", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                showingDeleteConfirmation = false
                // In a real app, this would call the delete account API
                // authViewModel.deleteAccount()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete your account? This action cannot be undone.")
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
            color: ThemeColor.black.opacity(0.1),
            radius: 4,
            x: 0,
            y: 2
        )
    }
}

struct AccountActionsView_Previews: PreviewProvider {
    static var previews: some View {
        AccountActionsView()
            .environmentObject(MockAuthViewModel())
            .padding()
            .background(ThemeColor.background)
            .previewLayout(.sizeThatFits)
    }
} 