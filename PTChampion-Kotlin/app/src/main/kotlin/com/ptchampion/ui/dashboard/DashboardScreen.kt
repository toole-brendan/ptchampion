package com.ptchampion.ui.dashboard

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.location.LocationManager
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.LocationOn
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Divider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.ContextCompat
import androidx.hilt.navigation.compose.hiltViewModel
import coil.compose.AsyncImage
import com.ptchampion.R
import com.ptchampion.domain.model.Exercise
import com.ptchampion.domain.model.UserExercise
import kotlin.math.roundToInt

/**
 * Dashboard screen
 */
@Composable
fun DashboardScreen(
    onNavigateToExercise: (Int) -> Unit,
    viewModel: DashboardViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val snackbarHostState = remember { SnackbarHostState() }
    val context = LocalContext.current
    
    // Location permission request
    val locationPermissionLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions()
    ) { permissions ->
        val locationGranted = permissions.getOrDefault(
            Manifest.permission.ACCESS_FINE_LOCATION, false
        ) || permissions.getOrDefault(
            Manifest.permission.ACCESS_COARSE_LOCATION, false
        )
        
        if (locationGranted) {
            // Get location and update
            getLastKnownLocation(context)?.let { location ->
                viewModel.updateUserLocation(location.latitude, location.longitude)
                viewModel.loadLocalLeaderboard(location)
            }
        }
    }
    
    // Request location permission on first load
    LaunchedEffect(Unit) {
        val hasFineLocation = ContextCompat.checkSelfPermission(
            context, Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED
        val hasCoarseLocation = ContextCompat.checkSelfPermission(
            context, Manifest.permission.ACCESS_COARSE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED
        
        if (!hasFineLocation && !hasCoarseLocation) {
            locationPermissionLauncher.launch(
                arrayOf(
                    Manifest.permission.ACCESS_FINE_LOCATION,
                    Manifest.permission.ACCESS_COARSE_LOCATION
                )
            )
        } else {
            // Get location and update
            getLastKnownLocation(context)?.let { location ->
                viewModel.updateUserLocation(location.latitude, location.longitude)
                viewModel.loadLocalLeaderboard(location)
            }
        }
    }
    
    // Show error message
    LaunchedEffect(uiState.error) {
        uiState.error?.let {
            snackbarHostState.showSnackbar(it)
            viewModel.clearError()
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
                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .verticalScroll(rememberScrollState())
                        .padding(16.dp)
                ) {
                    // Welcome header
                    uiState.user?.let { user ->
                        WelcomeHeader(username = user.username)
                    }
                    
                    Spacer(modifier = Modifier.height(16.dp))
                    
                    // Performance card with latest scores
                    PerformanceCard(latestExercises = uiState.latestExercises)
                    
                    Spacer(modifier = Modifier.height(24.dp))
                    
                    // Exercise cards
                    Text(
                        text = "Available Exercises",
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold
                    )
                    
                    Spacer(modifier = Modifier.height(8.dp))
                    
                    LazyRow(
                        contentPadding = PaddingValues(vertical = 8.dp),
                        horizontalArrangement = Arrangement.spacedBy(16.dp)
                    ) {
                        items(uiState.exercises) { exercise ->
                            val latestScore = uiState.latestExercises[exercise.type]
                            ExerciseCard(
                                exercise = exercise,
                                latestScore = latestScore,
                                onClick = { onNavigateToExercise(exercise.id) }
                            )
                        }
                    }
                    
                    Spacer(modifier = Modifier.height(24.dp))
                    
                    // Leaderboard
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Text(
                            text = "Leaderboard",
                            style = MaterialTheme.typography.titleLarge,
                            fontWeight = FontWeight.Bold
                        )
                        
                        Row {
                            // Location button
                            IconButton(
                                onClick = {
                                    locationPermissionLauncher.launch(
                                        arrayOf(
                                            Manifest.permission.ACCESS_FINE_LOCATION,
                                            Manifest.permission.ACCESS_COARSE_LOCATION
                                        )
                                    )
                                }
                            ) {
                                Icon(
                                    imageVector = Icons.Default.LocationOn,
                                    contentDescription = "Update Location"
                                )
                            }
                            
                            // Refresh button
                            IconButton(
                                onClick = { viewModel.loadData() }
                            ) {
                                Icon(
                                    imageVector = Icons.Default.Refresh,
                                    contentDescription = "Refresh"
                                )
                            }
                        }
                    }
                    
                    Spacer(modifier = Modifier.height(8.dp))
                    
                    LeaderboardList(
                        entries = uiState.leaderboard,
                        currentUserId = uiState.user?.id ?: -1
                    )
                }
            }
        }
    }
}

