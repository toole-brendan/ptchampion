import SwiftUI

struct RootView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        Group {
            if authViewModel.isLoading {
                LoadingView()
            } else if authViewModel.isAuthenticated {
                MainTabView()
            } else {
                AuthView()
            }
        }
        .alert(isPresented: .init(get: {
            authViewModel.error != nil
        }, set: { _ in
            authViewModel.error = nil
        })) {
            Alert(
                title: Text("Error"),
                message: Text(authViewModel.error ?? "An unknown error occurred"),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

struct LoadingView: View {
    var body: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
                .padding()
            Text("Loading...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
            .environmentObject(AuthViewModel())
    }
}