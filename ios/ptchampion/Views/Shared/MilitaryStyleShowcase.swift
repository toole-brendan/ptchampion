import SwiftUI
import PTDesignSystem

/// A showcase view demonstrating the military styling options
struct MilitaryStyleShowcase: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Section headers
                    Group {
                        SectionHeader("SECTION HEADERS")
                        
                        HStack {
                            Text("STANDARD LABEL")
                                .militaryMonospaced(size: Spacing.small)
                                .foregroundColor(Color.textSecondary)
                            
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        HStack {
                            Text("WITH BRASS ACCENT")
                                .militaryMonospaced(size: Spacing.small)
                                .foregroundColor(Color.brassGold)
                            
                            Spacer()
                        }
                        .padding(.horizontal)
                    }
                    
                    // Card styles
                    SectionHeader("CARD STYLES")
                    
                    // Standard card
                    VStack {
                        Text("Standard Card")
                            .padding()
                            .frame(maxWidth: .infinity)
                    }
                    .standardCardStyle()
                    .padding(.horizontal)
                    
                    // Military card
                    VStack {
                        Text("Military Card with Cut Corners")
                            .militaryMonospaced()
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .militaryCardStyle()
                    .padding(.horizontal)
                    
                    // Highlighted card
                    VStack {
                        Text("Highlighted Card")
                            .padding()
                            .frame(maxWidth: .infinity)
                    }
                    .standardCardStyle(style: .highlight)
                    .padding(.horizontal)
                    
                    // Text styles
                    SectionHeader("TEXT STYLES")
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Standard Text")
                            .body()
                        
                        Text("Military Monospaced")
                            .militaryMonospaced()
                        
                        // Text with tracking modifier that needs iOS 16+ check
                        stencilCapsTextView()
                        
                        Text("Primary Command")
                            .foregroundColor(Color.primary)
                            .militaryMonospaced()
                        
                        Text("Brass Accent")
                            .foregroundColor(Color.brassGold)
                            .militaryMonospaced()
                    }
                    .padding()
                    .standardCardStyle()
                    .padding(.horizontal)
                    
                    // Buttons
                    SectionHeader("BUTTONS")
                    
                    VStack(spacing: 15) {
                        // Primary button with military style
                        Button {
                            // Action
                        } label: {
                            Text("PRIMARY COMMAND")
                                .militaryMonospaced()
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.primary)
                                .foregroundColor(Color.textOnPrimary)
                        }
                        
                        // Secondary button with military style
                        Button {
                            // Action
                        } label: {
                            Text("SECONDARY COMMAND")
                                .militaryMonospaced()
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.secondary.opacity(0.1)
                                .foregroundColor(Color.secondary)
                                .overlay(
                                    RoundedRectangle(cornerRadius: CornerRadius.button)
                                        .stroke(Color.secondary, lineWidth: 1)
                                )
                        }
                        
                        // Accent button (brass)
                        Button {
                            // Action
                        } label: {
                            Text("HIGHLIGHT COMMAND")
                                .militaryMonospaced()
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.brassGold.opacity(0.1)
                                .foregroundColor(Color.brassGold)
                                .overlay(
                                    RoundedRectangle(cornerRadius: CornerRadius.button)
                                        .stroke(Color.brassGold, lineWidth: 1)
                                )
                        }
                    }
                    .cornerRadius(CornerRadius.button)
                    .padding(.horizontal)
                    
                    // Badges
                    SectionHeader("BADGES")
                    
                    HStack(spacing: 10) {
                        Text("PT READY")
                            .militaryMonospaced(size: 12)
                            .badgeStyle(color: Color.success)
                        
                        Text("ELITE")
                            .militaryMonospaced(size: 12)
                            .badgeStyle(color: Color.brassGold)
                        
                        Text("IMPROVING")
                            .militaryMonospaced(size: 12)
                            .badgeStyle(color: Color.primary)
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 40)
                }
                .padding(.top, 20)
            }
            .background(Color.background.ignoresSafeArea()
            .navigationTitle("Military UI Kit")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // Helper function to create a text view with conditional tracking for iOS 16+
    @ViewBuilder
    private func stencilCapsTextView() -> some View {
        let baseText = Text("STENCIL CAPS")
            .militaryMonospaced()
            
        // Apply extra tracking only on iOS 16+
        if #available(iOS 16.0, *) {
            baseText.tracking(1.5) // Extra tracking for more stencil-like look
        } else {
            baseText
        }
    }
    
    // Helper to create section headers
    private func SectionHeader(_ title: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .militaryMonospaced(size: Spacing.small)
                .foregroundColor(Color.textSecondary)
            
            Rectangle()
                .fill(Color.tacticalGray.opacity(0.3)
                .frame(height: 1)
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }
}

#Preview {
    MilitaryStyleShowcase()
        .environmentObject(ThemeManager.shared)
} 