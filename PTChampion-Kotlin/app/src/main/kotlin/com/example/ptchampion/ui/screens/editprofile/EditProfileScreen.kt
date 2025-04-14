package com.example.ptchampion.ui.screens.editprofile

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AccountCircle
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.example.ptchampion.ui.theme.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun EditProfileScreen(
    viewModel: EditProfileViewModel = hiltViewModel(),
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
                .verticalScroll(rememberScrollState())
                .padding(20.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            if (uiState.isLoading && uiState.name.isEmpty()) { // Show initial loading indicator
                Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    CircularProgressIndicator(color = PtAccent)
                }
            } else {
                // Avatar Section
                ProfileAvatar(
                    profilePictureUrl = uiState.profilePictureUrl,
                    onClick = viewModel::onAvatarChange
                )
                Spacer(modifier = Modifier.height(24.dp))

                // Name (Display Name) Field
                OutlinedTextField(
                    value = uiState.name,
                    onValueChange = viewModel::onNameChange,
                    label = { Text("Display Name") }, // Changed label
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true,
                    colors = ptTextFieldColors(),
                    isError = uiState.error?.contains("Name", ignoreCase = true) == true
                )
                Spacer(modifier = Modifier.height(16.dp))

                // Email Field (Display Only - Not Editable)
                OutlinedTextField(
                    value = uiState.email,
                    onValueChange = { /* No-op, email not editable */ },
                    label = { Text("Email (Cannot be changed)") },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true,
                    enabled = false, // Disable the field
                    colors = ptTextFieldColors(enabled = false) // Adjust colors for disabled state
                )
                Spacer(modifier = Modifier.height(16.dp))

                // TODO: Add fields for location, profile picture URL (if manual input is desired)
                // Example Location field:
                 OutlinedTextField(
                     value = uiState.location ?: "",
                     onValueChange = viewModel::onLocationChange,
                     label = { Text("Location (Optional)") },
                     modifier = Modifier.fillMaxWidth(),
                     singleLine = true,
                     colors = ptTextFieldColors(),
                     isError = uiState.error?.contains("Location", ignoreCase = true) == true
                 )
                 Spacer(modifier = Modifier.height(24.dp))

                // Error Message Display
                uiState.error?.let {
                    Text(
                        text = it,
                        color = MaterialTheme.colorScheme.error,
                        style = MaterialTheme.typography.bodySmall,
                        modifier = Modifier.padding(bottom = 8.dp)
                    )
                }

                // Save Button with Loading Indicator
                Button(
                    onClick = viewModel::saveProfile,
                    enabled = !uiState.isLoading, // Disable button during save
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
}

@Composable
fun ProfileAvatar(profilePictureUrl: String?, onClick: () -> Unit) {
    Box(
        modifier = Modifier
            .size(100.dp)
            .clip(CircleShape)
            .background(PtSecondaryText.copy(alpha = 0.3f))
            .clickable(onClick = onClick),
        contentAlignment = Alignment.Center
    ) {
        // TODO: Use Coil or Glide to load profilePictureUrl
        // If URL is null or loading fails, show placeholder
        Icon(
            imageVector = Icons.Default.AccountCircle,
            contentDescription = "Profile Picture",
            modifier = Modifier.size(80.dp),
            tint = PtBackground
        )
        Icon(
            imageVector = Icons.Default.Edit,
            contentDescription = "Edit Profile Picture",
            tint = PtAccent.copy(alpha = 0.9f),
            modifier = Modifier
                .align(Alignment.BottomEnd)
                .padding(8.dp)
                .size(24.dp)
                .background(PtPrimaryText.copy(alpha = 0.6f), CircleShape)
                .padding(4.dp)
        )
    }
}

// Use the helper from SignUpScreen or define locally
@Composable
fun ptTextFieldColors(enabled: Boolean = true) = TextFieldDefaults.outlinedTextFieldColors(
    focusedBorderColor = if (enabled) PtAccent else PtSecondaryText.copy(alpha = 0.5f),
    unfocusedBorderColor = if (enabled) PtSecondaryText else PtSecondaryText.copy(alpha = 0.3f),
    cursorColor = if (enabled) PtAccent else Color.Transparent,
    focusedLabelColor = if (enabled) PtAccent else PtSecondaryText.copy(alpha = 0.5f),
    unfocusedLabelColor = PtSecondaryText.copy(alpha = if (enabled) 1f else 0.5f),
    disabledBorderColor = PtSecondaryText.copy(alpha = 0.3f),
    disabledLabelColor = PtSecondaryText.copy(alpha = 0.5f),
    disabledTextColor = PtCommandBlack.copy(alpha = 0.6f)
) 