import SwiftUI
import PTDesignSystem

struct LoadingView: View {
    @EnvironmentObject private var navigationState: NavigationState
    
    var body: some View {
        ZStack {
            // Background
            AppTheme.GeneratedColors.cream.ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Logo
                Image(uiImage: UIImage(named: "pt_champion_logo") ?? 
                      (Bundle.main.path(forResource: "pt_champion_logo", ofType: "png").flatMap { UIImage(contentsOfFile: $0) }) ?? 
                      UIImage(systemName: "shield.lefthalf.filled")!)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                    .foregroundColor(AppTheme.GeneratedColors.brassGold)
                
                // Title
                PTLabel("PT CHAMPION", style: .heading)
                    .foregroundColor(AppTheme.GeneratedColors.commandBlack)
                
                // Loading indicator
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.GeneratedColors.brassGold))
                    .scaleEffect(1.5)
                    .padding(.top, 20)
                
                PTLabel("Loading...", style: .caption)
                    .foregroundColor(AppTheme.GeneratedColors.tacticalGray)
                    .padding(.top, 10)
            }
        }
        .onAppear {
            // Auto-navigate after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                if navigationState.currentScreen == .loading {
                    navigationState.navigateTo(.login)
                }
            }
        }
    }
}

#Preview {
    LoadingView()
        .environmentObject(NavigationState())
} 