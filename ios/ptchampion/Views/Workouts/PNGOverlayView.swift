import SwiftUI
import PTDesignSystem

/// View that displays PNG overlay guides for exercise positioning
struct PNGOverlayView: View {
    let exerciseType: ExerciseType
    let opacity: Double
    let isFlipped: Bool
    @State private var imageSize: CGSize = .zero
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let image = exerciseImage {
                    // Main overlay image - Centered properly for landscape
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(exerciseScale)
                        .opacity(opacity)
                        .frame(width: geometry.size.width * frameWidthMultiplier,
                               height: geometry.size.height * frameHeightMultiplier)
                        .position(x: geometry.size.width / 2,
                                  y: geometry.size.height / 2) // Always centered, no offset
                        .scaleEffect(x: isFlipped ? -1 : 1, y: 1)
                        .allowsHitTesting(false)
                        .overlay(
                            // Add a subtle glow effect for better visibility
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .scaleEffect(exerciseScale)
                                .frame(width: geometry.size.width * frameWidthMultiplier,
                                       height: geometry.size.height * frameHeightMultiplier)
                                .blur(radius: 25)
                                .opacity(opacity * 0.3) // Increased glow for better visibility
                                .scaleEffect(x: isFlipped ? -1 : 1, y: 1)
                                .allowsHitTesting(false)
                        )
                }
            }
        }
    }
    
    // Frame multipliers for better landscape centering
    private var frameWidthMultiplier: CGFloat {
        switch exerciseType {
        case .pushup, .situp:
            return 0.7 // Use 70% of screen width for better visibility
        case .pullup:
            return 0.5 // Pullup is more vertical
        default:
            return 0.6
        }
    }
    
    private var frameHeightMultiplier: CGFloat {
        switch exerciseType {
        case .pushup, .situp:
            return 0.8 // Use 80% of screen height
        case .pullup:
            return 0.9 // Pullup uses more vertical space
        default:
            return 0.8
        }
    }
    
    // Scale factor adjusted for better visibility
    private var exerciseScale: CGFloat {
        switch exerciseType {
        case .pushup:
            return 1.0 // No additional scaling needed with new frame logic
        case .situp:
            return 1.0
        case .pullup:
            return 1.1 // Slightly larger for pullup
        case .run:
            return 1.0
        case .unknown:
            return 1.0
        }
    }
    
    private var exerciseImage: UIImage? {
        // First try the position-specific image
        let positionImageName = "\(exerciseType.rawValue)_position"
        if let image = UIImage(named: positionImageName) {
            return image
        }
        
        // Fall back to the regular exercise image
        if let image = UIImage(named: exerciseType.rawValue) {
            return image
        }
        
        // Try alternate names for specific exercises
        switch exerciseType {
        case .pushup:
            return UIImage(named: "pushup") ?? UIImage(named: "pushup_position")
        case .situp:
            return UIImage(named: "situp") ?? UIImage(named: "situp_position")
        case .pullup:
            return UIImage(named: "pullup") ?? UIImage(named: "pullup_position")
        case .run:
            return UIImage(named: "running") ?? UIImage(named: "run_position")
        case .unknown:
            return nil
        }
    }
}

// MARK: - Preview
struct PNGOverlayView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            PNGOverlayView(exerciseType: .pushup, opacity: 0.5, isFlipped: false)
                .previewDisplayName("Push-up Overlay - Normal")
            
            PNGOverlayView(exerciseType: .pushup, opacity: 0.5, isFlipped: true)
                .previewDisplayName("Push-up Overlay - Flipped")
            
            PNGOverlayView(exerciseType: .situp, opacity: 0.5, isFlipped: false)
                .previewDisplayName("Sit-up Overlay - Normal")
            
            PNGOverlayView(exerciseType: .situp, opacity: 0.5, isFlipped: true)
                .previewDisplayName("Sit-up Overlay - Flipped")
            
            PNGOverlayView(exerciseType: .pullup, opacity: 0.5, isFlipped: false)
                .previewDisplayName("Pull-up Overlay")
        }
        .background(Color.black)
    }
} 