/**
 * Welcome header
 */
@Composable
fun WelcomeHeader(username: String) {
    Column(
        modifier = Modifier.fillMaxWidth()
    ) {
        Row(
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(
                modifier = Modifier
                    .size(50.dp)
                    .clip(CircleShape)
                    .background(MaterialTheme.colorScheme.primaryContainer),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = Icons.Default.Person,
                    contentDescription = "Profile",
                    modifier = Modifier.size(30.dp),
                    tint = MaterialTheme.colorScheme.onPrimaryContainer
                )
            }
            
            Column(
                modifier = Modifier.padding(start = 16.dp)
            ) {
                Text(
                    text = "Welcome back,",
                    style = MaterialTheme.typography.titleMedium
                )
                Text(
                    text = username,
                    style = MaterialTheme.typography.headlineMedium,
                    fontWeight = FontWeight.Bold
                )
            }
        }
    }
}

/**
 * Performance card showing latest exercise scores
 */
@Composable
fun PerformanceCard(latestExercises: Map<String, UserExercise>) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        elevation = CardDefaults.cardElevation(defaultElevation = 4.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.primaryContainer
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
        ) {
            Text(
                text = "Your Performance",
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onPrimaryContainer
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            val overallScore = calculateOverallScore(latestExercises)
            
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column {
                    Text(
                        text = "Overall Score",
                        style = MaterialTheme.typography.bodyLarge,
                        color = MaterialTheme.colorScheme.onPrimaryContainer
                    )
                    Text(
                        text = getScoreRating(overallScore),
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.onPrimaryContainer
                    )
                }
                
                Text(
                    text = "$overallScore",
                    style = MaterialTheme.typography.headlineLarge,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.onPrimaryContainer
                )
            }
            
            Spacer(modifier = Modifier.height(16.dp))
            
            ExerciseScoresList(latestExercises)
        }
    }
}

/**
 * List of exercise scores
 */
@Composable
fun ExerciseScoresList(latestExercises: Map<String, UserExercise>) {
    Column(
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        listOf("pushup", "pullup", "situp", "run").forEach { type ->
            val exercise = latestExercises[type]
            ExerciseScoreItem(
                type = type,
                score = exercise?.score ?: 0,
                details = getExerciseDetail(exercise, type)
            )
        }
    }
}

/**
 * Individual exercise score item
 */
@Composable
fun ExerciseScoreItem(type: String, score: Int, details: String) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Column(
            modifier = Modifier.weight(1f)
        ) {
            Text(
                text = formatExerciseType(type),
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onPrimaryContainer
            )
            Text(
                text = details,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onPrimaryContainer.copy(alpha = 0.7f)
            )
        }
        
        Text(
            text = "$score",
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold,
            color = MaterialTheme.colorScheme.onPrimaryContainer
        )
    }
}

/**
 * Exercise card
 */
@Composable
fun ExerciseCard(
    exercise: Exercise,
    latestScore: UserExercise?,
    onClick: () -> Unit
) {
    Card(
        modifier = Modifier
            .size(width = 180.dp, height = 220.dp),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
        shape = RoundedCornerShape(12.dp),
        onClick = onClick
    ) {
        Column(
            modifier = Modifier.fillMaxSize()
        ) {
            // Exercise image
            AsyncImage(
                model = exercise.imageUrl,
                contentDescription = exercise.name,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(120.dp),
                error = painterResource(id = R.drawable.exercise_placeholder)
            )
            
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(12.dp)
            ) {
                Text(
                    text = exercise.name,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    maxLines = 1
                )
                
                Spacer(modifier = Modifier.height(4.dp))
                
                latestScore?.let {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Text(
                            text = "Last score:",
                            style = MaterialTheme.typography.bodySmall
                        )
                        Text(
                            text = "${latestScore.score}",
                            style = MaterialTheme.typography.bodyMedium,
                            fontWeight = FontWeight.Bold
                        )
                    }
                } ?: Text(
                    text = "No attempts yet",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.outline
                )
            }
        }
    }
}

/**
 * Leaderboard list
 */
