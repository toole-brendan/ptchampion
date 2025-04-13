package com.example.ptchampion.ui.screens.camera

import android.Manifest
import android.content.Context
import android.util.Log
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
import com.example.ptchampion.ui.screens.camera.SessionState
import com.example.ptchampion.ui.screens.camera.CameraNavigationEvent
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import kotlinx.coroutines.flow.collectLatest
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.camera.core.ImageProxy
import androidx.camera.core.ImageAnalysis

@Composable
fun CameraScreen(
    exerciseId: Int, // Add exerciseId parameter
    exerciseType: String?, // Received from navigation args
    viewModel: CameraViewModel = viewModel(),
    onWorkoutComplete: () -> Unit = {}
) {
    val context = LocalContext.current
    val lifecycleOwner = LocalLifecycleOwner.current
    val uiState by viewModel.uiState.collectAsState()
    val snackbarHostState = remember { SnackbarHostState() } // For showing errors

    // --- Navigation Handler ---
    LaunchedEffect(Unit) {
        viewModel.navigationEvent.collectLatest {
            when(it) {
                is CameraNavigationEvent.NavigateBack -> {
                    // Show a brief success message before navigating
                    snackbarHostState.showSnackbar("Workout Saved Successfully!")
                    onWorkoutComplete() // Trigger navigation passed from NavHost
                }
            }
        }
    }

    // --- Error Snackbar Handler ---
    LaunchedEffect(uiState.saveError) {
        uiState.saveError?.let {
            snackbarHostState.showSnackbar(it)
            // Optionally clear the error in VM after showing
        }
    }

    // Request permission explicitly when state requires it
    LaunchedEffect(Unit) {
        viewModel.onPermissionResult(granted = true, shouldShowRationale = false)
    }

    // Create and manage the camera executor service
    val cameraExecutor = remember { Executors.newSingleThreadExecutor() }
    DisposableEffect(Unit) {
        onDispose { cameraExecutor.shutdown() }
    }

    Scaffold(
        snackbarHost = { SnackbarHost(hostState = snackbarHostState) } // Add snackbar host
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues),
            contentAlignment = Alignment.Center
        ) {
            // Handle Initialization State
            if (uiState.isInitializing) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    CircularProgressIndicator()
                    Spacer(modifier = Modifier.height(8.dp))
                    Text("Initializing Pose Detection...")
                }
            } else if (uiState.initializationError != null) {
                Text("Error: ${uiState.initializationError}", color = MaterialTheme.colorScheme.error)
            } 
            // Handle Permission States
            else if (false) { // Temporarily bypass permission UI
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Text("Camera permission needed (Bypassed for now)") // Placeholder
                }
            } 
            // Permissions granted and initialized -> Show Camera & Overlay
            else {
                // Use Box to layer CameraPreview and PoseOverlay
                Box(modifier = Modifier.fillMaxSize()) {
                    CameraPreview(
                        context = context,
                        lifecycleOwner = lifecycleOwner,
                        cameraExecutor = cameraExecutor,
                        modifier = Modifier.fillMaxSize(),
                        onFrameAnalyzed = viewModel::processFrame
                    )

                    // Draw Overlay using results from ViewModel
                    uiState.poseLandmarkerResult?.let { resultBundle ->
                        PoseOverlay(
                            resultBundle = resultBundle,
                            modifier = Modifier.fillMaxSize()
                        )
                    }

                    // --- Top Info Bar --- 
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .background(Color.Black.copy(alpha = 0.5f)) // Semi-transparent background
                            .padding(horizontal = 16.dp, vertical = 8.dp)
                            .align(Alignment.TopCenter),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Text(
                            text = "Exercise: ${exerciseType ?: "Unknown"}",
                            style = MaterialTheme.typography.titleMedium,
                            color = Color.White
                        )
                        Text(
                            text = "Reps: ${uiState.repCount}",
                            style = MaterialTheme.typography.titleMedium,
                            color = Color.White
                        )
                        Text(
                            text = "Form: ${uiState.formScore}%", // Display form score
                            style = MaterialTheme.typography.titleMedium,
                            color = if (uiState.formScore >= 80) Color.Green else if (uiState.formScore >= 60) Color.Yellow else Color.Red
                        )
                    }

                    // --- Bottom Control Bar & Feedback --- 
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .align(Alignment.BottomCenter)
                            .background(Color.Black.copy(alpha = 0.5f))
                            .padding(16.dp),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        // Display Feedback
                        if (uiState.sessionState == SessionState.RUNNING || uiState.sessionState == SessionState.PAUSED) {
                            Text(
                                text = uiState.exerciseFeedback ?: "Keep Going!",
                                color = if (uiState.exerciseFeedback?.contains("deep", ignoreCase = true) == true ||
                                          uiState.exerciseFeedback?.contains("extend", ignoreCase = true) == true ||
                                          uiState.exerciseFeedback?.contains("down", ignoreCase = true) == true ||
                                          uiState.exerciseFeedback?.contains("hips", ignoreCase = true) == true
                                ) MaterialTheme.colorScheme.error else Color.White,
                                style = MaterialTheme.typography.bodyMedium,
                                modifier = Modifier.padding(bottom = 8.dp)
                            )
                        }
                        
                        // Display Detection Error (if any)
                        uiState.detectionError?.let {
                            Text(
                                text = "Detection Error: $it",
                                color = MaterialTheme.colorScheme.error,
                                style = MaterialTheme.typography.bodySmall,
                                modifier = Modifier.padding(bottom = 8.dp)
                            )
                        }

                        // Saving Indicator
                        if (uiState.isSaving) {
                            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                LinearProgressIndicator(modifier = Modifier.fillMaxWidth(0.8f).padding(vertical = 8.dp))
                                Text("Saving workout...", color = Color.White, style = MaterialTheme.typography.bodySmall)
                            }
                        } else if (uiState.saveSuccess) {
                             Text("Workout Saved!", color = Color.Green, style = MaterialTheme.typography.bodyMedium)
                             // Navigation is handled by LaunchedEffect
                         }

                        // Control Buttons (disable when saving)
                        Row(horizontalArrangement = Arrangement.Center, verticalAlignment = Alignment.CenterVertically) {
                            when (uiState.sessionState) {
                                SessionState.IDLE -> {
                                    Button(onClick = viewModel::startSession, enabled = !uiState.isSaving) {
                                        Icon(Icons.Filled.PlayArrow, contentDescription = "Start")
                                        Spacer(modifier = Modifier.width(ButtonDefaults.IconSpacing))
                                        Text("Start")
                                    }
                                }
                                SessionState.RUNNING -> {
                                    IconButton(onClick = viewModel::pauseSession, enabled = !uiState.isSaving) {
                                        Icon(Icons.Filled.Pause, contentDescription = "Pause", modifier = Modifier.size(40.dp), tint = Color.White)
                                    }
                                    Spacer(modifier = Modifier.width(16.dp))
                                    IconButton(onClick = viewModel::stopSession, enabled = !uiState.isSaving) {
                                        Icon(Icons.Filled.Stop, contentDescription = "Stop", modifier = Modifier.size(40.dp), tint = Color.Red)
                                    }
                                }
                                SessionState.PAUSED -> {
                                    Button(onClick = viewModel::startSession, enabled = !uiState.isSaving) { // Resume
                                        Icon(Icons.Filled.PlayArrow, contentDescription = "Resume")
                                        Spacer(modifier = Modifier.width(ButtonDefaults.IconSpacing))
                                        Text("Resume")
                                    }
                                    Spacer(modifier = Modifier.width(16.dp))
                                    IconButton(onClick = viewModel::stopSession, enabled = !uiState.isSaving) {
                                        Icon(Icons.Filled.Stop, contentDescription = "Stop", modifier = Modifier.size(40.dp), tint = Color.Red)
                                    }
                                }
                                SessionState.STOPPED -> {
                                    // Show Start button again or maybe a "Summary" button?
                                    // For now, allow starting a new session after stopping/saving
                                    Button(onClick = viewModel::startSession, enabled = !uiState.isSaving) {
                                        Icon(Icons.Filled.PlayArrow, contentDescription = "Start New Session")
                                        Spacer(modifier = Modifier.width(ButtonDefaults.IconSpacing))
                                        Text("Start New")
                                    }
                                    // Optionally add a button to explicitly go back if auto-nav fails
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun CameraPreview(
    context: Context,
    lifecycleOwner: LifecycleOwner,
    cameraExecutor: ExecutorService,
    modifier: Modifier = Modifier,
    onFrameAnalyzed: (ImageProxy) -> Unit
) {
    AndroidView(
        factory = { ctx ->
            val previewView = PreviewView(ctx)
            val cameraProviderFuture = ProcessCameraProvider.getInstance(ctx)

            cameraProviderFuture.addListener({
                val cameraProvider = cameraProviderFuture.get()
                
                // Preview Use Case
                val preview = Preview.Builder().build().also {
                    it.setSurfaceProvider(previewView.surfaceProvider)
                }

                // Image Analysis Use Case
                val imageAnalyzer = androidx.camera.core.ImageAnalysis.Builder()
                    // Configure analysis options if needed (e.g., resolution)
                    // .setTargetResolution(Size(640, 480))
                    .setBackpressureStrategy(androidx.camera.core.ImageAnalysis.STRATEGY_BLOCK_PRODUCER)
                    .build()
                    .also {
                        it.setAnalyzer(cameraExecutor) { imageProxy ->
                            // Pass the frame for analysis
                            onFrameAnalyzed(imageProxy)
                            // IMPORTANT: ImageProxy must be closed manually here if not closed in ViewModel
                            // However, our ViewModel closes it, so we don't close here.
                        }
                    }

                // Select Camera (prefer front camera for exercises)
                val cameraSelector = CameraSelector.Builder()
                    .requireLensFacing(CameraSelector.LENS_FACING_FRONT)
                    .build()

                try {
                    // Unbind use cases before rebinding
                    cameraProvider.unbindAll()

                    // Bind use cases to camera
                    cameraProvider.bindToLifecycle(
                        lifecycleOwner,
                        cameraSelector,
                        preview,
                        imageAnalyzer // Add the analyzer use case
                    )
                    Log.d("CameraPreview", "Camera Use Cases Bound")
                } catch (exc: Exception) {
                    Log.e("CameraPreview", "Use case binding failed", exc)
                }

            }, ContextCompat.getMainExecutor(ctx))
            previewView
        },
        modifier = modifier
    )
} 