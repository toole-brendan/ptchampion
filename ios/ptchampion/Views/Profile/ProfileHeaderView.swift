import SwiftUI
import PTDesignSystem

/// Header component for profile views showing user info and edit button
struct ProfileHeaderView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @Binding var showingEditProfile: Bool
    
    init(showingEditProfile: Binding<Bool>) {
        self._showingEditProfile = showingEditProfile
    }
    
    var displayName: String {
        if let firstName = authViewModel.firstName, let lastName = authViewModel.lastName {
            return "\(firstName) \(lastName)"
        } else if let firstName = authViewModel.firstName {
            return firstName
        } else if let lastName = authViewModel.lastName {
            return lastName
        } else if let email = authViewModel.email {
            return email
        } else {
            return "User"
        }
    }
    
    var initials: String {
        if let firstName = authViewModel.firstName?.prefix(1), let lastName = authViewModel.lastName?.prefix(1) {
            return "\(firstName)\(lastName)"
        } else {
            return displayName.prefix(1).uppercased()
        }
    }

    var body: some View {
        VStack {
            VStack(spacing: Spacing.medium) {
                // Avatar circle with initials
                ZStack {
                    Circle()
                        .fill(Color.brassGold.opacity(0.2))
                    
                    Text(initials)
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(Color.brassGold)
                        .minimumScaleFactor(0.5)
                        .padding(Spacing.contentPadding)
                }
                .frame(width: 100, height: 100)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                
                // Name and email
                VStack(spacing: 4) {
                    Text(displayName)
                        .font(.title3.weight(.semibold))
                        .foregroundColor(Color.textPrimary)
                    
                    Text(authViewModel.email ?? "N/A")
                        .font(.caption)
                        .foregroundColor(Color.textSecondary)
                }
                
                // Edit profile button
                Button {
                    showingEditProfile = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "pencil")
                            .font(.caption)
                        Text("Edit Profile")
                            .font(.caption.weight(.medium))
                    }
                    .padding(.horizontal, Spacing.small)
                    .padding(.vertical, 6)
                    .background(Color.brassGold.opacity(0.1))
                    .cornerRadius(CornerRadius.button)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(Spacing.contentPadding)
        }
        .background(Color.cardBackground)
        .cornerRadius(CornerRadius.card)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct ProfileHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileHeaderView(showingEditProfile: .constant(false))
            .environmentObject(AuthViewModel())
            .padding()
            .background(Color.background)
            .previewLayout(.sizeThatFits)
    }
} 