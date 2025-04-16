package com.example.ptchampion.ui.screens.camera

import android.Manifest
import android.content.pm.PackageManager
import android.util.Log
import android.widget.Toast
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.camera.core.AspectRatio
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.BugReport
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLifecycleOwner
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.content.ContextCompat
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.lifecycle.LifecycleOwner
import com.example.ptchampion.BuildConfig // Import BuildConfig
import com.example.ptchampion.posedetection.PoseDetectorProcessor
import com.example.ptchampion.posedetection.PoseLandmarkerHelper
import com.example.ptchampion.posedetection.PoseProcessor
import com.example.ptchampion.ui.common.PoseOverlay
import com.example.ptchampion.utils.PoseDetectionTester // Import Tester
import com.google.accompanist.permissions.ExperimentalPermissionsApi
import com.google.accompanist.permissions.isGranted
import com.google.accompanist.permissions.rememberPermissionState
import com.google.accompanist.permissions.shouldShowRationale
import com.google.common.util.concurrent.ListenableFuture
import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarkerResult
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import kotlin.coroutines.resume
import kotlin.coroutines.suspendCoroutine

// Helper extension function for CameraProviderFuture
suspend fun <T> ListenableFuture<T>.await(): T = suspendCoroutine { continuation ->
    addListener({ continuation.resume(get()) }, ContextCompat.getMainExecutor(context))
}

@OptIn(ExperimentalPermissionsApi::class)
@Composable
fun CameraScreen(
    // exerciseId: Int, // No longer directly used in this version of the screen logic
    // exerciseType: String?, // No longer directly used here, handled by ViewModel
    viewModel: CameraViewModel = hiltViewModel(),
    onWorkoutComplete: () -> Unit
) {
    val context = LocalContext.current
    val lifecycleOwner = LocalLifecycleOwner.current
    val scope = rememberCoroutineScope()

    val cameraProviderFuture = remember { ProcessCameraProvider.getInstance(context) }
    val cameraExecutor = remember { Executors.newSingleThreadExecutor() }

    val uiState by viewModel.uiState.collectAsState()
    val previewView = remember { PreviewView(context) }

    var cameraProvider by remember { mutableStateOf<ProcessCameraProvider?>(null) }
    var hasInitializedCamera by remember { mutableStateOf(false) }

    // Track latest pose result and image size for overlay
    var latestPoseResult by remember { mutableStateOf<PoseLandmarkerResult?>(null) }
    var imageSize by remember { mutableStateOf(Pair(0, 0)) } // Width, Height

    // Handle camera permissions
    val cameraPermissionState = rememberPermissionState(Manifest.permission.CAMERA)
    val hasPermission = cameraPermissionState.status.isGranted

    // Effect to get camera provider instance
    LaunchedEffect(cameraProviderFuture) {
        try {
            cameraProvider = cameraProviderFuture.await()
            Log.d("CameraScreen", "CameraProvider obtained successfully.")
        } catch (e: Exception) {
            Log.e("CameraScreen", "Failed to get camera provider", e)
            // Show error to user (e.g., update UI state in ViewModel)
        }
    }

    // Handle proper lifecycle binding for camera
    DisposableEffect(lifecycleOwner, cameraProvider, hasPermission, uiState.lensFacing) {
        val observer = LifecycleEventObserver { _, event ->
            scope.launch {
                when (event) {
                    Lifecycle.Event.ON_RESUME -> {
                        if (hasPermission && cameraProvider != null && !hasInitializedCamera) {
                            Log.d("CameraScreen", "ON_RESUME: Binding camera use cases.")
                            bindCameraUseCases(
                                cameraProvider = cameraProvider!!,
                                lifecycleOwner = lifecycleOwner,
                                previewView = previewView,
                                cameraExecutor = cameraExecutor,
                                lensFacing = uiState.lensFacing,
                                poseProcessor = viewModel.poseDetectorProcessor,
                                onImageSizeChanged = { width, height -> imageSize = Pair(width, height) },
                                onPoseResultUpdate = { result -> latestPoseResult = result }
                            )
                            hasInitializedCamera = true
                        }
                    }
                    Lifecycle.Event.ON_PAUSE -> {
                        if (cameraProvider != null && hasInitializedCamera) {
                            Log.d("CameraScreen", "ON_PAUSE: Unbinding camera use cases.")
                            cameraProvider?.unbindAll()
                            hasInitializedCamera = false
                        }
                    }
                    Lifecycle.Event.ON_DESTROY -> {
                        Log.d("CameraScreen", "ON_DESTROY: Unbinding camera.")
                        cameraProvider?.unbindAll()
                        hasInitializedCamera = false
                    }
                    else -> { /* No specific action needed for other events */ }
                }
            }
        }
        lifecycleOwner.lifecycle.addObserver(observer)
        onDispose {
            Log.d("CameraScreen", "Disposing camera lifecycle effect.")
            lifecycleOwner.lifecycle.removeObserver(observer)
            // Consider unbinding here too, though ON_PAUSE/ON_DESTROY should handle it
            // cameraProvider?.unbindAll()
        }
    }

    // Rebind camera when lens facing changes
    // Note: DisposableEffect above already includes uiState.lensFacing as a key,
    // so it will re-run and trigger the ON_RESUME logic when lensFacing changes.

    // Navigate back when workout saved successfully
    LaunchedEffect(uiState.feedback) {
        if (uiState.feedback == "Workout Saved Successfully!") {
            Toast.makeText(context, "Workout Saved!", Toast.LENGTH_SHORT).show()
            delay(500) // Short delay before navigating back
            onWorkoutComplete()
        }
    }

    Scaffold { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            if (hasPermission) {
                // Camera Preview
                AndroidView(
                    factory = { previewView },
                    modifier = Modifier.fillMaxSize()
                )

                // Pose Overlay (draws detected landmarks)
                PoseOverlay(
                    poseResult = latestPoseResult,
                    sourceInfo = imageSize, // Pass image dimensions
                    modifier = Modifier.fillMaxSize()
                )

                // UI Overlay (buttons, stats, feedback)
                CameraUIOverlay(
                    uiState = uiState,
                    onSwitchCamera = { viewModel.switchCamera() },
                    onFinishWorkout = { viewModel.finishWorkout() }
                )

                // Diagnostic Button (Debug Only - Phase 6.2)
                if (BuildConfig.DEBUG) {
                    FloatingActionButton(
                        onClick = {
                            val tester = PoseDetectionTester(context)
                            tester.logSystemInfo()
                            val result = tester.testPoseLandmarkerInitialization()
                            Toast.makeText(context, "Pose detector test: $result", Toast.LENGTH_LONG).show()
                        },
                        modifier = Modifier
                            .align(Alignment.BottomStart)
                            .padding(16.dp)
                    ) {
                        Icon(Icons.Default.BugReport, contentDescription = "Run diagnostics")
                    }
                }

            } else {
                // Screen to request permission
                PermissionRequestScreen(
                    onRequestPermission = { cameraPermissionState.launchPermissionRequest() },
                    showRationale = cameraPermissionState.status.shouldShowRationale
                )
            }

            // Loading indicator while saving
            if (uiState.isLoadingSave) {
                CircularProgressIndicator(modifier = Modifier.align(Alignment.Center))
            }

            // Display error messages
            uiState.error?.let {
                Toast.makeText(context, "Error: $it", Toast.LENGTH_LONG).show()
                // Optionally show a more prominent error UI
            }
        }
    }

    // Cleanup executor when the composable leaves the composition
    DisposableEffect(Unit) {
        onDispose {
            Log.d("CameraScreen", "Shutting down cameraExecutor.")
            cameraExecutor.shutdown()
        }
    }
}

