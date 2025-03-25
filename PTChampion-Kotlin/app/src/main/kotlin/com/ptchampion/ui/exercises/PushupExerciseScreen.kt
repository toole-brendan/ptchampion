package com.ptchampion.ui.exercises

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Matrix
import android.view.ViewGroup
import android.widget.LinearLayout
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageProxy
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Stop
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLifecycleOwner
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.content.ContextCompat
import com.ptchampion.data.posedetection.PoseDetectionService
import com.ptchampion.domain.model.Exercise
import com.ptchampion.domain.model.PushupState
import java.util.concurrent.Executors
import kotlin.math.roundToInt

/**
 * Pushup exercise screen
 */
@Composable
fun PushupExerciseScreen(
    exercise: Exercise,
    uiState: ExerciseUiState,
    onNavigateBack: () -> Unit,
    onStartExercise: () -> Unit,
    onUpdateState: (PushupState) -> Unit,
    onCompleteExercise: (Int) -> Unit
) {
    val context = LocalContext.current
    val lifecycleOwner = LocalLifecycleOwner.current
    var showPermissionDialog by remember { mutableStateOf(false) }
    var cameraPreviewView by remember { mutableStateOf<PreviewView?>(null) }
    var isAnalyzing by remember { mutableStateOf(false) }
    
    // Completion dialog
    if (uiState.isExerciseComplete) {
        AlertDialog(
            onDismissRequest = { },
            title = { Text("Exercise Complete") },
            text = {
                ExerciseCompletionSummary(
                    exerciseType = exercise.type,
                    reps = uiState.pushupState.count,
                    score = calculatePushupScore(uiState.pushupState.count),
                    onClose = onNavigateBack
                )
            },
            confirmButton = { }
        )
    }
    
    Column(
        modifier = Modifier.fillMaxSize()
    ) {
        ExerciseHeader(
            exercise = exercise,
            onNavigateBack = onNavigateBack
        )
        
        if (!uiState.isExerciseStarted) {
            // Exercise instructions
            Box(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxWidth()
                    .padding(16.dp),
                contentAlignment = Alignment.Center
            ) {
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Text(
                        text = "Get ready for Push-ups",
                        style = MaterialTheme.typography.headlineSmall,
                        fontWeight = FontWeight.Bold
                    )
                    
                    Spacer(modifier = Modifier.height(16.dp))
                    
                    Text(
                        text = "Position your device so that your full body is visible in the camera. " +
                                "The app will count your reps and analyze your form.",
                        style = MaterialTheme.typography.bodyLarge,
                        textAlign = TextAlign.Center
                    )
                    
                    Spacer(modifier = Modifier.height(32.dp))
                    
                    Button(
                        onClick = {
                            showPermissionDialog = true
                        },
                        modifier = Modifier.fillMaxWidth(0.7f)
                    ) {
                        Icon(
                            imageVector = Icons.Default.PlayArrow,
                            contentDescription = "Start"
                        )
                        Spacer(modifier = Modifier.size(8.dp))
                        Text("Start Exercise")
                    }
                }
            }
        } else {
            // Camera preview with pose detection
            Box(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp),
                contentAlignment = Alignment.Center
            ) {
                // Camera preview
                AndroidView(
                    factory = { ctx ->
                        PreviewView(ctx).apply {
                            layoutParams = LinearLayout.LayoutParams(
                                ViewGroup.LayoutParams.MATCH_PARENT,
                                ViewGroup.LayoutParams.MATCH_PARENT
                            )
                            scaleType = PreviewView.ScaleType.FIT_CENTER
                            implementationMode = PreviewView.ImplementationMode.COMPATIBLE
                            cameraPreviewView = this
                        }
                    },
                    modifier = Modifier
                        .fillMaxSize()
                        .clip(RoundedCornerShape(12.dp))
                        .border(
                            width = 2.dp,
                            color = MaterialTheme.colorScheme.outline,
                            shape = RoundedCornerShape(12.dp)
                        )
                )
                
                // Pose skeleton overlay
                if (isAnalyzing) {
                    PoseOverlay(uiState.pushupState)
                }
                
                // Exercise feedback
                Card(
                    modifier = Modifier
                        .align(Alignment.TopCenter)
                        .padding(top = 16.dp)
                ) {
                    Column(
                        modifier = Modifier.padding(16.dp),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Text(
                            text = "Count: ${uiState.pushupState.count}",
                            style = MaterialTheme.typography.headlineMedium,
                            fontWeight = FontWeight.Bold
                        )
                        
                        Spacer(modifier = Modifier.height(4.dp))
                        
                        Text(
                            text = uiState.pushupState.feedback,
                            style = MaterialTheme.typography.bodyMedium,
                            textAlign = TextAlign.Center
                        )
                    }
                }
                
                // Stop button
                OutlinedButton(
                    onClick = {
                        onCompleteExercise(uiState.pushupState.count)
                    },
                    modifier = Modifier
                        .align(Alignment.BottomCenter)
                        .padding(bottom = 16.dp)
                ) {
                    Icon(
                        imageVector = Icons.Default.Stop,
                        contentDescription = "Stop"
                    )
                    Spacer(modifier = Modifier.size(8.dp))
                    Text("Complete Exercise")
                }
            }
        }
    }
    
    // Camera permission handling
    if (showPermissionDialog) {
        CameraPermissionRequest(
            onPermissionGranted = {
                showPermissionDialog = false
                onStartExercise()
                startCamera(context, lifecycleOwner, onUpdateState)
                isAnalyzing = true
            },
            onCancel = {
                showPermissionDialog = false
            }
        )
    }
    
    // Clean up camera when leaving the screen
    DisposableEffect(Unit) {
        onDispose {
            isAnalyzing = false
        }
    }
}

