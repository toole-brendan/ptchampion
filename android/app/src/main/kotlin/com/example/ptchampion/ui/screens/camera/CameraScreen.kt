package com.example.ptchampion.ui.screens.camera

import android.Manifest
import android.content.Context
import android.util.Log
import android.widget.Toast
import androidx.camera.core.CameraSelector
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.compose.foundation.layout.*
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLifecycleOwner
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.content.ContextCompat
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.lifecycle.LifecycleOwner
import com.example.ptchampion.posedetection.PoseOverlay
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Pause
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Stop
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.FlipCameraAndroid
import androidx.compose.foundation.shape.CircleShape
import com.example.ptchampion.ui.theme.PtAccent
import com.example.ptchampion.ui.theme.PtCommandBlack
import com.example.ptchampion.ui.theme.PtSecondaryText
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.camera.core.ImageProxy
import androidx.camera.core.ImageAnalysis
import com.google.accompanist.permissions.rememberPermissionState
import com.google.accompanist.permissions.ExperimentalPermissionsApi
import com.google.accompanist.permissions.isGranted
import com.google.accompanist.permissions.shouldShowRationale
import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarkerResult

// Create a helper class to handle the Camera functionality with stubs
class CameraHelper {
    companion object {
        fun createCamera(context: Context): ProcessCameraProvider {
            return ProcessCameraProvider.getInstance(context).get()
        }
    }
}

@OptIn(ExperimentalPermissionsApi::class)
@Composable
fun CameraScreen(
    exerciseId: Int,
    exerciseType: String?,
    viewModel: CameraViewModel = hiltViewModel(),
    onWorkoutComplete: () -> Unit // Callback to navigate back
) {
    val context = LocalContext.current
    val lifecycleOwner = LocalLifecycleOwner.current
    
    // Use a helper method to create the camera provider
    val cameraProvider = remember { CameraHelper.createCamera(context) }
    val cameraExecutor = remember { Executors.newSingleThreadExecutor() }

    val uiState by viewModel.uiState.collectAsState()
    var sourceInfo by remember { mutableStateOf(Pair(0, 0)) } // Width, Height
    
    // Track latest pose detection result for overlay
    var latestPoseResult by remember { mutableStateOf<PoseLandmarkerResult?>(null) }

    // Handle camera permissions
    val cameraPermissionState = rememberPermissionState(Manifest.permission.CAMERA)
    val hasPermission = cameraPermissionState.status.isGranted

    // Effect to navigate back when workout is successfully saved
    LaunchedEffect(uiState.feedback) {
        if (uiState.feedback == "Workout Saved Successfully!") {
            Toast.makeText(context, "Workout Saved!", Toast.LENGTH_SHORT).show()
            kotlinx.coroutines.delay(500) // Brief delay to show message
            onWorkoutComplete()
        }
    }

    // Main content based on permission status
    Scaffold { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            if (hasPermission) {
                // Show camera content when permission is granted
                CameraContent(
                    context = context,
                    lifecycleOwner = lifecycleOwner,
                    cameraProvider = cameraProvider,
                    cameraExecutor = cameraExecutor,
                    uiState = uiState,
                    viewModel = viewModel,
                    sourceInfo = sourceInfo,
                    onSourceInfoUpdate = { sourceInfo = it },
                    latestPoseResult = latestPoseResult,
                    onPoseResultUpdate = { latestPoseResult = it }
                )
            } else {
                // Show permission request UI
                PermissionRequestScreen(
                    onRequestPermission = { cameraPermissionState.launchPermissionRequest() },
                    showRationale = cameraPermissionState.status.shouldShowRationale
                )
            }
        }
    }

    // Cleanup camera executor
    DisposableEffect(Unit) {
        onDispose {
            cameraExecutor.shutdown()
        }
    }
}

@Composable
private fun PermissionRequestScreen(
    onRequestPermission: () -> Unit,
    showRationale: Boolean
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Text(
            text = if (showRationale) {
                "Camera access is required to analyze your exercises. Please grant the permission in app settings."
            } else {
                "Camera permission is required to analyze exercises."
            },
            style = MaterialTheme.typography.bodyLarge,
            textAlign = androidx.compose.ui.text.style.TextAlign.Center
        )
        Spacer(modifier = Modifier.height(16.dp))
        
        if (!showRationale) {
            Button(
                onClick = onRequestPermission,
                colors = ButtonDefaults.buttonColors(
                    containerColor = PtAccent,
                    contentColor = PtCommandBlack
                )
            ) {
                Text("Grant Permission")
            }
        }
    }
}

