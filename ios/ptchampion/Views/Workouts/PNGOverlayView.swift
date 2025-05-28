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
                    // Main overlay image - Fill entire screen
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .opacity(opacity)
                        .frame(width: geometry.size.width,
                               height: geometry.size.height)
                        .position(x: geometry.size.width / 2,
                                  y: geometry.size.height / 2)
                        .allowsHitTesting(false)
                        .clipped()
                        .overlay(
                            // Add a subtle glow effect for better visibility
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: geometry.size.width,
                                       height: geometry.size.height)
                                .blur(radius: 25)
                                .opacity(opacity * 0.2)
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