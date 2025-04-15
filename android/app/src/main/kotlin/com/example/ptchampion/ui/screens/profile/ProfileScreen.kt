package com.example.ptchampion.ui.screens.profile

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.hilt.navigation.compose.hiltViewModel
import com.example.ptchampion.domain.model.User
import com.example.ptchampion.ui.theme.*

@Composable
fun ProfileScreen(
    viewModel: ProfileViewModel = hiltViewModel(),
    navigateToLogin: () -> Unit,
    navigateToEditProfile: () -> Unit,
    navigateToSettings: () -> Unit
) {
    val uiState by viewModel.uiState.collectAsState()

    Surface(
        modifier = Modifier.fillMaxSize(),
        color = PtBackground // Tactical Cream background
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(20.dp) // 20px global padding per style guide
                .verticalScroll(rememberScrollState()), // Add vertical scroll
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            when {
                uiState.isLoading -> {
                    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                        CircularProgressIndicator(color = PtAccent) // Brass Gold
                    }
                }
                uiState.error != null -> {
                    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            Text(
                                text = "Error: ${uiState.error}",
                                color = MaterialTheme.colorScheme.error,
                                style = MaterialTheme.typography.bodyLarge
                            )
                            // Optionally add a retry button if refresh is implemented
                            // Button(onClick = { viewModel.refreshProfile() }) { Text("RETRY") }
                        }
                    }
                }
                uiState.user != null -> {
                    val user = uiState.user!!
                    // Profile Header
                    ProfileHeader(
                        user = user,
                        onEditClick = navigateToEditProfile // Pass navigation lambda
                    )

                    Spacer(modifier = Modifier.height(24.dp))

                    // Settings and Options Card
                    Card(
                        modifier = Modifier.fillMaxWidth(),
                        colors = CardDefaults.cardColors(containerColor = PtBackground),
                        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp),
                        shape = MaterialTheme.shapes.medium
                    ) {
                        Column(modifier = Modifier.padding(16.dp)) {
                            SettingsOption(
                                icon = Icons.Default.Edit,
                                title = "Edit Profile",
                                onClick = navigateToEditProfile
                            )

                            Divider(
                                modifier = Modifier.padding(vertical = 12.dp),
                                color = PtSecondaryText.copy(alpha = 0.2f)
                            )

                            SettingsOption(
                                icon = Icons.Default.Settings,
                                title = "Settings",
                                onClick = navigateToSettings
                            )
                        }
                    }

                    Spacer(modifier = Modifier.weight(1f))

                    // Logout Button
                    Button(
                        onClick = { viewModel.logout(onLoggedOut = navigateToLogin) },
                        modifier = Modifier.fillMaxWidth(),
                        colors = ButtonDefaults.buttonColors(
                            containerColor = PtAccent, // Brass Gold
                            contentColor = PtCommandBlack // Command Black
                        ),
                        shape = MaterialTheme.shapes.small // 8px radius as per styling guide
                    ) {
                        Icon(
                            imageVector = Icons.Default.ExitToApp,
                            contentDescription = null,
                            modifier = Modifier.size(18.dp)
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = "LOGOUT",
                            style = MaterialTheme.typography.labelLarge
                        )
                    }
                }
                else -> {
                    // Handle case where user is null but not loading and no error (e.g., logged out)
                    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                         Text("Not logged in.", style = MaterialTheme.typography.bodyLarge)
                         // Optional: Add button to navigate to login
                         // Button(onClick = navigateToLogin) { Text("LOGIN") }
                    }
                }
            }
        }
    }
}

@Composable
fun ProfileHeader(
    user: User,
    onEditClick: () -> Unit
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = Modifier.fillMaxWidth()
    ) {
        Box(
            modifier = Modifier
                .size(100.dp)
                .clip(CircleShape)
                .background(PtPrimaryText)
                // Make the entire avatar clickable to edit
                .clickable(onClick = onEditClick),
            contentAlignment = Alignment.Center
        ) {
            // TODO: Use Coil or Glide to load user.profilePictureUrl
            Icon(
                imageVector = Icons.Default.AccountCircle,
                contentDescription = "Profile Picture",
                modifier = Modifier.size(80.dp),
                tint = PtBackground
            )
            // Overlay edit icon (optional, as whole avatar is clickable)
            Icon(
                imageVector = Icons.Default.Edit,
                contentDescription = "Edit Profile Picture",
                tint = PtAccent.copy(alpha = 0.8f),
                modifier = Modifier
                    .align(Alignment.BottomEnd)
                    .padding(4.dp)
                    .size(24.dp)
                    .background(PtPrimaryText.copy(alpha = 0.5f), CircleShape)
            )
        }

        Spacer(modifier = Modifier.height(16.dp))

        // User Name
        Text(
            text = (user.displayName ?: user.username).uppercase(), // Use display name or fallback to username
            style = MaterialTheme.typography.headlineSmall,
            color = PtCommandBlack
        )

        Spacer(modifier = Modifier.height(4.dp))

        // User Email (if available)
        user.email?.let {
             Text(
                text = it,
                style = MaterialTheme.typography.bodyMedium,
                color = PtSecondaryText
            )
        }
    }
}

@Composable
fun SettingsOption(
    icon: ImageVector,
    title: String,
    onClick: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            tint = PtAccent, // Brass Gold
            modifier = Modifier.size(24.dp)
        )
        Spacer(modifier = Modifier.width(16.dp))
        Text(
            text = title,
            style = MaterialTheme.typography.titleMedium,
            color = PtCommandBlack // Command Black
        )
        Spacer(modifier = Modifier.weight(1f))
        Icon(
            imageVector = Icons.Default.KeyboardArrowRight,
            contentDescription = null,
            tint = PtSecondaryText, // Tactical Gray
            modifier = Modifier.size(24.dp)
        )
    }
} 