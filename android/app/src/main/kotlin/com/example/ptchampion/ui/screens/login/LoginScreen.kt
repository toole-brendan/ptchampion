package com.example.ptchampion.ui.screens.login

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Visibility
import androidx.compose.material.icons.filled.VisibilityOff
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavController
import com.example.ptchampion.R
import com.example.ptchampion.ui.navigation.Screen
import com.example.ptchampion.ui.theme.*
import kotlinx.coroutines.flow.collectLatest
import androidx.compose.material3.ExperimentalMaterial3Api

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun LoginScreen(
    navController: NavController,
    viewModel: LoginViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    // Handle navigation effects
    LaunchedEffect(key1 = true) {
        viewModel.effect.collect { effect ->
            when (effect) {
                is LoginEffect.NavigateToHome -> {
                    // Navigate to Home and clear back stack up to Login
                    navController.navigate(Screen.Home.route) {
                        popUpTo(Screen.Login.route) { inclusive = true }
                        launchSingleTop = true
                    }
                }
                is LoginEffect.NavigateToSignUp -> {
                    navController.navigate(Screen.SignUp.route)
                }
            }
        }
    }

    // Alternative way to handle navigation on success (if effect isn't desired for this)
    /*
    LaunchedEffect(uiState.isLoginSuccess) {
        if (uiState.isLoginSuccess) {
             navController.navigate(Screen.Home.route) {
                popUpTo(Screen.Login.route) { inclusive = true }
                launchSingleTop = true
            }
            viewModel.resetLoginSuccess() // Reset flag after navigation
        }
    }
    */

    Surface(
        modifier = Modifier.fillMaxSize(),
        color = PtBackground // Use theme background
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(32.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Text("Login", style = MaterialTheme.typography.headlineLarge, color = PtCommandBlack)
            Spacer(modifier = Modifier.height(24.dp))

            // Email/Username Field
            OutlinedTextField(
                value = uiState.email, // Use email field from state
                onValueChange = { viewModel.onEvent(LoginEvent.EmailChanged(it)) },
                label = { Text("Email or Username") }, // Adjusted label
                modifier = Modifier.fillMaxWidth(),
                singleLine = true,
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Email),
                colors = TextFieldDefaults.outlinedTextFieldColors(
                    focusedBorderColor = PtAccent,
                    unfocusedBorderColor = PtSecondaryText,
                    cursorColor = PtAccent,
                    focusedLabelColor = PtAccent,
                    unfocusedLabelColor = PtSecondaryText
                ),
                isError = uiState.error?.contains("Email", ignoreCase = true) == true || uiState.error?.contains("Username", ignoreCase = true) == true
            )
            Spacer(modifier = Modifier.height(16.dp))

            // Password Field
            OutlinedTextField(
                value = uiState.password,
                onValueChange = { viewModel.onEvent(LoginEvent.PasswordChanged(it)) },
                label = { Text("Password") },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true,
                visualTransformation = PasswordVisualTransformation(),
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password),
                colors = TextFieldDefaults.outlinedTextFieldColors(
                    focusedBorderColor = PtAccent,
                    unfocusedBorderColor = PtSecondaryText,
                    cursorColor = PtAccent,
                    focusedLabelColor = PtAccent,
                    unfocusedLabelColor = PtSecondaryText
                ),
                isError = uiState.error?.contains("Password", ignoreCase = true) == true
            )
            Spacer(modifier = Modifier.height(24.dp))

            // Error Message Display
            uiState.error?.let {
                Text(
                    text = it,
                    color = MaterialTheme.colorScheme.error,
                    style = MaterialTheme.typography.bodySmall,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.padding(bottom = 8.dp)
                )
            }

            // Login Button with Loading Indicator
            Button(
                onClick = { viewModel.onEvent(LoginEvent.Submit) },
                enabled = !uiState.isLoading, // Disable button when loading
                modifier = Modifier.fillMaxWidth(),
                colors = ButtonDefaults.buttonColors(
                    containerColor = PtAccent,
                    contentColor = PtCommandBlack,
                    disabledContainerColor = PtAccent.copy(alpha = 0.5f),
                    disabledContentColor = PtCommandBlack.copy(alpha = 0.5f)
                ),
                shape = MaterialTheme.shapes.small
            ) {
                if (uiState.isLoading) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(24.dp),
                        color = PtCommandBlack,
                        strokeWidth = 2.dp
                    )
                } else {
                    Text("LOGIN")
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Sign Up Link
            TextButton(onClick = { viewModel.navigateToSignUp() }) {
                Text("Don't have an account? Sign Up", color = PtAccent)
            }
        }
    }
} 