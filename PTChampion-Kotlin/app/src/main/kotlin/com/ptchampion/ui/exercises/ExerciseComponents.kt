package com.ptchampion.ui.exercises

import android.Manifest
import android.content.pm.PackageManager
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.core.content.ContextCompat
import com.ptchampion.domain.model.Exercise
import kotlin.math.roundToInt

/**
 * Exercise header component
 */
@Composable
fun ExerciseHeader(
    exercise: Exercise,
    onNavigateBack: () -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically
            ) {
                IconButton(
                    onClick = onNavigateBack,
                    modifier = Modifier.size(24.dp)
                ) {
                    Icon(
                        imageVector = Icons.Default.ArrowBack,
                        contentDescription = "Back"
                    )
                }
                
                Text(
                    text = exercise.name,
                    style = MaterialTheme.typography.headlineSmall,
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier.padding(start = 8.dp)
                )
            }
            
            Spacer(modifier = Modifier.height(8.dp))
            
            Text(
                text = exercise.description,
                style = MaterialTheme.typography.bodyMedium
            )
        }
    }
}

/**
 * Camera permission request dialog
 */
@Composable
fun CameraPermissionRequest(
    onPermissionGranted: () -> Unit,
    onCancel: () -> Unit
) {
    val context = LocalContext.current
    val cameraPermissionLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { isGranted ->
        if (isGranted) {
            onPermissionGranted()
        } else {
            onCancel()
        }
    }
    
    val hasCameraPermission = ContextCompat.checkSelfPermission(
        context, Manifest.permission.CAMERA
    ) == PackageManager.PERMISSION_GRANTED
    
    if (hasCameraPermission) {
        onPermissionGranted()
    } else {
        AlertDialog(
            onDismissRequest = onCancel,
            title = { Text("Camera Permission Required") },
            text = {
                Text("The camera is needed to analyze your form during the exercise. Please grant camera permission to continue.")
            },
            confirmButton = {
                Button(
                    onClick = {
                        cameraPermissionLauncher.launch(Manifest.permission.CAMERA)
                    }
                ) {
                    Text("Grant Permission")
                }
            },
            dismissButton = {
                TextButton(
                    onClick = onCancel
                ) {
                    Text("Cancel")
                }
            }
        )
    }
}

/**
 * Exercise completion summary
 */
@Composable
fun ExerciseCompletionSummary(
    exerciseType: String,
    reps: Int,
    score: Int,
    onClose: () -> Unit
) {
    Column(
        modifier = Modifier.padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = "Exercise Complete!",
            style = MaterialTheme.typography.headlineSmall,
            fontWeight = FontWeight.Bold
        )
        
        Spacer(modifier = Modifier.height(24.dp))
        
        Text(
            text = score.toString(),
            style = MaterialTheme.typography.displayLarge,
            fontWeight = FontWeight.Bold
        )
        
        Text(
            text = "Your Score",
            style = MaterialTheme.typography.titleMedium
        )
        
        Spacer(modifier = Modifier.height(24.dp))
        
        Text(
            text = "You completed $reps ${if (reps == 1) getExerciseSingular(exerciseType) else exerciseType}!",
            style = MaterialTheme.typography.bodyLarge,
            textAlign = TextAlign.Center
        )
        
        Spacer(modifier = Modifier.height(8.dp))
        
        Text(
            text = getScoreRating(score),
            style = MaterialTheme.typography.titleMedium,
            color = getScoreColor(score)
        )
        
        Spacer(modifier = Modifier.height(32.dp))
        
        Button(
            onClick = onClose,
            modifier = Modifier.fillMaxWidth()
        ) {
            Text("Done")
        }
    }
}

/**
 * Helper function to convert exercise type to singular form
 */
private fun getExerciseSingular(exerciseType: String): String {
    return when (exerciseType.lowercase()) {
        "pushups" -> "pushup"
        "pullups" -> "pullup"
        "situps" -> "situp"
        else -> exerciseType
    }
}

/**
 * Get color based on score
 */
@Composable
fun getScoreColor(score: Int): androidx.compose.ui.graphics.Color {
    return when {
        score >= 90 -> MaterialTheme.colorScheme.primary
        score >= 80 -> MaterialTheme.colorScheme.tertiary
        score >= 65 -> MaterialTheme.colorScheme.secondary
        score >= 50 -> MaterialTheme.colorScheme.tertiary.copy(alpha = 0.7f)
        else -> MaterialTheme.colorScheme.error
    }
}

/**
 * Get score rating text
 */
fun getScoreRating(score: Int): String {
    return when {
        score >= 90 -> "Excellent"
        score >= 80 -> "Good"
        score >= 65 -> "Satisfactory"
        score >= 50 -> "Marginal"
        else -> "Poor"
    }
}

/**
 * Rotate bitmap for camera preview
 */
fun rotateBitmap(bitmap: android.graphics.Bitmap, rotationDegrees: Float): android.graphics.Bitmap {
    val matrix = android.graphics.Matrix()
    matrix.postRotate(rotationDegrees)
    return android.graphics.Bitmap.createBitmap(
        bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true
    )
}

/**
 * Extension function to convert ImageProxy to Bitmap
 */
fun androidx.camera.core.ImageProxy.toBitmap(): android.graphics.Bitmap {
    val buffer = planes[0].buffer
    buffer.rewind()
    val bytes = ByteArray(buffer.capacity())
    buffer.get(bytes)
    val bitmap = android.graphics.BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
    
    return when (imageInfo.rotationDegrees) {
        0 -> bitmap
        else -> rotateBitmap(bitmap, imageInfo.rotationDegrees.toFloat())
    }
}