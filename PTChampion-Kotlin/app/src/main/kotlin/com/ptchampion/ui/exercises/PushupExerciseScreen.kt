package com.ptchampion.ui.exercises

import android.content.Context
import android.view.ViewGroup
import android.widget.LinearLayout
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.border
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
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.StarOutline
import androidx.compose.material.icons.filled.Stop
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
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
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.content.ContextCompat
import com.ptchampion.data.posedetection.PoseDetectionManager
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
    onCompleteExercise: (Int) -> Unit,
    onTogglePoseDetection: () -> Unit
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
        // Header with back button and detection toggle
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Back button
            IconButton(onClick = onNavigateBack) {
                Icon(
                    imageVector = Icons.Default.ArrowBack,
                    contentDescription = "Back"
                )
            }
            
            // Title
            Text(
                text = "Push-ups",
                style = MaterialTheme.typography.headlineSmall,
                fontWeight = FontWeight.Bold,
                modifier = Modifier.weight(1f)
            )
            
            // Detection toggle button
            IconButton(onClick = onTogglePoseDetection) {
                Icon(
                    imageVector = if (uiState.useMediaPipeDetection) Icons.Default.Star else Icons.Default.StarOutline,
                    contentDescription = "Toggle detection system",
                    tint = if (uiState.useMediaPipeDetection) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurface
                )
            }
        }
        
        // Detection system indicator
        Text(
            text = "Using: ${if (uiState.useMediaPipeDetection) "MediaPipe" else "ML Kit"}",
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp),
            textAlign = TextAlign.End
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
                        text = "Position your device so that your full body is visible from the side. " +
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
                    PushupPoseOverlay(uiState.pushupState)
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
                startPushupCamera(
                    context, 
                    lifecycleOwner, 
                    onUpdateState, 
                    cameraPreviewView,
                    uiState.useMediaPipeDetection
                )
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
 * Start the camera with pose detection for pushups
 */
private fun startPushupCamera(
    context: Context,
    lifecycleOwner: androidx.lifecycle.LifecycleOwner,
    onUpdateState: (PushupState) -> Unit,
    cameraPreviewView: PreviewView?,
    useMediaPipe: Boolean
) {
    val cameraProviderFuture = ProcessCameraProvider.getInstance(context)
    
    // Use dependency injection in real app
    val poseDetectionManager = PoseDetectionManager(
        context,
        PoseDetectionService(context),
        MediaPipePoseDetectionService(context)
    )
    
    // Set detection system
    poseDetectionManager.useMediaPipe = useMediaPipe
    
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
            
            // Convert to bitmap for processing
            val bitmap = imageProxy.toBitmap()
            val rotatedBitmap = rotateBitmap(bitmap, rotationDegrees.toFloat())
            
            // Process on a background thread
            executor.execute {
                // Detect pose using the selected detection system
                val poseResult = poseDetectionManager.detectPose(rotatedBitmap)
                
                // Analyze pushup motion with the appropriate detector
                val newState = poseDetectionManager.detectPushup(poseResult, lastState)
                lastState = newState
                
                // Update UI
                onUpdateState(newState)
                
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
 * Pushup pose skeleton overlay
 */
@Composable
fun PushupPoseOverlay(pushupState: PushupState) {
    val upColor = if (pushupState.isUp) Color.Green else Color.Gray
    val downColor = if (pushupState.isDown) Color.Red else Color.Gray
    
    Canvas(modifier = Modifier.fillMaxSize()) {
        // Draw indicators for up and down positions
        drawCircle(
            color = upColor,
            radius = 20f,
            center = Offset(size.width * 0.8f, size.height * 0.3f),
            style = Stroke(width = 4f, cap = StrokeCap.Round)
        )
        
        drawCircle(
            color = downColor,
            radius = 20f,
            center = Offset(size.width * 0.8f, size.height * 0.7f),
            style = Stroke(width = 4f, cap = StrokeCap.Round)
        )
    }
}

/**
 * Calculate pushup score
 * - 100 points = 60 reps
 * - 50 points = 30 reps
 */
private fun calculatePushupScore(reps: Int): Int {
    return when {
        reps >= 60 -> 100
        reps <= 0 -> 0
        else -> ((reps - 10) * 100) / 50
    }.coerceIn(0, 100)
}
