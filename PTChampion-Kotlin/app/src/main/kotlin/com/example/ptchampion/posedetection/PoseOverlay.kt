package com.example.ptchampion.posedetection

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.unit.dp
// import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarker // Comment out MP import
// import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarkerResult // Comment out MP import
import kotlin.math.max
import kotlin.math.min

// Based on MediaPipe example: https://github.com/googlesamples/mediapipe/blob/main/examples/pose_landmarker/android/app/src/main/java/com/google/mediapipe/examples/poselandmarker/OverlayView.kt

@Composable
fun PoseOverlay(
    resultBundle: PoseLandmarkerHelper.ResultBundle,
    modifier: Modifier = Modifier
) {
    // val results = resultBundle.results // results uses MP type, comment out
    // val imageWidth = resultBundle.inputImageWidth
    // val imageHeight = resultBundle.inputImageHeight

    // We expect only one pose detection result in live stream mode
    // if (results.landmarks().isNotEmpty()) { // Comment out check using MP type
    if (false) { // Temporarily disable drawing logic
        // val landmarks = results.landmarks()[0] // Comment out landmarks access

        Canvas(modifier = modifier.fillMaxSize()) { // Use passed modifier
            // val canvasWidth = size.width
            // val canvasHeight = size.height
            // ...rest of drawing logic...
            /*
            // Draw Landmarks (circles)
            landmarks.forEach { normalizedLandmark ->
                // Only draw if landmark is visible (within normalized bounds)
                if (normalizedLandmark.visibility().orElse(0f) > 0.5f) { // Threshold for visibility
                    val x = min(canvasWidth, max(0f, normalizedLandmark.x() * scaledWidth + xOffset))
                    val y = min(canvasHeight, max(0f, normalizedLandmark.y() * scaledHeight + yOffset))
                    drawCircle(
                        color = Color.Blue, // Landmark color
                        radius = 8f,       // Landmark radius
                        center = Offset(x, y),
                        style = Stroke(width = 4f) // Outline
                    )
                }
            }

            // Draw Connections (lines)
            PoseLandmarker.POSE_LANDMARKS.forEach { connection ->
                val startLandmark = landmarks[connection.start()]
                val endLandmark = landmarks[connection.end()]

                // Check visibility of both connected landmarks
                if (startLandmark.visibility().orElse(0f) > 0.5f && endLandmark.visibility().orElse(0f) > 0.5f) {
                    val startX = min(canvasWidth, max(0f, startLandmark.x() * scaledWidth + xOffset))
                    val startY = min(canvasHeight, max(0f, startLandmark.y() * scaledHeight + yOffset))
                    val endX = min(canvasWidth, max(0f, endLandmark.x() * scaledWidth + xOffset))
                    val endY = min(canvasHeight, max(0f, endLandmark.y() * scaledHeight + yOffset))

                    drawLine(
                        color = Color.Green, // Connection color
                        start = Offset(startX, startY),
                        end = Offset(endX, endY),
                        strokeWidth = 6f,   // Connection line thickness
                        cap = StrokeCap.Round // Rounded line ends
                    )
                }
            }
            */
        }
    }
} 