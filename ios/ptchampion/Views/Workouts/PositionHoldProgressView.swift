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
                            gradient: Gradient(colors: [
                                isInCorrectPosition ? .green : .orange,
                                isInCorrectPosition ? .blue : .red
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.3), value: progress)
                
                // Center content
                VStack(spacing: 4) {
                    Text("\(Int(timeRemaining))")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("seconds")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: pulseAnimation)
            }
            
            // Status text
            Text(isInCorrectPosition ? "Hold Position" : "Get in Position")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isInCorrectPosition ? Color.green.opacity(0.8) : Color.orange.opacity(0.8))
                )
        }
        .onAppear {
            withAnimation {
                pulseAnimation = true
            }
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