import SwiftUI
import PTDesignSystem

struct WarningBanner: View {
    let title: String
    let message: String
    let primary: BannerButton
    let secondary: BannerButton?
    
    struct BannerButton {
        let label: String
        let action: () -> Void
    }
    
    var body: some View {
        VStack(spacing: AppTheme.GeneratedSpacing.extraSmall) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(AppTheme.GeneratedColors.warning)
                Text(title)
                    .font(AppTheme.GeneratedTypography.bodyBold())
                    .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                Spacer()
                Button(action: primary.action) {
                    Text(primary.label)
                        .font(AppTheme.GeneratedTypography.bodyBold(size: AppTheme.GeneratedTypography.small))
                        .foregroundColor(AppTheme.GeneratedColors.brassGold)
                }
                if let secondary = secondary {
                    Button(action: secondary.action) {
                        Text(secondary.label)
                            .font(AppTheme.GeneratedTypography.body(size: AppTheme.GeneratedTypography.small))
                            .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                    }
                }
            }
            .padding(.horizontal)
            
            Text(message)
                .font(AppTheme.GeneratedTypography.body(size: AppTheme.GeneratedTypography.small))
                .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal)
            
        }
        .padding(.vertical, AppTheme.GeneratedSpacing.small)
        .background(.ultraThinMaterial)
        .overlay(
            Divider().background(AppTheme.GeneratedColors.tacticalGray.opacity(0.3)), 
            alignment: .bottom
        )
        .transition(.move(edge: .top).combined(with: .opacity))
    }
} 