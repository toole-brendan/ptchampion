import SwiftUI
import PTDesignSystem

struct UserProfileView: View {
    let userID: String
    // TODO: Inject a ViewModel to fetch user details based on userID

    var body: some View {
        VStack {
            PTLabel("User Profile", style: .heading)
            Divider()
            PTLabel("Displaying profile for User ID:", style: .subheading)
            Text(userID)
                .font(.title3)
                .padding()
            
            // TODO: Add more user details here once ViewModel is implemented
            // e.g., Username, Rank, Stats, Recent Activity etc.
            
            Spacer()
        }
        .padding()
        .navigationTitle("User Profile") // Set a navigation title
        .navigationBarTitleDisplayMode(.inline)
    }
}

#if DEBUG
struct UserProfileView_Previews: PreviewProvider {
    static var previews: some View {
        // Wrap in NavigationView for previewing navigationBarTitle
        NavigationView {
            UserProfileView(userID: "previewUserID123")
        }
    }
}
#endif 