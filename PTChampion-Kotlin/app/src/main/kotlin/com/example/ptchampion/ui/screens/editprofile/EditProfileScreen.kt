package com.example.ptchampion.ui.screens.editprofile

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.AccountCircle
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.example.ptchampion.ui.theme.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun EditProfileScreen(
    viewModel: EditProfileViewModel = viewModel(),
    onNavigateBack: () -> Unit
) {
    val uiState by viewModel.uiState.collectAsState()

    // Handle navigation after successful save
    LaunchedEffect(uiState.isSaveSuccess) {
        if (uiState.isSaveSuccess) {
            viewModel.resetSaveSuccess() // Reset flag before navigating
            onNavigateBack()
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("EDIT PROFILE", color = PtCommandBlack) },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Filled.ArrowBack, contentDescription = "Back", tint = PtAccent)
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = PtBackground)
            )
        },
        containerColor = PtBackground
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .padding(paddingValues)
                .fillMaxSize()
                .verticalScroll(rememberScrollState()) // Add scroll for smaller screens
                .padding(20.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            // Avatar Section
            ProfileAvatar(
                avatarUrl = uiState.avatarUrl, // Pass URL if available
                onClick = viewModel::onAvatarChange // Trigger avatar change
            )
            Spacer(modifier = Modifier.height(24.dp))

            // Name Field
            OutlinedTextField(
                value = uiState.name,
                onValueChange = viewModel::onNameChange,
                label = { Text("Name") },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true,
                colors = TextFieldDefaults.outlinedTextFieldColors( // Apply custom colors
                    focusedBorderColor = PtAccent,
                    unfocusedBorderColor = PtSecondaryText,
                    cursorColor = PtAccent,
                    focusedLabelColor = PtAccent,
                    unfocusedLabelColor = PtSecondaryText
                ),
                isError = uiState.error?.contains("Name", ignoreCase = true) == true // Example error check
            )
            Spacer(modifier = Modifier.height(16.dp))

            // Email Field
            OutlinedTextField(
                value = uiState.email,
                onValueChange = viewModel::onEmailChange,
                label = { Text("Email") },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true,
                colors = TextFieldDefaults.outlinedTextFieldColors( // Apply custom colors
                    focusedBorderColor = PtAccent,
                    unfocusedBorderColor = PtSecondaryText,
                    cursorColor = PtAccent,
                    focusedLabelColor = PtAccent,
                    unfocusedLabelColor = PtSecondaryText
                ),
                isError = uiState.error?.contains("Email", ignoreCase = true) == true // Example error check
            )
            Spacer(modifier = Modifier.height(24.dp))

            // Error Message Display
            uiState.error?.let { error ->
                Text(
                    text = error,
                    color = MaterialTheme.colorScheme.error,
                    style = MaterialTheme.typography.bodySmall,
                    modifier = Modifier.padding(bottom = 8.dp)
                )
            }

            // Save Button with Loading Indicator
            Button(
                onClick = viewModel::saveProfile, // Call save function
                enabled = !uiState.isLoading, // Disable button when loading
                modifier = Modifier.fillMaxWidth(),
                colors = ButtonDefaults.buttonColors(
                    containerColor = PtAccent,
                    contentColor = PtCommandBlack,
                    disabledContainerColor = PtAccent.copy(alpha = 0.5f),
                    disabledContentColor = PtCommandBlack.copy(alpha = 0.5f)
                )
            ) {
                if (uiState.isLoading) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(24.dp),
                        color = PtCommandBlack,
                        strokeWidth = 2.dp
                    )
                } else {
                    Text("SAVE CHANGES")
                }
            }
        }
    }
}

// Extracted Composable for the Avatar part
@Composable
fun ProfileAvatar(avatarUrl: String?, onClick: () -> Unit) {
    Box(
        modifier = Modifier
            .size(100.dp)
            .clip(CircleShape)
            .background(PtSecondaryText.copy(alpha = 0.3f)) // Placeholder background
            .clickable(onClick = onClick), // Make it clickable
        contentAlignment = Alignment.Center
    ) {
        // TODO: Load image from avatarUrl using a library like Coil
        Icon(
            imageVector = Icons.Default.AccountCircle,
            contentDescription = "Profile Picture",
            modifier = Modifier.size(80.dp),
            tint = PtBackground // Use light tint on darker background
        )
        // Overlay Edit Icon
        Icon(
            imageVector = Icons.Default.Edit,
            contentDescription = "Edit Profile Picture",
            tint = PtAccent.copy(alpha = 0.9f),
            modifier = Modifier
                .align(Alignment.BottomEnd)
                .padding(8.dp)
                .size(24.dp)
                .background(PtPrimaryText.copy(alpha = 0.6f), CircleShape)
                .padding(4.dp) // Inner padding for the icon
        )
    }
} 