@Composable
fun LeaderboardList(entries: List<LeaderboardEntry>, currentUserId: Int) {
    if (entries.isEmpty()) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(200.dp),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = "No leaderboard data available",
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.outline,
                textAlign = TextAlign.Center
            )
        }
    } else {
        Card(
            modifier = Modifier.fillMaxWidth(),
            elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp)
            ) {
                // Header row
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text(
                        text = "Rank",
                        style = MaterialTheme.typography.bodyMedium,
                        fontWeight = FontWeight.Medium,
                        modifier = Modifier.weight(0.2f)
                    )
                    Text(
                        text = "User",
                        style = MaterialTheme.typography.bodyMedium,
                        fontWeight = FontWeight.Medium,
                        modifier = Modifier.weight(0.5f)
                    )
                    Text(
                        text = "Score",
                        style = MaterialTheme.typography.bodyMedium,
                        fontWeight = FontWeight.Medium,
                        modifier = Modifier.weight(0.3f),
                        textAlign = TextAlign.End
                    )
                }
                
                Spacer(modifier = Modifier.height(8.dp))
                Divider()
                
                // Entries
                entries.take(10).forEachIndexed { index, entry ->
                    val isCurrentUser = entry.userId == currentUserId
                    val backgroundColor = if (isCurrentUser) {
                        MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.3f)
                    } else {
                        Color.Transparent
                    }
                    
                    Surface(
                        modifier = Modifier.fillMaxWidth(),
                        color = backgroundColor
                    ) {
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(vertical = 8.dp),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                text = "#${index + 1}",
                                style = MaterialTheme.typography.bodyMedium,
                                modifier = Modifier.weight(0.2f)
                            )
                            Text(
                                text = entry.username,
                                style = MaterialTheme.typography.bodyMedium,
                                fontWeight = if (isCurrentUser) FontWeight.Bold else FontWeight.Normal,
                                modifier = Modifier.weight(0.5f)
                            )
                            Text(
                                text = "${entry.totalScore}",
                                style = MaterialTheme.typography.bodyMedium,
                                fontWeight = FontWeight.Bold,
                                modifier = Modifier.weight(0.3f),
                                textAlign = TextAlign.End
                            )
                        }
                    }
                    
                    if (index < entries.size - 1) {
                        Divider(
                            color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f)
                        )
                    }
                }
            }
        }
    }
}

/**
 * Helper function to get the last known location
 */
private fun getLastKnownLocation(context: Context): android.location.Location? {
    val locationManager = context.getSystemService(Context.LOCATION_SERVICE) as LocationManager
    
    val providers = locationManager.getProviders(true)
    var location: android.location.Location? = null
    
    for (provider in providers) {
        try {
            if (ContextCompat.checkSelfPermission(
                    context,
                    Manifest.permission.ACCESS_FINE_LOCATION
                ) == PackageManager.PERMISSION_GRANTED ||
                ContextCompat.checkSelfPermission(
                    context,
                    Manifest.permission.ACCESS_COARSE_LOCATION
                ) == PackageManager.PERMISSION_GRANTED
            ) {
                val l = locationManager.getLastKnownLocation(provider) ?: continue
                if (location == null || l.accuracy < location.accuracy) {
                    location = l
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
    
    return location
}

/**
 * Helper function to format exercise type for display
 */
private fun formatExerciseType(type: String): String {
    return when (type.lowercase()) {
        "pushup" -> "Push-ups"
        "pullup" -> "Pull-ups"
        "situp" -> "Sit-ups"
        "run" -> "2-Mile Run"
        else -> type.replaceFirstChar { it.uppercase() }
    }
}

/**
 * Helper function to get exercise details for display
 */
private fun getExerciseDetail(exercise: UserExercise?, type: String): String {
    return when {
        exercise == null -> "Not attempted yet"
        type == "run" && exercise.timeInSeconds != null -> {
            formatRunTime(exercise.timeInSeconds)
        }
        exercise.reps != null -> "${exercise.reps} reps"
        else -> "Completed"
    }
}

/**
 * Helper function to calculate overall score
 */
private fun calculateOverallScore(latestExercises: Map<String, UserExercise>): Int {
    if (latestExercises.isEmpty()) return 0
    
    var totalScore = 0
    var count = 0
    
    latestExercises.values.forEach { exercise ->
        totalScore += exercise.score
        count++
    }
    
    return if (count > 0) (totalScore.toFloat() / count).roundToInt() else 0
}

/**
 * Helper function to get score rating
 */
private fun getScoreRating(score: Int): String {
    return when {
        score >= 90 -> "Excellent"
        score >= 80 -> "Good"
        score >= 65 -> "Satisfactory"
        score >= 50 -> "Marginal"
        else -> "Poor"
    }
}

/**
 * Helper function to format run time
 */
private fun formatRunTime(seconds: Int): String {
    val minutes = seconds / 60
    val remainingSeconds = seconds % 60
    return "$minutes:${remainingSeconds.toString().padStart(2, '0')}"
}