// Function to bind camera use cases (extracted for clarity)
private fun bindCameraUseCases(
    cameraProvider: ProcessCameraProvider,
    lifecycleOwner: LifecycleOwner,
    previewView: PreviewView,
    cameraExecutor: ExecutorService,
    lensFacing: Int,
    poseProcessor: PoseDetectorProcessor?, // Use PoseDetectorProcessor
    onImageSizeChanged: (Int, Int) -> Unit,
    onPoseResultUpdate: (PoseLandmarkerResult) -> Unit
) {
    // Basic check for processor
    if (poseProcessor == null) {
        Log.e("CameraScreen", "PoseProcessor is null, cannot bind analysis.")
        return
    }

    // Ensure processor is initialized (or initialize it)
    if (!poseProcessor.isInitialized()) {
        Log.w("CameraScreen", "PoseProcessor not initialized, attempting initialization...")
        poseProcessor.initialize()
        if (!poseProcessor.isInitialized()) {
            Log.e("CameraScreen", "PoseProcessor failed to initialize, cannot bind analysis.")
            return
        }
    }

    val cameraSelector = CameraSelector.Builder()
        .requireLensFacing(lensFacing)
        .build()

    // Set up the Preview use case
    val preview = Preview.Builder()
        .setTargetAspectRatio(AspectRatio.RATIO_16_9) // Match analysis aspect ratio
        .build()
        .also {
            it.setSurfaceProvider(previewView.surfaceProvider)
        }

    // Set up the ImageAnalysis use case
    val imageAnalysis = ImageAnalysis.Builder()
        .setTargetAspectRatio(AspectRatio.RATIO_16_9) // Keep consistent
        .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
        // .setOutputImageFormat(ImageAnalysis.OUTPUT_IMAGE_FORMAT_YUV_420_888) // YUV is needed by YuvToRgbConverter
        .build()

    // Set up the analyzer
    imageAnalysis.setAnalyzer(cameraExecutor) { imageProxy ->
        // Update image size for overlay scaling
        onImageSizeChanged(imageProxy.width, imageProxy.height)

        // Use a middleman listener to capture results for the overlay
        // Ensure we don't keep nesting listeners if this function runs multiple times
        val originalListener = poseProcessor.listener
        val overlayListener = object : PoseProcessor.PoseProcessorListener {
            override fun onPoseDetected(result: PoseLandmarkerResult, timestampMs: Long) {
                onPoseResultUpdate(result) // Update overlay state
                originalListener?.onPoseDetected(result, timestampMs) // Forward to original listener (ViewModel)
            }

            override fun onError(error: String, errorCode: Int) {
                originalListener?.onError(error, errorCode) // Forward errors
            }
        }
        // Temporarily set the overlay listener only if it's not already set
        if (poseProcessor.listener !== overlayListener) { // Basic check to avoid redundant sets
            poseProcessor.listener = overlayListener
        }

        // Process the image
        try {
            // Rotation degrees are handled internally by MediaPipe tasks usually
            poseProcessor.processImageProxy(imageProxy, imageProxy.imageInfo.rotationDegrees)
        } catch (e: Exception) {
            Log.e("CameraScreen", "Error processing image in analyzer: ${e.message}", e)
            // Ensure imageProxy is closed on error
            try { imageProxy.close() } catch (ignored: Exception) {}
        }
    }

    try {
        // Unbind all existing use cases before rebinding
        cameraProvider.unbindAll()
        Log.d("CameraScreen", "Binding Preview and ImageAnalysis use cases.")
        // Bind the desired use cases to the camera
        cameraProvider.bindToLifecycle(
            lifecycleOwner,
            cameraSelector,
            preview,
            imageAnalysis
        )
    } catch (e: Exception) { // Catch specific exceptions if possible
        Log.e("CameraScreen", "Use case binding failed", e)
        // Handle binding failure (e.g., show error message)
    }
}

