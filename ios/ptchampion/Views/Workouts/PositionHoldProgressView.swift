import SwiftUI

struct PositionHoldProgressView: View {
    let progress: Double // 0.0 to 1.0
    @State private var pulseAnimation = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Main progress circle
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 8)
                    .frame(width: 120, height: 120)
                
                // Progress circle
                Circle()
                    .trim(from: 0, to: CGFloat(progress))
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [.green, .blue]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.2), value: progress)
                
                // Center content
                VStack(spacing: 4) {
                    Image(systemName: "figure.stand")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                    
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            
            // Instruction text
            VStack(spacing: 4) {
                Text("Hold Position")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Stay in starting position")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            // Time remaining indicator
            if progress > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("\(String(format: "%.1f", (1.0 - progress) * 2.0))s remaining")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [.green.opacity(0.5), .blue.opacity(0.5)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
        )
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                pulseAnimation = true
            }
        }
        .scaleEffect(progress > 0.8 ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: progress)
    }
}

// MARK: - Enhanced Position Hold Progress View
struct EnhancedPositionHoldProgressView: View {
    let progress: Double
    let timeRemaining: Double
    let isInCorrectPosition: Bool
    
    @State private var pulseAnimation = false
    @State private var glowAnimation = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Main progress indicator
            ZStack {
                // Outer glow ring (when in correct position)
                if isInCorrectPosition {
                    Circle()
                        .stroke(Color.green.opacity(0.3), lineWidth: 4)
                        .frame(width: 140, height: 140)
                        .scaleEffect(glowAnimation ? 1.1 : 1.0)
                        .opacity(glowAnimation ? 0.5 : 0.8)
                }
                
                // Background circle
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 6)
                    .frame(width: 120, height: 120)
                
                // Progress circle
                Circle()
                    .trim(from: 0, to: CGFloat(progress))
                    .stroke(
                        progressGradient,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.3), value: progress)
                
                // Center icon and percentage
                VStack(spacing: 6) {
                    Image(systemName: centerIcon)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(iconColor)
                        .scaleEffect(pulseAnimation ? 1.15 : 1.0)
                    
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            
            // Status and instruction
            VStack(spacing: 8) {
                Text(statusText)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(statusColor)
                
                Text(instructionText)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                
                // Time remaining (only when actively progressing)
                if progress > 0 && isInCorrectPosition {
                    HStack(spacing: 6) {
                        Image(systemName: "timer")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text("\(String(format: "%.1f", timeRemaining))s")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(borderGradient, lineWidth: 2)
                )
        )
        .shadow(color: .black.opacity(0.4), radius: 15, x: 0, y: 8)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                pulseAnimation = true
            }
            
            if isInCorrectPosition {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    glowAnimation = true
                }
            }
        }
        .onChange(of: isInCorrectPosition) { _, newValue in
            if newValue {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    glowAnimation = true
                }
            } else {
                glowAnimation = false
            }
        }
        .scaleEffect(progress > 0.9 ? 1.02 : 1.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: progress)
    }
    
    // MARK: - Computed Properties
    
    private var progressGradient: LinearGradient {
        if isInCorrectPosition {
            return LinearGradient(
                gradient: Gradient(colors: [.green, .blue]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                gradient: Gradient(colors: [.orange, .red]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var centerIcon: String {
        if progress >= 1.0 {
            return "checkmark.circle.fill"
        } else if isInCorrectPosition {
            return "figure.stand"
        } else {
            return "exclamationmark.triangle.fill"
        }
    }
    
    private var iconColor: Color {
        if progress >= 1.0 {
            return .green
        } else if isInCorrectPosition {
            return .white
        } else {
            return .orange
        }
    }
    
    private var statusText: String {
        if progress >= 1.0 {
            return "Ready!"
        } else if isInCorrectPosition {
            return "Hold Position"
        } else {
            return "Get in Position"
        }
    }
    
    private var statusColor: Color {
        if progress >= 1.0 {
            return .green
        } else if isInCorrectPosition {
            return .white
        } else {
            return .orange
        }
    }
    
    private var instructionText: String {
        if progress >= 1.0 {
            return "Starting workout..."
        } else if isInCorrectPosition {
            return "Stay in starting position"
        } else {
            return "Move to starting position"
        }
    }
    
    private var backgroundColor: Color {
        Color.black.opacity(0.85)
    }
    
    private var borderGradient: LinearGradient {
        if isInCorrectPosition {
            return LinearGradient(
                gradient: Gradient(colors: [.green.opacity(0.6), .blue.opacity(0.6)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                gradient: Gradient(colors: [.orange.opacity(0.6), .red.opacity(0.6)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

// MARK: - Preview
struct PositionHoldProgressView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Basic version
            PositionHoldProgressView(progress: 0.6)
                .background(Color.black)
                .previewDisplayName("Basic Progress")
            
            // Enhanced version - in position
            EnhancedPositionHoldProgressView(
                progress: 0.7,
                timeRemaining: 0.6,
                isInCorrectPosition: true
            )
            .background(Color.black)
            .previewDisplayName("Enhanced - In Position")
            
            // Enhanced version - not in position
            EnhancedPositionHoldProgressView(
                progress: 0.0,
                timeRemaining: 2.0,
                isInCorrectPosition: false
            )
            .background(Color.black)
            .previewDisplayName("Enhanced - Not In Position")
            
            // Enhanced version - complete
            EnhancedPositionHoldProgressView(
                progress: 1.0,
                timeRemaining: 0.0,
                isInCorrectPosition: true
            )
            .background(Color.black)
            .previewDisplayName("Enhanced - Complete")
        }
    }
} 