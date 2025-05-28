import SwiftUI
import PTDesignSystem

struct DirectionalArrows: View {
    let adjustment: FullBodyFramingValidator.FramingAdjustment
    
    @State private var pulseAnimation = false
    
    var body: some View {
        ZStack {
            switch adjustment {
            case .moveCloser:
                VStack {
                    Spacer()
                    ArrowIndicator(direction: .up, text: "Move Closer")
                    Spacer()
                }
                
            case .moveBack:
                VStack {
                    Spacer()
                    ArrowIndicator(direction: .down, text: "Step Back")
                    Spacer()
                }
                
            case .moveLeft:
                HStack {
                    ArrowIndicator(direction: .left, text: "Move Left")
                    Spacer()
                }
                
            case .moveRight:
                HStack {
                    Spacer()
                    ArrowIndicator(direction: .right, text: "Move Right")
                }
                
            case .rotateDevice:
                VStack {
                    Spacer()
                    RotateDeviceIndicator()
                    Spacer()
                }
                
            case .none:
                EmptyView()
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                pulseAnimation = true
            }
        }
    }
}

struct ArrowIndicator: View {
    enum Direction {
        case up, down, left, right
        
        var systemImage: String {
            switch self {
            case .up: return "arrow.up.circle.fill"
            case .down: return "arrow.down.circle.fill"
            case .left: return "arrow.left.circle.fill"
            case .right: return "arrow.right.circle.fill"
            }
        }
    }
    
    let direction: Direction
    let text: String
    @State private var pulseAnimation = false
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: direction.systemImage)
                .font(.system(size: 40))
                .foregroundColor(.orange)
                .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: pulseAnimation)
            
            Text(text)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.7))
                )
        }
        .onAppear {
            pulseAnimation = true
        }
    }
}

struct RotateDeviceIndicator: View {
    @State private var rotationAnimation = false
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "iphone")
                .font(.system(size: 40))
                .foregroundColor(.orange)
                .rotationEffect(.degrees(rotationAnimation ? 90 : 0))
                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: rotationAnimation)
            
            Text("Rotate Device")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.7))
                )
        }
        .onAppear {
            rotationAnimation = true
        }
    }
}

// MARK: - Preview
struct DirectionalArrows_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            DirectionalArrows(adjustment: .moveCloser)
                .previewDisplayName("Move Closer")
            
            DirectionalArrows(adjustment: .moveLeft)
                .previewDisplayName("Move Left")
            
            DirectionalArrows(adjustment: .rotateDevice)
                .previewDisplayName("Rotate Device")
        }
        .background(Color.black)
        .previewLayout(.sizeThatFits)
    }
} 