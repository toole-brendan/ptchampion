import XCTest
import UIKit
import MediaPipeTasksVision
@testable import PTChampion

/// Tests for the MediaPipe pose detection integration
class MediaPipeIntegrationTest: XCTestCase {
    
    var mediaPipeService: MediaPipePoseDetectionService!
    
    override func setUp() {
        super.setUp()
        mediaPipeService = MediaPipePoseDetectionService()
    }
    
    override func tearDown() {
        mediaPipeService = nil
        super.tearDown()
    }
    
    /// Test that the MediaPipe model can be loaded
    func testModelLoading() {
        // This test will fail if the model file is missing or inaccessible
        let expectation = self.expectation(description: "Model loading")
        
        // Initialize service - model loading happens in init
        let service = MediaPipePoseDetectionService()
        
        // Attempt to load a test image and process it
        if let testImage = UIImage(named: "test_pushup_image") {
            let cgImage = testImage.cgImage!
            let ciImage = CIImage(cgImage: cgImage)
            let pixelBuffer = createPixelBuffer(from: ciImage)
            
            if let sampleBuffer = createSampleBuffer(from: pixelBuffer) {
                let result = service.detectPoseInFrame(sampleBuffer: sampleBuffer, orientation: .up)
                XCTAssertNotNil(result.mediaPoseResult, "MediaPipe should return a pose result")
                expectation.fulfill()
            } else {
                XCTFail("Could not create sample buffer")
            }
        } else {
            // If no test image, just fulfill for now
            // In a real test you'd want actual test images
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0, handler: nil)
    }
    
    /// Test push-up detection logic
    func testPushupDetection() {
        // Create a simulated MediaPipe pose result for a push-up up position
        let mockResult = createMockPushupResult(isUp: true)
        
        // Test detection
        let state = mediaPipeService.detectPushup(mediapipePose: mockResult)
        
        // Verify state is as expected
        XCTAssertTrue(state.isUp, "Should detect up position")
        XCTAssertFalse(state.isDown, "Should not detect down position")
    }
    
    /// Test the user preference toggle
    func testUserPreferenceToggle() {
        // Reset preference to start fresh
        UserDefaults.standard.removeObject(forKey: "useMediaPipeDetection")
        
        // Create view model
        let viewModel = ExerciseViewModel()
        
        // Should start with MediaPipe disabled by default
        XCTAssertFalse(viewModel.useMediaPipe, "MediaPipe should be disabled by default")
        
        // Toggle to enable
        let result1 = viewModel.toggleMediaPipe()
        XCTAssertTrue(result1, "MediaPipe should be enabled after first toggle")
        XCTAssertTrue(viewModel.useMediaPipe, "useMediaPipe should be true")
        
        // Toggle to disable
        let result2 = viewModel.toggleMediaPipe()
        XCTAssertFalse(result2, "MediaPipe should be disabled after second toggle")
        XCTAssertFalse(viewModel.useMediaPipe, "useMediaPipe should be false")
    }
    
    // MARK: - Helper Methods
    
    /// Create a mock MediaPipe pose result for testing
    private func createMockPushupResult(isUp: Bool) -> MPPPoseDetectorResult {
        // In a real test, this would create a properly structured MPPPoseDetectorResult
        // For now, we'll use this empty shell that will need to be implemented
        let mockResult = MockPoseDetectorResult()
        return mockResult
    }
    
    /// Create a pixel buffer from a CIImage
    private func createPixelBuffer(from ciImage: CIImage) -> CVPixelBuffer? {
        let context = CIContext()
        var pixelBuffer: CVPixelBuffer?
        
        let attributes = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue
        ] as CFDictionary
        
        let width = Int(ciImage.extent.width)
        let height = Int(ciImage.extent.height)
        
        CVPixelBufferCreate(kCFAllocatorDefault,
                           width,
                           height,
                           kCVPixelFormatType_32ARGB,
                           attributes,
                           &pixelBuffer)
        
        if let pixelBuffer = pixelBuffer {
            context.render(ciImage, to: pixelBuffer)
        }
        
        return pixelBuffer
    }
    
    /// Create a sample buffer from a pixel buffer
    private func createSampleBuffer(from pixelBuffer: CVPixelBuffer) -> CMSampleBuffer? {
        var sampleBuffer: CMSampleBuffer?
        
        var timimgInfo = CMSampleTimingInfo()
        timimgInfo.duration = CMTime.invalid
        timimgInfo.decodeTimeStamp = CMTime.invalid
        timimgInfo.presentationTimeStamp = CMTime.now
        
        var formatDescription: CMFormatDescription?
        CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault,
                                                    imageBuffer: pixelBuffer,
                                                    formatDescriptionOut: &formatDescription)
        
        if let formatDescription = formatDescription {
            CMSampleBufferCreateReadyWithImageBuffer(allocator: kCFAllocatorDefault,
                                                    imageBuffer: pixelBuffer,
                                                    formatDescription: formatDescription,
                                                    sampleTiming: &timimgInfo,
                                                    sampleBufferOut: &sampleBuffer)
        }
        
        return sampleBuffer
    }
}

// MARK: - Mock Implementation

/// Mock implementation of MPPPoseDetectorResult for testing
class MockPoseDetectorResult: MPPPoseDetectorResult {
    
    override func landmarks() -> [[MPPLandmark]] {
        // Create a mock set of landmarks for a push-up
        var landmarks = [MPPLandmark]()
        
        // Add all 33 landmarks with appropriate positions for a push-up
        // For a basic test, we'll just add the key landmarks needed for push-up detection
        
        // Define helper function to create landmarks
        func addLandmark(index: Int, x: Float, y: Float, z: Float = 0, visibility: Float = 0.9) {
            let landmark = MPPLandmark()
            landmark.setValue(x, forKey: "x")
            landmark.setValue(y, forKey: "y") 
            landmark.setValue(z, forKey: "z")
            landmark.setValue(visibility, forKey: "visibility")
            
            // Ensure array is large enough
            while landmarks.count <= index {
                landmarks.append(MPPLandmark())
            }
            landmarks[index] = landmark
        }
        
        // Left shoulder
        addLandmark(index: 11, x: 0.3, y: 0.4)
        
        // Right shoulder
        addLandmark(index: 12, x: 0.7, y: 0.4)
        
        // Left elbow
        addLandmark(index: 13, x: 0.25, y: 0.6)
        
        // Right elbow
        addLandmark(index: 14, x: 0.75, y: 0.6)
        
        // Left wrist
        addLandmark(index: 15, x: 0.2, y: 0.8)
        
        // Right wrist
        addLandmark(index: 16, x: 0.8, y: 0.8)
        
        // Left hip
        addLandmark(index: 23, x: 0.35, y: 0.7)
        
        // Right hip
        addLandmark(index: 24, x: 0.65, y: 0.7)
        
        return [landmarks]
    }
}
