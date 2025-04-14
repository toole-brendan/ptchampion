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
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp
import com.example.ptchampion.ui.screens.camera.SessionState
import com.example.ptchampion.ui.screens.camera.CameraNavigationEvent
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import kotlinx.coroutines.flow.collectLatest
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.camera.core.ImageProxy
import androidx.camera.core.ImageAnalysis
import com.google.accompanist.permissions.ExperimentalPermissionsApi
import com.google.accompanist.permissions.PermissionRequired
import com.google.accompanist.permissions.rememberPermissionState
import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarkerResult

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
    val cameraProviderFuture = remember { ProcessCameraProvider.getInstance(context) }
    val cameraExecutor = remember { Executors.newSingleThreadExecutor() }

    val uiState by viewModel.uiState.collectAsState()
    var poseResult by remember { mutableStateOf<PoseLandmarkerResult?>(null) }
    var sourceInfo by remember { mutableStateOf(Pair(0, 0)) } // Width, Height

    // Handle camera permissions
    val cameraPermissionState = rememberPermissionState(Manifest.permission.CAMERA)

    // Effect to navigate back when workout is successfully saved
    // We can check a flag, or specific feedback message
    LaunchedEffect(uiState.feedback) {
        if (uiState.feedback == "Workout Saved Successfully!") {
            Toast.makeText(context, "Workout Saved!", Toast.LENGTH_SHORT).show()
            kotlinx.coroutines.delay(500) // Brief delay to show message
            onWorkoutComplete()
        }
    }

    PermissionRequired(
        permissionState = cameraPermissionState,
        permissionNotGrantedContent = {
            Column(
                modifier = Modifier.fillMaxSize().padding(16.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center
            ) {
                Text("Camera permission is required to analyze exercises.")
                Spacer(modifier = Modifier.height(8.dp))
                Button(onClick = { cameraPermissionState.launchPermissionRequest() }) {
                    Text("Grant Permission")
                }
            }
        },
        permissionNotAvailableContent = {
             Column(
                modifier = Modifier.fillMaxSize().padding(16.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center
            ) {
                Text("Camera permission was denied. Please enable it in app settings.")
                 // TODO: Add button to navigate to settings
             }
        }
    ) {
        // Content to show when permission is granted
        Box(modifier = Modifier.fillMaxSize()) {
            // Camera Preview
            AndroidView(
                factory = { ctx ->
                    val previewView = PreviewView(ctx)
                    val cameraProvider = cameraProviderFuture.get()
                    val preview = Preview.Builder().build().also {
                        it.setSurfaceProvider(previewView.surfaceProvider)
                    }

                    val imageAnalysis = ImageAnalysis.Builder()
                        .setTargetResolution(android.util.Size(1280, 720)) // Example resolution
                        .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                        .setOutputImageFormat(ImageAnalysis.OUTPUT_IMAGE_FORMAT_RGBA_8888)
                        .build()
                        .also {
                            it.setAnalyzer(cameraExecutor) { imageProxy ->
                                val rotationDegrees = imageProxy.imageInfo.rotationDegrees
                                // Update source info for overlay
                                if (sourceInfo.first != imageProxy.width || sourceInfo.second != imageProxy.height) {
                                     sourceInfo = Pair(imageProxy.width, imageProxy.height)
                                }
                                
                                // Pass frame to ViewModel ONLY IF PoseDetectorProcessor is ready
                                val processor = viewModel.poseDetectorProcessor
                                if (processor != null && processor.isInitialized()) {
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
                            Toast.makeText(context, "Failed to start camera: ${exc.message}", Toast.LENGTH_LONG).show()
                        }
                    }

                    // Observe lensFacing state
                    // Use a State listener or LaunchedEffect in the Composable scope if needed
                    // For simplicity, just bind initially and rely on Composable recomposition if needed
                    bindCameraUseCases()

                    previewView
                },
                modifier = Modifier.fillMaxSize(),
                update = { /* Re-binding logic might go here if needed based on state changes */
                    // Rebind camera if lensFacing changes
                    val cameraProvider = cameraProviderFuture.get()
                    cameraProvider.unbindAll()
                    try {
                        cameraProvider.bindToLifecycle(
                            lifecycleOwner,
                            CameraSelector.Builder().requireLensFacing(uiState.lensFacing).build(),
                            it.surfaceProvider // Assuming preview provides surfaceProvider
                            // Need to re-bind image analysis too
                        )
                     } catch (exc: Exception) {
                         Log.e("CameraScreen", "Update Use case binding failed", exc)
                     }
                }
            )

            // Pose Overlay
            PoseOverlay(
                poseResult = poseResult,
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

    // Cleanup camera executor
    DisposableEffect(Unit) {
        onDispose {
            cameraExecutor.shutdown()
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