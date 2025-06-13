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
            return 0.85 // Increased from 0.7 to use 85% of screen width
        case .pullup:
            return 0.65 // Increased from 0.5 for pullup
        default:
            return 0.75 // Increased from 0.6
        }
    }
    
    private var frameHeightMultiplier: CGFloat {
        switch exerciseType {
        case .pushup, .situp:
            return 0.9 // Increased from 0.8 to use 90% of screen height
        case .pullup:
            return 0.95 // Increased from 0.9
        default:
            return 0.9
        }
    }
    
    // Scale factor adjusted for better visibility
    private var exerciseScale: CGFloat {
        switch exerciseType {
        case .pushup:
            return 1.2 // Added 20% scale for better visibility
        case .situp:
            return 1.2 // Added 20% scale
        case .pullup:
            return 1.25 // Slightly more for pullup since it's vertical
        case .run:
            return 1.15
        case .plank:
            return 1.2 // Same as pushup since similar position
        case .unknown:
            return 1.15
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
        case .plank:
            return UIImage(named: "plank") ?? UIImage(named: "plank_position")
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