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
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .opacity(opacity)
                        .frame(maxWidth: geometry.size.width * 0.8,
                               maxHeight: geometry.size.height * 0.8)
                        .position(x: geometry.size.width / 2,
                                  y: geometry.size.height / 2)
                        .allowsHitTesting(false)
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
        let imageName: String
        switch exerciseType {
        case .pushup:
            imageName = "pushup_position"
        case .situp:
            imageName = "situp_position"
        case .pullup:
            imageName = "pullup_position"
        case .run, .unknown:
            imageName = "unknown_position"
        }
        
        // Try multiple variations of the image name
        if let image = UIImage(named: imageName) {
            return image
        } else if let image = UIImage(named: "\(exerciseType.rawValue)_position") {
            return image
        } else if let image = UIImage(named: exerciseType.rawValue) {
            return image
        }
        
        print("WARNING: Could not find PNG overlay image for \(exerciseType.rawValue)")
        return nil
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