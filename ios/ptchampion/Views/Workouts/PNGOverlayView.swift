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
                    // Main overlay image - Fit with scale for larger size
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)  // Prevent cutoff
                        .scaleEffect(exerciseScale)  // Scale up to make larger
                        .opacity(opacity)
                        .padding(exercisePadding)  // Small padding
                        .frame(width: geometry.size.width,
                               height: geometry.size.height)
                        .position(x: geometry.size.width / 2,
                                  y: geometry.size.height / 2)
                        .scaleEffect(x: isFlipped ? -1 : 1, y: 1)
                        .allowsHitTesting(false)
                        .clipped()
                        .overlay(
                            // Add a subtle glow effect for better visibility
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .scaleEffect(exerciseScale)  // Same scale for glow
                                .padding(exercisePadding)
                                .frame(width: geometry.size.width,
                                       height: geometry.size.height)
                                .blur(radius: 25)
                                .opacity(opacity * 0.2)
                                .scaleEffect(x: isFlipped ? -1 : 1, y: 1)
                                .allowsHitTesting(false)
                                .clipped()
                        )
                        .background(
                            GeometryReader { imageGeometry in
                                Color.clear
                                    .onAppear {
                                        imageSize = imageGeometry.size
                                    }
                            }
                        )
                }
            }
        }
    }
    
    // Scale factor to make images larger while still fitting
    private var exerciseScale: CGFloat {
        switch exerciseType {
        case .pushup:
            return 1.50  // Scale up 50% for pushup
        case .pullup, .situp:
            return 1.40  // Scale up 40% for pullup and situp (with their added padding)
        case .run:
            return 1.45
        case .unknown:
            return 1.45
        }
    }
    
    // Add minimal padding
    private var exercisePadding: EdgeInsets {
        switch exerciseType {
        case .pushup:
            // Pushup already has visual padding in the image, so use very minimal padding
            return EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5)
        case .pullup, .situp:
            // Pullup and situp need a bit more padding to match pushup appearance
            return EdgeInsets(top: 15, leading: 15, bottom: 15, trailing: 15)
        case .run:
            // Running uses moderate padding
            return EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        case .unknown:
            return EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
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