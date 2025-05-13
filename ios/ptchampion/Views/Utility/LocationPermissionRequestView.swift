import SwiftUI
import CoreLocation
import PTDesignSystem

struct LocationPermissionRequestView: View {
    var onRequestPermission: () -> Void
    var onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 25) {
            Image(systemName: "location.fill")
                .font(.system(size: 70)
                .foregroundColor(Color.primary)
            
            Text("Location Permission")
                .font(.title)
                .fontWeight(.bold)
            
            Text("PT Champion needs your location to track run distance and pace. Your location data is only used during workouts.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Text("The app will use your device's GPS to calculate distance, pace and route information while you're running.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .foregroundColor(Color.textSecondary)
            
            HStack(spacing: 20) {
                Button(action: onCancel) {
                    Text("Not Now")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.backgroundOverlay)
                        .foregroundColor(Color.textPrimary)
                        .cornerRadius(CornerRadius.medium)
                }
                
                Button(action: onRequestPermission) {
                    Text("Allow Location")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.primary)
                        .foregroundColor(Color.textPrimaryOnDark)
                        .cornerRadius(CornerRadius.medium)
                }
            }
            .padding(.horizontal)
            .padding(.top, 10)
        }
        .padding()
        .background(Color.background)
        .cornerRadius(CornerRadius.card)
        .shadow(radius: 10)
        .padding(.horizontal, 20)
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.3).edgesIgnoringSafeArea(.all)
        LocationPermissionRequestView(
            onRequestPermission: {},
            onCancel: {}
        )
    }
} 