import SwiftUI
import PTDesignSystem

struct AppInfoView: View {
    var body: some View {
        Text("App Version: \(appVersion())")
            .font(.footnote)
            .foregroundColor(AppTheme.GeneratedColors.textTertiary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, AppTheme.GeneratedSpacing.medium)
    }
    
    private func appVersion() -> String {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "N/A"
    }
}

struct AppInfoView_Previews: PreviewProvider {
    static var previews: some View {
        AppInfoView()
            .padding()
            .background(AppTheme.GeneratedColors.background)
            .previewLayout(.sizeThatFits)
    }
} 