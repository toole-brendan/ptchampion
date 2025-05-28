import SwiftUI
import PTDesignSystem

/// View that displays PNG overlay guides for exercise positioning
struct PNGOverlayView: View {
    let exerciseType: ExerciseType
    let opacity: Double
    @State private var imageSize: CGSize = .zero
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let image = exerciseImage {
                    // Main overlay image - Made significantly larger
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .opacity(opacity)
                        .frame(maxWidth: geometry.size.width * 1.5,  // Increased from 1.2 to 1.5 (150% of screen width)
                               maxHeight: geometry.size.height * 1.3) // Increased from 1.1 to 1.3 (130% of screen height)
                        .position(x: geometry.size.width / 2,
                                  y: geometry.size.height / 2)
                        .allowsHitTesting(false)
                        .overlay(
                            // Add a subtle glow effect for better visibility
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: geometry.size.width * 1.5,
                                       maxHeight: geometry.size.height * 1.3)
                                .blur(radius: 20)
                                .opacity(opacity * 0.5)
                                .allowsHitTesting(false)
                        )
                        .background(
                            GeometryReader { imageGeometry in
                                Color.clear
                                    .onAppear {
                                        imageSize = imageGeometry.size
                                    }
                            }
                        )
                        .clipped()
                }
            }
        }
        .clipped()
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
            PNGOverlayView(exerciseType: .pushup, opacity: 0.5)
                .previewDisplayName("Push-up Overlay")
            
            PNGOverlayView(exerciseType: .situp, opacity: 0.5)
                .previewDisplayName("Sit-up Overlay")
            
            PNGOverlayView(exerciseType: .pullup, opacity: 0.5)
                .previewDisplayName("Pull-up Overlay")
        }
        .background(Color.black)
    }
} 