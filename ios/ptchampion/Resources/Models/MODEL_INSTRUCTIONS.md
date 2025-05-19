# BlazePose Model Instructions

## Required Model
Download the MediaPipe BlazePose PoseLandmarker model and place it in this directory:

- Full Model: `pose_landmarker_full.task` (~9MB size) - Recommended for best accuracy
- Download from: https://developers.google.com/mediapipe/solutions/vision/pose_landmarker/

## Manual Download Steps
1. Visit the MediaPipe model download page: https://developers.google.com/mediapipe/solutions/vision/pose_landmarker
2. Download the "Full" model (pose_landmarker_full.task)
3. Place the downloaded .task file in this directory (ios/ptchampion/Resources/Models/)
4. Ensure the file is included in the app bundle by adding it to your Xcode project in this group

## Alternative Models
- Lite Model: `pose_landmarker_lite.task` (~2MB) - Faster but less accurate
- Heavy Model: `pose_landmarker_heavy.task` (~14MB) - Most accurate but slower

Choose the model that best balances accuracy and performance for your deployment needs. 