/**
 * Start the camera with pose detection
 */
private fun startCamera(
    context: Context,
    lifecycleOwner: androidx.lifecycle.LifecycleOwner,
    onUpdateState: (PushupState) -> Unit
) {
    val cameraProviderFuture = ProcessCameraProvider.getInstance(context)
    val poseDetectionService = PoseDetectionService(context)
    var lastState = PushupState()
    
    cameraProviderFuture.addListener({
        val cameraProvider = cameraProviderFuture.get()
        
        val preview = Preview.Builder().build()
        val cameraSelector = CameraSelector.DEFAULT_BACK_CAMERA
        
        val imageAnalysis = ImageAnalysis.Builder()
            .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
            .build()
        
        val executor = Executors.newSingleThreadExecutor()
        
        imageAnalysis.setAnalyzer(executor) { imageProxy ->
            val rotationDegrees = imageProxy.imageInfo.rotationDegrees
            
            // Convert to bitmap for ML Kit processing
            val bitmap = imageProxy.toBitmap()
            val rotatedBitmap = rotateBitmap(bitmap, rotationDegrees.toFloat())
            
            // Process on a background thread
            executor.execute {
                // Detect pose using ML Kit
                poseDetectionService.detectPose(rotatedBitmap)?.let { pose ->
                    // Analyze pushup motion
                    val newState = poseDetectionService.detectPushup(pose, lastState)
                    lastState = newState
                    
                    // Update UI
                    onUpdateState(newState)
                }
                
                // Close the image proxy
                imageProxy.close()
            }
        }
        
        try {
            // Unbind all use cases before rebinding
            cameraProvider.unbindAll()
            
            // Bind use cases to camera
            cameraProvider.bindToLifecycle(
                lifecycleOwner,
                cameraSelector,
                preview,
                imageAnalysis
            )
            
            // Attach the preview to the PreviewView
            preview.setSurfaceProvider(cameraPreviewView?.surfaceProvider)
            
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }, ContextCompat.getMainExecutor(context))
}

/**
 * Convert ImageProxy to Bitmap
 */
private fun ImageProxy.toBitmap(): Bitmap {
    val buffer = planes[0].buffer
    val bytes = ByteArray(buffer.remaining())
    buffer.get(bytes)
    return android.graphics.BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
}

/**
 * Rotate bitmap to correct orientation
 */
private fun rotateBitmap(bitmap: Bitmap, rotationDegrees: Float): Bitmap {
    val matrix = Matrix().apply {
        postRotate(rotationDegrees)
    }
    return Bitmap.createBitmap(
        bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true
    )
}

/**
 * Pose skeleton overlay
 */
@Composable
fun PoseOverlay(pushupState: PushupState) {
    val upColor = if (pushupState.isUp) Color.Green else Color.Gray
    val downColor = if (pushupState.isDown) Color.Red else Color.Gray
    
    Canvas(modifier = Modifier.fillMaxSize()) {
        // Draw indicators for up and down positions
        drawCircle(
            color = upColor,
            radius = 20f,
            center = Offset(size.width * 0.8f, size.height * 0.2f),
            style = Stroke(width = 4f, cap = StrokeCap.Round)
        )
        
        drawCircle(
            color = downColor,
            radius = 20f,
            center = Offset(size.width * 0.8f, size.height * 0.8f),
            style = Stroke(width = 4f, cap = StrokeCap.Round)
        )
    }
}

/**
 * Calculate pushup score
 * - 100 points = 77 reps
 * - 50 points = 40 reps
 */
private fun calculatePushupScore(reps: Int): Int {
    return when {
        reps >= 77 -> 100
        reps <= 0 -> 0
        else -> ((reps - 3) * 100) / 74
    }.coerceIn(0, 100)
}