// Simple Composable for requesting camera permission
@OptIn(ExperimentalPermissionsApi::class)
@Composable
private fun PermissionRequestScreen(
    onRequestPermission: () -> Unit,
    showRationale: Boolean
) {
    Column(
        modifier = Modifier.fillMaxSize(),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            if (showRationale) {
                "Camera permission is needed to analyze your exercise form. Please grant the permission."
            } else {
                "Camera permission required for exercise tracking."
            },
            style = MaterialTheme.typography.bodyLarge,
            modifier = Modifier.padding(16.dp)
        )
        Button(onClick = onRequestPermission) {
            Text("Grant Permission")
        }
    }
}

// Placeholder for CameraUIOverlay - Use your existing implementation
@Composable
private fun CameraUIOverlay(
    modifier: Modifier = Modifier, // Add modifier parameter
    uiState: CameraUiState,
    onSwitchCamera: () -> Unit,
    onFinishWorkout: () -> Unit
) {
    // *** Replace this with your actual Camera UI Overlay implementation ***
    // This should include buttons for switching camera, finishing workout,
    // and displaying stats like reps, timer, form score, feedback.
    Box(modifier = modifier.fillMaxSize()) {
        Column(
            modifier = Modifier
                .align(Alignment.TopCenter)
                .padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text("Reps: ${uiState.reps}", style = MaterialTheme.typography.headlineMedium)
            Text("Timer: ${uiState.timerSeconds}s", style = MaterialTheme.typography.headlineSmall)
            Text("Form: ${uiState.formScore.toInt()}%", style = MaterialTheme.typography.headlineSmall)
            Text(uiState.feedback ?: "", style = MaterialTheme.typography.bodyLarge)
        }
        Row(
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .padding(16.dp),
            horizontalArrangement = Arrangement.SpaceEvenly,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Button(onClick = onSwitchCamera) { Text("Switch Cam") }
            Spacer(modifier = Modifier.width(16.dp))
            Button(onClick = onFinishWorkout, enabled = !uiState.isFinished) { Text("Finish") }
        }
    }
}