import SwiftUI
import PTDesignSystem

// fileprivate extension View { ... } // REMOVED

struct ProfileHeaderView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @Binding var showingEditProfile: Bool
    
    // Computed property to get user's initials
    private var userInitials: String {
        if case .authenticated(let user) = authViewModel.authState {
            let firstInitial = user.firstName?.prefix(1).uppercased() ?? ""
            let lastInitial = user.lastName?.prefix(1).uppercased() ?? ""
            
            if !lastInitial.isEmpty {
                return "\(firstInitial)\(lastInitial)"
            } else if !firstInitial.isEmpty {
                // If only first name is available, use first two letters
                let firstName = user.firstName ?? ""
                if firstName.count > 1 {
                    let secondLetter = String(firstName.dropFirst().prefix(1).uppercased())
                    return "\(firstInitial)\(secondLetter)"
                }
                return firstInitial
            }
            return "U" // Default if no name available
        }
        return "U" // Default for unauthenticated
    }

    var body: some View {
        PTCard(style: .standard) { // Use PTCard as the root
            VStack(spacing: AppTheme.GeneratedSpacing.medium) {
                // Avatar circle with initials
                ZStack {
                    Circle()
                        .fill(AppTheme.GeneratedColors.primary.opacity(0.1))
                        .frame(width: 100, height: 100)
                    
                    Text(userInitials)
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(AppTheme.GeneratedColors.primary)
                }
                .padding(.top, AppTheme.GeneratedSpacing.medium)
                
                // User information
                VStack(spacing: AppTheme.GeneratedSpacing.small) {
                    Text(authViewModel.displayName ?? "N/A")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                    
                    Text(authViewModel.email ?? "N/A")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                }
                
                // Edit profile button
                Button {
                    showingEditProfile = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "pencil")
                            .font(.footnote)
                        Text("Edit Profile")
                            .font(.footnote.weight(.medium))
                    }
                    .foregroundColor(AppTheme.GeneratedColors.brassGold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .stroke(AppTheme.GeneratedColors.brassGold, lineWidth: 1)
                    )
                }
                .padding(.bottom, AppTheme.GeneratedSpacing.small)
            }
            .frame(maxWidth: .infinity) // Make the VStack (content of the card) take full width
        }
    }
}

// Moved MockAuthViewModelForHeader outside of the previews property
fileprivate class MockAuthViewModelForHeaderPreview: AuthViewModel {
    override init() {
        super.init()
        let mockUser = AuthUserModel(
            id: "mockUserID123",
            email: "user@example.com",
            firstName: "Preview",
            lastName: "User",
            profilePictureUrl: nil
        )
        self.setMockUser(mockUser)
    }
}

// Preview for ProfileHeaderView
struct ProfileHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileHeaderView(
            authViewModel: MockAuthViewModelForHeaderPreview(),
            showingEditProfile: .constant(false)
        )
        .padding()
        .background(Color.gray.opacity(0.2))
        .previewLayout(.sizeThatFits)
    }
} 