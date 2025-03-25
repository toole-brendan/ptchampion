package com.ptchampion.ui.exercises

import android.Manifest
import android.content.pm.PackageManager
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Stop
import androidx.compose.material.icons.filled.Videocam
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.content.ContextCompat
import androidx.hilt.navigation.compose.hiltViewModel
import coil.compose.AsyncImage
import com.ptchampion.R
import com.ptchampion.domain.model.Exercise

/**
 * Parent screen for all exercise types
 */
@Composable
fun ExercisesScreen(
    exerciseId: Int,
    onNavigateBack: () -> Unit,
    viewModel: ExerciseViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val snackbarHostState = remember { SnackbarHostState() }
    
    // Show error message
    LaunchedEffect(uiState.error) {
        uiState.error?.let {
            snackbarHostState.showSnackbar(it)
            viewModel.clearError()
        }
    }
    
    // Load exercise if needed
    LaunchedEffect(exerciseId) {
        if (uiState.exercise == null || uiState.exercise?.id != exerciseId) {
            viewModel.loadExercise(exerciseId)
        }
    }
    
    Scaffold(
        snackbarHost = { SnackbarHost(snackbarHostState) }
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            if (uiState.isLoading) {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    CircularProgressIndicator()
                }
            } else {
                val exercise = uiState.exercise
                if (exercise != null) {
                    when (exercise.type) {
                        "pushup" -> PushupExerciseScreen(
                            exercise = exercise,
                            uiState = uiState,
                            onNavigateBack = onNavigateBack,
                            onStartExercise = { viewModel.startExercise() },
                            onUpdateState = { viewModel.updatePushupState(it) },
                            onCompleteExercise = { reps ->
                                viewModel.completeExercise(reps = reps)
                            }
                        )
                        "pullup" -> PullupExerciseScreen(
                            exercise = exercise,
                            uiState = uiState,
                            onNavigateBack = onNavigateBack,
                            onStartExercise = { viewModel.startExercise() },
                            onUpdateState = { viewModel.updatePullupState(it) },
                            onCompleteExercise = { reps ->
                                viewModel.completeExercise(reps = reps)
                            }
                        )
                        "situp" -> SitupExerciseScreen(
                            exercise = exercise,
                            uiState = uiState,
                            onNavigateBack = onNavigateBack,
                            onStartExercise = { viewModel.startExercise() },
                            onUpdateState = { viewModel.updateSitupState(it) },
                            onCompleteExercise = { reps ->
                                viewModel.completeExercise(reps = reps)
                            }
                        )
                        "run" -> RunExerciseScreen(
                            exercise = exercise,
                            uiState = uiState,
                            availableDevices = viewModel.getAvailableDevices().collectAsState(initial = emptyList()).value,
                            onNavigateBack = onNavigateBack,
                            onStartExercise = { viewModel.startExercise() },
                            onCompleteExercise = { time, distance ->
                                viewModel.completeExercise(
                                    timeInSeconds = time,
                                    distance = distance
                                )
                            },
                            onConnectDevice = { deviceId ->
                                viewModel.connectToDevice(deviceId)
                            },
                            onDisconnectDevice = { deviceId ->
                                viewModel.disconnectDevice(deviceId)
                            }
                        )
                        else -> {
                            // Unknown exercise type
                            Box(
                                modifier = Modifier.fillMaxSize(),
                                contentAlignment = Alignment.Center
                            ) {
                                Text(
                                    text = "Unsupported exercise type: ${exercise.type}",
                                    style = MaterialTheme.typography.bodyLarge
                                )
                            }
                        }
                    }
                } else {
                    // No exercise found
                    Box(
                        modifier = Modifier.fillMaxSize(),
                        contentAlignment = Alignment.Center
                    ) {
                        Column(
                            horizontalAlignment = Alignment.CenterHorizontally
                        ) {
                            Text(
                                text = "Exercise not found",
                                style = MaterialTheme.typography.headlineMedium
                            )
                            Spacer(modifier = Modifier.height(16.dp))
                            OutlinedButton(onClick = onNavigateBack) {
                                Icon(
                                    imageVector = Icons.Default.ArrowBack,
                                    contentDescription = "Back"
                                )
                                Spacer(modifier = Modifier.size(8.dp))
                                Text("Go Back")
                            }
                        }
                    }
                }
            }
        }
    }
}