@Composable
private fun CameraContent(
    context: Context,
    lifecycleOwner: LifecycleOwner,
    cameraProvider: ProcessCameraProvider,
    cameraExecutor: ExecutorService,
    uiState: CameraUiState,
    viewModel: CameraViewModel,
    sourceInfo: Pair<Int, Int>,
    onSourceInfoUpdate: (Pair<Int, Int>) -> Unit,
    latestPoseResult: PoseLandmarkerResult?,
    onPoseResultUpdate: (PoseLandmarkerResult?) -> Unit
) {
    Box(modifier = Modifier.fillMaxSize()) {
        // Camera Preview
        AndroidView(
            factory = { ctx ->
                val previewView = PreviewView(ctx)
                // Restore CameraX logic
                val preview = Preview.Builder().build().also {
                    it.setSurfaceProvider(previewView.surfaceProvider)
                }

                val imageAnalysis = ImageAnalysis.Builder()
                    .setTargetResolution(android.util.Size(1280, 720))
                    .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                    .setOutputImageFormat(ImageAnalysis.OUTPUT_IMAGE_FORMAT_RGBA_8888)
                    .build()
                    .also {
                        it.setAnalyzer(cameraExecutor) { imageProxy ->
                            val rotationDegrees = imageProxy.imageInfo.rotationDegrees
                            // Update source info for overlay
                            if (sourceInfo.first != imageProxy.width || sourceInfo.second != imageProxy.height) {
                                onSourceInfoUpdate(Pair(imageProxy.width, imageProxy.height))
                            }
                            
                            // Pass frame to ViewModel
                            val processor = viewModel.poseDetectorProcessor
                            if (processor != null && processor.isInitialized()) {
                                // Get the latest result for the overlay
                                // We use an intermediary listener to capture results for overlay
                                val originalListener = processor.listener
                                processor.listener = object : com.example.ptchampion.posedetection.PoseProcessor.PoseProcessorListener {
                                    override fun onPoseDetected(result: PoseLandmarkerResult, timestampMs: Long) {
                                        // Update the latest result for overlay
                                        onPoseResultUpdate(result)
                                        // Forward to original listener
                                        originalListener?.onPoseDetected(result, timestampMs)
                                    }
                                    
                                    override fun onError(error: String, errorCode: Int) {
                                        originalListener?.onError(error, errorCode)
                                    }
                                }
                                processor.processImageProxy(imageProxy, rotationDegrees)
                            } else {
                                imageProxy.close() // Close if processor not ready
                            }
                        }
                    }

                // Re-bind use cases when lensFacing changes
                fun bindCameraUseCases() {
                    try {
                        cameraProvider.unbindAll()
                        cameraProvider.bindToLifecycle(
                            lifecycleOwner,
                            CameraSelector.Builder().requireLensFacing(uiState.lensFacing).build(),
                            preview,
                            imageAnalysis
                        )
                    } catch (exc: Exception) {
                        Log.e("CameraScreen", "Use case binding failed", exc)
                    }
                }

                // Bind camera use cases
                bindCameraUseCases()
                previewView
            },
            modifier = Modifier.fillMaxSize()
        )

        // Pose Overlay
        PoseOverlay(
            poseResult = latestPoseResult,
            sourceInfo = sourceInfo,
            modifier = Modifier.fillMaxSize()
        )

        // UI Overlay (Controls, Stats, Feedback)
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(16.dp)
        ) {
            // Top Row: Timer, Feedback
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = formatTime(uiState.timerSeconds),
                    fontSize = 24.sp,
                    fontWeight = FontWeight.Bold,
                    color = Color.White,
                    modifier = Modifier.background(Color.Black.copy(alpha = 0.5f), CircleShape).padding(horizontal = 12.dp, vertical = 4.dp)
                )
                Text(
                    text = uiState.feedback,
                    fontSize = 16.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = Color.White,
                    modifier = Modifier.background(Color.Black.copy(alpha = 0.5f)).padding(horizontal = 8.dp, vertical = 4.dp)
                )
            }

            Spacer(modifier = Modifier.weight(1f))

             // Display Save Error prominently if it occurs
             uiState.error?.let {
                Text(
                    text = "Error: $it",
                    color = MaterialTheme.colorScheme.error,
                    fontSize = 16.sp,
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier
                        .align(Alignment.CenterHorizontally)
                        .background(Color.Black.copy(alpha = 0.7f))
                        .padding(8.dp)
                )
                Spacer(modifier = Modifier.height(8.dp))
             }

            // Bottom Row: Reps, Form Score, Controls
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceAround,
                verticalAlignment = Alignment.CenterVertically
            ) {
                StatDisplay(label = "REPS", value = uiState.reps.toString())
                StatDisplay(label = "FORM", value = "${String.format("%.1f", uiState.formScore)}%") // Format score

                // Controls
                Row {
                    // Switch Camera Button
                    IconButton(
                        onClick = { viewModel.switchCamera() },
                        modifier = Modifier.background(Color.Black.copy(alpha = 0.5f), CircleShape)
                    ) {
                        Icon(Icons.Default.FlipCameraAndroid, contentDescription = "Switch Camera", tint = Color.White)
                    }
                    Spacer(modifier = Modifier.width(16.dp))

                    // Finish Button
                    if (!uiState.isFinished) {
                        Button(
                            onClick = { viewModel.finishWorkout() },
                            enabled = !uiState.isLoadingSave, // Disable while saving
                            shape = CircleShape,
                            colors = ButtonDefaults.buttonColors(containerColor = PtAccent, contentColor = PtCommandBlack),
                            contentPadding = PaddingValues(16.dp)
                        ) {
                            if (uiState.isLoadingSave) {
                                CircularProgressIndicator(modifier = Modifier.size(24.dp), color = PtCommandBlack)
                            } else {
                                Icon(Icons.Default.Check, contentDescription = "Finish Workout")
                            }
                        }
                    } else {
                         // Optionally show a different state or disabled button after finishing
                         Icon(
                             Icons.Default.Check,
                             contentDescription = "Workout Finished",
                             tint = PtAccent,
                             modifier = Modifier.size(56.dp) // Match button size
                                 .background(Color.Black.copy(alpha = 0.5f), CircleShape)
                                 .padding(16.dp)
                         )
                    }
                }
            }
        }
    }
}

@Composable
fun StatDisplay(label: String, value: String) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text(text = label, fontSize = 14.sp, color = PtAccent, fontWeight = FontWeight.Bold)
        Text(
            text = value,
            fontSize = 32.sp,
            fontWeight = FontWeight.Bold,
            color = Color.White,
            modifier = Modifier.background(Color.Black.copy(alpha = 0.5f)).padding(horizontal = 8.dp)
        )
    }
}

fun formatTime(seconds: Int): String {
    val minutes = seconds / 60
    val remainingSeconds = seconds % 60
    return String.format("%02d:%02d", minutes, remainingSeconds)
} 