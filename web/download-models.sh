#!/bin/bash

# Create directory structure
mkdir -p public/models

# Download face landmarker model
curl -L "https://storage.googleapis.com/mediapipe-models/face_landmarker/face_landmarker/float16/1/face_landmarker.task" -o public/models/face_landmarker.task

# Download hand landmarker model
curl -L "https://storage.googleapis.com/mediapipe-models/hand_landmarker/hand_landmarker/float16/1/hand_landmarker.task" -o public/models/hand_landmarker.task

# Download pose landmarker lite model (in case it's missing or outdated)
curl -L "https://storage.googleapis.com/mediapipe-models/pose_landmarker/pose_landmarker_lite/float16/1/pose_landmarker_lite.task" -o public/models/pose_landmarker_lite.task

echo "Model download complete!" 