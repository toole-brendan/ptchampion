package com.example.ptchampion.posedetection

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import com.example.ptchampion.domain.exercise.utils.landmarks
import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarkerResult

/**
 * A composable that draws pose landmarks as an overlay
 * 
 * @param poseResult The pose detection result from MediaPipe
 * @param sourceInfo Size information about the source image (width, height)
 * @param modifier Modifier for the canvas
 */
@Composable
fun PoseOverlay(
    poseResult: PoseLandmarkerResult?,
    sourceInfo: Pair<Int, Int>,
    modifier: Modifier = Modifier
) {
    Canvas(modifier = modifier.fillMaxSize()) {
        if (poseResult == null || poseResult.landmarks().isEmpty()) return@Canvas
        
        val landmarks = poseResult.landmarks // Use extension property
        
        // Scale factors for converting from normalized coordinates to canvas coordinates
        val scaleX = size.width
        val scaleY = size.height
        
        // Draw landmarks
        landmarks.forEachIndexed { index, landmark ->
            val x = landmark.x() * scaleX
            val y = landmark.y() * scaleY
            
            // Draw a circle for each landmark
            drawCircle(
                color = Color.Green,
                radius = 8f,
                center = Offset(x, y),
                style = Stroke(width = 2f)
            )
        }
        
        // Define connections between landmarks to draw lines
        val connections = listOf(
            // Face
            Pair(0, 1), Pair(1, 2), Pair(2, 3), Pair(3, 7),
            Pair(0, 4), Pair(4, 5), Pair(5, 6), Pair(6, 8),
            // Upper body
            Pair(9, 10),
            Pair(11, 12), Pair(11, 13), Pair(13, 15),
            Pair(12, 14), Pair(14, 16),
            // Lower body
            Pair(11, 23), Pair(12, 24), Pair(23, 24),
            Pair(23, 25), Pair(24, 26), Pair(25, 27), Pair(26, 28),
            // Feet
            Pair(27, 29), Pair(27, 31), Pair(28, 30), Pair(28, 32)
        )
        
        // Draw connections
        connections.forEach { (start, end) ->
            if (start < landmarks.size && end < landmarks.size) {
                val startLandmark = landmarks[start]
                val endLandmark = landmarks[end]
                
                drawLine(
                    color = Color.Yellow,
                    start = Offset(startLandmark.x() * scaleX, startLandmark.y() * scaleY),
                    end = Offset(endLandmark.x() * scaleX, endLandmark.y() * scaleY),
                    strokeWidth = 3f,
                    cap = StrokeCap.Round
                )
            }
        }
    }
} 