/**
 * Common exercise header
 */
@Composable
fun ExerciseHeader(
    exercise: Exercise,
    onNavigateBack: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(16.dp)
    ) {
        Row(
            verticalAlignment = Alignment.CenterVertically
        ) {
            IconButton(onClick = onNavigateBack) {
                Icon(
                    imageVector = Icons.Default.ArrowBack,
                    contentDescription = "Back"
                )
            }
            
            Text(
                text = exercise.name,
                style = MaterialTheme.typography.headlineMedium,
                fontWeight = FontWeight.Bold
            )
        }
        
        Spacer(modifier = Modifier.height(8.dp))
        
        Text(
            text = exercise.description,
            style = MaterialTheme.typography.bodyLarge
        )
    }
}

/**
 * Exercise completion summary
 */
@Composable
fun ExerciseCompletionSummary(
    exerciseType: String,
    reps: Int? = null,
    timeInSeconds: Int? = null,
    distance: Double? = null,
    score: Int,
    onClose: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Icon(
            imageVector = Icons.Default.Check,
            contentDescription = "Complete",
            modifier = Modifier.size(64.dp),
            tint = MaterialTheme.colorScheme.primary
        )
        
        Spacer(modifier = Modifier.height(16.dp))
        
        Text(
            text = "Exercise Complete!",
            style = MaterialTheme.typography.headlineMedium,
            fontWeight = FontWeight.Bold
        )
        
        Spacer(modifier = Modifier.height(24.dp))
        
        when {
            reps != null -> {
                Text(
                    text = "You completed: $reps reps",
                    style = MaterialTheme.typography.titleLarge
                )
            }
            timeInSeconds != null -> {
                val minutes = timeInSeconds / 60
                val seconds = timeInSeconds % 60
                Text(
                    text = "Your time: $minutes:${seconds.toString().padStart(2, '0')}",
                    style = MaterialTheme.typography.titleLarge
                )
                
                if (distance != null) {
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        text = "Distance: ${String.format("%.2f", distance)} miles",
                        style = MaterialTheme.typography.titleLarge
                    )
                }
            }
        }
        
        Spacer(modifier = Modifier.height(16.dp))
        
        Text(
            text = "Your score: $score",
            style = MaterialTheme.typography.headlineLarge,
            fontWeight = FontWeight.Bold,
            color = MaterialTheme.colorScheme.primary
        )
        
        Spacer(modifier = Modifier.height(8.dp))
        
        val rating = when {
            score >= 90 -> "Excellent"
            score >= 80 -> "Good"
            score >= 65 -> "Satisfactory"
            score >= 50 -> "Marginal"
            else -> "Poor"
        }
        
        Text(
            text = "Rating: $rating",
            style = MaterialTheme.typography.titleMedium
        )
        
        Spacer(modifier = Modifier.height(32.dp))
        
        Button(
            onClick = onClose,
            modifier = Modifier.fillMaxWidth()
        ) {
            Text("Return to Dashboard")
        }
    }
}

/**
 * Camera permission request
 */
@Composable
fun CameraPermissionRequest(
    onPermissionGranted: () -> Unit,
    onCancel: () -> Unit
) {
    val context = LocalContext.current
    val launcher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { isGranted ->
        if (isGranted) {
            onPermissionGranted()
        } else {
            onCancel()
        }
    }
    
    LaunchedEffect(Unit) {
        when (PackageManager.PERMISSION_GRANTED) {
            ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.CAMERA
            ) -> {
                onPermissionGranted()
            }
            else -> {
                launcher.launch(Manifest.permission.CAMERA)
            }
        }
    }
}